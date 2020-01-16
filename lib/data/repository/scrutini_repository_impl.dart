import 'package:dartz/dartz.dart';
import 'package:f_logs/f_logs.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:registro_elettronico/core/error/failures.dart';
import 'package:registro_elettronico/data/network/service/web/web_spaggiari_client.dart';
import 'package:registro_elettronico/domain/repository/profile_repository.dart';
import 'package:registro_elettronico/domain/repository/scrutini_repository.dart';

class ScrutiniRepositoryImpl implements ScrutiniRepository {
  WebSpaggiariClient webSpaggiariClient;
  ProfileRepository profileRepository;
  FlutterSecureStorage flutterSecureStorage;

  ScrutiniRepositoryImpl(
    this.webSpaggiariClient,
    this.profileRepository,
    this.flutterSecureStorage,
  );

  @override
  Future<Either<Failure, String>> getLoginToken() async {
    final profile = await profileRepository.getDbProfile();
    final password = await flutterSecureStorage.read(key: profile.ident);

    try {
      final resToken = await webSpaggiariClient.getPHPToken(
        username: profile.ident,
        password: password,
      );

      return Right(resToken);
    } catch (e, s) {
      Crashlytics.instance.recordError(e, s);
      FLog.error(
          exception: e, stacktrace: s, text: 'Error getting login token');
      return Left(ServerFailure());
    }
  }
}