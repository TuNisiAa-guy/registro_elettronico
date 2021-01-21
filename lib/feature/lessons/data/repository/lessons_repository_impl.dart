import 'package:flutter/foundation.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart';
import 'package:registro_elettronico/core/infrastructure/error/handler.dart';
import 'package:registro_elettronico/core/infrastructure/generic/update.dart';
import 'package:registro_elettronico/core/infrastructure/log/logger.dart';
import 'package:registro_elettronico/feature/lessons/data/datasource/lessons_local_datasource.dart';
import 'package:registro_elettronico/feature/lessons/data/datasource/lessons_remote_datasource.dart';
import 'package:registro_elettronico/feature/lessons/data/model/lesson_remote_model.dart';
import 'package:registro_elettronico/feature/lessons/domain/model/lesson_domain_model.dart';
import 'package:registro_elettronico/core/infrastructure/generic/resource.dart';
import 'package:registro_elettronico/core/infrastructure/error/successes.dart';
import 'package:registro_elettronico/core/infrastructure/error/failures_v2.dart';
import 'package:dartz/dartz.dart';
import 'package:registro_elettronico/feature/lessons/domain/repository/lessons_repository.dart';
import 'package:registro_elettronico/utils/date_utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonsRepositoryImpl implements LessonsRepository {
  static const String lastUpdateKey = 'lessonsLastUpdate';

  final LessonsRemoteDatasource lessonsRemoteDatasource;
  final LessonsLocalDatasource lessonsLocalDatasource;
  final SharedPreferences sharedPreferences;

  LessonsRepositoryImpl({
    @required this.lessonsRemoteDatasource,
    @required this.lessonsLocalDatasource,
    @required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, Success>> updateAllLessons({bool ifNeeded}) async {
    try {
      if (!ifNeeded |
          (ifNeeded && needUpdate(sharedPreferences.getInt(lastUpdateKey)))) {
        final interval = DateUtils.getDateInerval();
        final remoteModels =
            await lessonsRemoteDatasource.getLessonBetweenDates(
          interval.begin,
          interval.end,
        );

        final updateResult = await _updateLessons(remoteLessons: remoteModels);
        return Right(updateResult);
      }

      return Right(Success());
    } catch (e, s) {
      return Left(handleError(e, s));
    }
  }

  @override
  Future<Either<Failure, Success>> updateTodaysLessons({bool ifNeeded}) async {
    try {
      if (!ifNeeded |
          (ifNeeded && needUpdate(sharedPreferences.getInt(lastUpdateKey)))) {
        final interval = DateUtils.getDateInerval();
        final remoteModels =
            await lessonsRemoteDatasource.getLessonBetweenDates(
          interval.begin,
          interval.end,
        );

        final updateResult = await _updateLessons(remoteLessons: remoteModels);
        return Right(updateResult);
      } else {
        return Right(Success());
      }
    } catch (e, s) {
      return Left(handleError(e, s));
    }
  }

  @override
  Stream<Resource<List<LessonDomainModel>>> watchAllLessons() {
    return lessonsLocalDatasource.watchAllLessons().map(
      (lessonLocalModels) {
        lessonLocalModels.sort((a, b) => a.date.compareTo(b.date));

        final lessonDomainModels = lessonLocalModels
            .map((e) => LessonDomainModel.fromLocalModel(e))
            .toList();

        return Resource.success(data: lessonDomainModels);
      },
    ).onErrorReturnWith((error) {
      Logger.streamError(error.toString());
      return Resource.failed(error: handleError(error));
    });
  }

  @override
  Stream<Resource<List<LessonDomainModel>>> watchLessonsForSubjectId({
    int subjectId,
  }) {
    return lessonsLocalDatasource.watchLessonsForSubject(subjectId).map(
      (lessonLocalModels) {
        lessonLocalModels.sort((a, b) => a.date.compareTo(b.date));

        final lessonDomainModels = lessonLocalModels
            .map((e) => LessonDomainModel.fromLocalModel(e))
            .toList();

        return Resource.success(data: lessonDomainModels);
      },
    ).onErrorReturnWith((error) {
      Logger.streamError(error.toString());
      return Resource.failed(error: handleError(error));
    });
  }

  Future<Success> _updateLessons({
    @required List<LessonRemoteModel> remoteLessons,
  }) async {
    final localLessons = await lessonsLocalDatasource.getAllLessons();

    final lessonsMap = Map<int, LessonLocalModel>.fromIterable(localLessons,
        key: (v) => v.evtId, value: (v) => v);

    final remoteIds = remoteLessons.map((e) => e.evtId).toList();

    List<LessonLocalModel> lessonsToDelete = [];

    for (final localLesson in localLessons) {
      if (!remoteIds.contains(localLesson.eventId)) {
        lessonsToDelete.add(localLesson);
      }
    }

    await lessonsLocalDatasource.insertLessons(
      remoteLessons
          .map(
            (e) => e.toLocalModel(),
          )
          .toList(),
    );

    // delete the lessons that were removed from the remote source
    await lessonsLocalDatasource.deleteLessons(lessonsToDelete);

    await sharedPreferences.setInt(
        lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

    return SuccessWithUpdate();
  }
}
