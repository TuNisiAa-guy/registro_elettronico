import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart' as db;
import 'package:registro_elettronico/core/infrastructure/log/logger.dart';
import 'package:registro_elettronico/feature/profile/data/dao/profile_dao.dart';
import 'package:registro_elettronico/feature/profile/data/model/profile_entity.dart';
import 'package:registro_elettronico/feature/profile/data/model/profile_mapper.dart';
import 'package:registro_elettronico/feature/profile/domain/repository/profile_repository.dart';
import 'package:registro_elettronico/utils/constants/preferences_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDao profileDao;
  final FlutterSecureStorage flutterSecureStorage;
  final SharedPreferences sharedPreferences;

  ProfileRepositoryImpl(
    this.profileDao,
    this.flutterSecureStorage,
    this.sharedPreferences,
  );

  @override
  Future<bool> isLoggedIn() async {
    Logger.info('Checking logged in user...');
    return sharedPreferences.getString(PrefsConstants.profile) != null;
  }

  @override
  Future deleteProfile({Profile profile}) => profileDao.deleteProfile(
      ProfileMapper.mapProfileEntityToProfileInsertable(profile));

  @override
  Future insertProfile({
    Profile profile,
  }) {
    final convertedProfile =
        ProfileMapper.mapProfileEntityToProfileInsertable(profile);
    return profileDao.insertProfile(convertedProfile);
  }

  @override
  Future deleteAllProfiles() => profileDao.deleteAllProfiles();

  @override
  Future<String> getToken() async {
    final profile = await getProfile();
    return profile.token;
  }

  @override
  Future<db.Profile> getDbProfile() async {
    final profile = await profileDao.getProfile();
    return profile;
  }

  @override
  Future updateProfile(Profile profile) {
    return profileDao.updateProfile(
      ProfileMapper.mapProfileEntityToProfileInsertable(profile),
    );
  }

  @override
  Future<Tuple2<Profile, String>> getUserAndPassword() async {
    final profile = await getProfile();
    final password = await flutterSecureStorage.read(key: profile.ident);
    return Tuple2(profile, password);
  }

  @override
  Profile getProfile() {
    final profile = sharedPreferences.getString(PrefsConstants.profile);
    return Profile.fromJson(profile);
  }
}