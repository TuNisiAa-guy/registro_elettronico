import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:registro_elettronico/core/infrastructure/error/failures_v2.dart';
import 'package:registro_elettronico/core/infrastructure/error/successes.dart';
import 'package:registro_elettronico/core/infrastructure/generic/resource.dart';
import 'package:registro_elettronico/feature/timetable/domain/model/timetable_entry_domain_model.dart';
import 'package:registro_elettronico/feature/timetable/presentation/model/timetable_entry_presentation_model.dart';

abstract class TimetableRepository {
  Stream<Resource<List<TimetableEntryPresentationModel>>> watchEntries();

  Future<Either<Failure, Success>> regenerateTimetable();

  Future<Either<Failure, Success>> insertTimetableEntry({
    @required TimetableEntryDomainModel entry,
  });

  Future<Either<Failure, Success>> updateTimetableEntry({
    @required TimetableEntryDomainModel entry,
  });
}
