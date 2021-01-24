import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:registro_elettronico/core/infrastructure/error/failures_v2.dart';
import 'package:registro_elettronico/core/infrastructure/error/handler.dart';
import 'package:registro_elettronico/feature/authentication/data/datasource/authentication_remote_datasource.dart';
import 'package:registro_elettronico/feature/authentication/data/datasource/profiles_local_datasource.dart';
import 'package:registro_elettronico/feature/authentication/data/model/login/generic_login_response.dart';
import 'package:registro_elettronico/feature/authentication/data/model/login/login_response_remote_model.dart';
import 'package:registro_elettronico/feature/authentication/domain/model/credentials_domain_model.dart';
import 'package:registro_elettronico/feature/authentication/domain/model/login_request_domain_model.dart';
import 'package:registro_elettronico/feature/authentication/domain/model/profile_domain_model.dart';
import 'package:registro_elettronico/feature/authentication/domain/repository/authentication_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final AuthenticationRemoteDatasource authenticationRemoteDatasource;
  final ProfilesLocalDatasource profilesLocalDatasource;
  final FlutterSecureStorage flutterSecureStorage;
  final SharedPreferences sharedPreferences;

  AuthenticationRepositoryImpl({
    @required this.profilesLocalDatasource,
    @required this.flutterSecureStorage,
    @required this.sharedPreferences,
    @required this.authenticationRemoteDatasource,
  });

  @override
  Future<bool> isLoggedIn() async {
    final profile = await _getProfile();
    return profile != null;
  }

  @override
  Future<ProfileDomainModel> getProfile() async {
    final profile = await _getProfile();
    return profile;
  }

  @override
  Future<CredentialsDomainModel> getCredentials() async {
    final profile = await _getProfile();
    final password = await flutterSecureStorage.read(key: profile.ident);
    return CredentialsDomainModel(profile: profile, password: password);
  }

  @override
  Future<String> getCurrentStudentId() async {
    final profile = await _getProfile();
    return profile.ident;
  }

  Future<ProfileDomainModel> _getProfile() async {
    final profileSingleton = _ProfileSingleton.instance;

    if (profileSingleton.profile != null) {
      return profileSingleton.profile;
    } else {
      final localProfile = await profilesLocalDatasource.getLoggedInUser();
      profileSingleton.profile =
          ProfileDomainModel.fromLocalModel(localProfile);
    }

    return profileSingleton.profile;
  }

  @override
  Future<Either<Failure, GenericLoginResponse>> loginUser({
    LoginRequestDomainModel loginRequestDomainModel,
  }) async {
    try {
      final response = await authenticationRemoteDatasource.loginUser(
        loginRequestDomainModel: loginRequestDomainModel,
      );

      return response.fold(
        (parentResponse) {
          return Right(GenericLoginResponse(
            response: Left(parentResponse),
          ));
        },
        (loginResponse) {
          return Right(GenericLoginResponse(
            response: Right(loginResponse),
          ));
        },
      );
    } on DioError catch (e) {
      return Left(LoginFailure(dioError: e));
    } catch (e, s) {
      return Left(handleError(e, s));
    }
  }

  @override
  Future updateProfile({
    DefaultLoginResponseRemoteModel responseRemoteModel,
  }) async {
    final localModel = responseRemoteModel.toLocalModel();
    await profilesLocalDatasource.updateProfile(localModel);
    final domainModel = ProfileDomainModel.fromLocalModel(localModel);
    // we update the singleton
    _ProfileSingleton.instance.profile = domainModel;
  }
}

class _ProfileSingleton {
  static final _ProfileSingleton _singleton = _ProfileSingleton._internal();
  _ProfileSingleton._internal();
  static _ProfileSingleton get instance => _singleton;

  ProfileDomainModel profile;
}

class LoginFailure extends Failure {
  DioError dioError;

  LoginFailure({@required this.dioError});

  @override
  String localizedDescription(BuildContext context) {
    if (dioError.response.statusCode == 422) {
      // TODO: better response
      return 'PAssword sbagliata';
    } else if (dioError.response.statusCode >= 500) {
      return 'Server down';
    }

    return super.localizedDescription(context);
  }
}
