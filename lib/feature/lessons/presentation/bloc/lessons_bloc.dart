import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:registro_elettronico/core/infrastructure/log/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:meta/meta.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart';
import 'package:registro_elettronico/core/infrastructure/error/failures.dart';
import 'package:registro_elettronico/feature/lessons/domain/repository/lessons_repository.dart';

part 'lessons_event.dart';
part 'lessons_state.dart';

class LessonsBloc extends Bloc<LessonsEvent, LessonsState> {
  final LessonsRepository lessonsRepository;

  LessonsBloc({
    @required this.lessonsRepository,
  }) : super(LessonsInitial());

  @override
  Stream<LessonsState> mapEventToState(
    LessonsEvent event,
  ) async* {
    if (event is GetLastLessons) {
      yield* _mapGetLastLessonsToState();
    } else if (event is GetLessonsByDate) {
      yield* _mapGetLessonsByDateLessonsToState(event.dateTime);
    } else if (event is GetLessons) {
      yield* _mapGetLessonsToState();
    } else if (event is UpdateAllLessons) {
      yield* _mapUpdateAllLessonsToState();
    } else if (event is UpdateTodayLessons) {
      yield* _mapTodayLessonsToState();
    } else if (event is GetLessonsForSubject) {
      yield* _mapGetLessonsForSubjectToState(event.subjectId);
    }
  }

  Stream<LessonsState> _mapGetLastLessonsToState() async* {
    yield LessonsLoadInProgress();
    try {
      final lessons = await lessonsRepository.getLastLessons();
      Logger.info('BloC -> Got ${lessons.length} lessons');

      yield LessonsLoadSuccess(lessons: lessons);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Error getting last lessons by date',
        exception: e,
        stacktrace: s,
      );
      yield LessonsLoadError(error: e.toString());
    }
  }

  Stream<LessonsState> _mapGetLessonsByDateLessonsToState(
      DateTime dateTime) async* {
    yield LessonsLoadInProgress();
    try {
      final lessons = await lessonsRepository.getLessonsByDate(dateTime);
      Logger.info('BloC -> Got ${lessons.length} lessons');
      yield LessonsLoadSuccess(lessons: lessons);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Error getting lessons by date',
        exception: e,
        stacktrace: s,
      );
      await FirebaseCrashlytics.instance.recordError(e, s);
      yield LessonsLoadError(error: e.toString());
    }
  }

  Stream<LessonsState> _mapGetLessonsToState() async* {
    yield LessonsLoadInProgress();
    try {
      final lessons = await lessonsRepository.getLessons();
      Logger.info('BloC -> Got ${lessons.length} events');
      yield LessonsLoadSuccess(lessons: lessons);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Error getting absences',
        exception: e,
        stacktrace: s,
      );
      await FirebaseCrashlytics.instance.recordError(e, s);
      yield LessonsLoadError(error: e.toString());
    }
  }

  Stream<LessonsState> _mapUpdateAllLessonsToState() async* {
    try {
      await lessonsRepository.updateAllLessons();

      yield LessonsUpdateLoadSuccess();
    } on NotConntectedException catch (_) {
      yield LessonsLoadErrorNotConnected();
    } on DioError catch (e, s) {
      Logger.info('Server - Error updating absences');
      await FirebaseCrashlytics.instance.recordError(e, s);
      yield LessonsLoadServerError(serverError: e);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Other - Error updating absences',
        exception: e,
        stacktrace: s,
      );
      await FirebaseCrashlytics.instance.recordError(e, s);
      LessonsLoadError(error: e.toString());
    }
  }

  Stream<LessonsState> _mapTodayLessonsToState() async* {
    try {
      await lessonsRepository.upadateTodayLessons();
      yield LessonsUpdateLoadSuccess();
    } on NotConntectedException catch (_) {
      yield LessonsLoadErrorNotConnected();
    } on DioError catch (e, s) {
      Logger.e(
        text: 'Other - Error updating today lessons',
        exception: e,
        stacktrace: s,
      );
      await FirebaseCrashlytics.instance.recordError(e, s);
      yield LessonsLoadServerError(serverError: e);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Other - Error updating today lessons',
        exception: e,
        stacktrace: s,
      );
      await FirebaseCrashlytics.instance.recordError(e, s);

      LessonsLoadError(error: e.toString());
    }
  }

  Stream<LessonsState> _mapGetLessonsForSubjectToState(int subjectId) async* {
    yield LessonsLoadInProgress();
    try {
      final lessons = await lessonsRepository.getLessonsForSubject(subjectId);
      yield LessonsLoadSuccess(lessons: lessons);
    } on Exception catch (e, s) {
      Logger.e(
        text: 'Other - Error getting lessons for subject lessons',
        exception: e,
        stacktrace: s,
      );
      yield LessonsLoadError(error: e.toString());
    }
  }
}