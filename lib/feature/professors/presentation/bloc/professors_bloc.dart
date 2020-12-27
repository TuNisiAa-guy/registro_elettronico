import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:meta/meta.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart';
import 'package:registro_elettronico/feature/subjects/domain/repository/subjects_repository.dart';

part 'professors_event.dart';

part 'professors_state.dart';

class ProfessorsBloc extends Bloc<ProfessorsEvent, ProfessorsState> {
  final SubjectsRepository subjectsRepository;

  ProfessorsBloc({
    @required this.subjectsRepository,
  }) : super(ProfessorsInitial());

  @override
  Stream<ProfessorsState> mapEventToState(
    ProfessorsEvent event,
  ) async* {
    if (event is GetProfessorsForSubject) {
      yield ProfessorsLoadInProgress();
      try {
        final professors = await subjectsRepository.getAllProfessors();
        FLog.info(text: 'BloC -> Got ${professors.length} professors');
        yield ProfessorsLoadSuccess(
          professors:
              professors.where((p) => p.subjectId == event.subjectId).toList(),
        );
      } on Exception catch (e, s) {
        FLog.error(
          text: 'Error getting professors for subject',
          exception: e,
          stacktrace: s,
        );
        FirebaseCrashlytics.instance.recordError(e, s);
        yield ProfessorsLoadError();
      }
    }
  }
}
