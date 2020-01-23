import 'package:f_logs/model/flog/flog.dart';
import 'package:registro_elettronico/core/error/failures.dart';
import 'package:registro_elettronico/core/network/network_info.dart';
import 'package:registro_elettronico/data/db/dao/professor_dao.dart';
import 'package:registro_elettronico/data/db/dao/profile_dao.dart';
import 'package:registro_elettronico/data/db/dao/subject_dao.dart';
import 'package:registro_elettronico/data/db/moor_database.dart';
import 'package:registro_elettronico/data/network/service/api/spaggiari_client.dart';
import 'package:registro_elettronico/data/repository/mapper/subject_mapper.dart';
import 'package:registro_elettronico/domain/repository/subjects_repository.dart';

class SubjectsRepositoryImpl implements SubjectsRepository {
  SpaggiariClient spaggiariClient;
  ProfessorDao professorDao;
  SubjectDao subjectDao;
  ProfileDao profileDao;
  NetworkInfo networkInfo;

  SubjectsRepositoryImpl(
    this.spaggiariClient,
    this.professorDao,
    this.subjectDao,
    this.profileDao,
    this.networkInfo,
  );

  @override
  Future updateSubjects() async {
    if (await networkInfo.isConnected) {
      final profile = await profileDao.getProfile();
      final res = await spaggiariClient.getSubjects(profile.studentId);

      List<Subject> subjects = [];
      List<Professor> teachers = [];
      res.subjects.forEach((subject) {
        subjects.add(SubjectMapper.convertSubjectEntityToInsertable(subject));
        subject.teachers.forEach((professor) {
          teachers.add(
            SubjectMapper.convertProfessorEntityToInsertable(
              professor,
              subject.id,
            ),
          );
        });
      });

      FLog.info(
        text:
            'Got ${res.subjects} subjects from server, procceding to insert in database',
      );
      // Clear the old profofessors and subjects from the database
      await professorDao.deleteAllProfessors();
      await subjectDao.deleteAllSubjects();

      await subjectDao.insertSubjects(subjects);
      await professorDao.insertProfessors(teachers);
    } else {
      throw NotConntectedException();
    }
  }

  @override
  Future insertSubject(Subject subject) {
    return subjectDao.insertSubject(subject);
  }

  @override
  Future<List<Subject>> getAllSubjects() {
    return subjectDao.getAllSubjects();
  }

  @override
  Future<List<Professor>> getAllProfessors() {
    return professorDao.getAllProfessors();
  }

  @override
  Future<List<Subject>> getSubjectsOrdered() {
    return subjectDao.getSubjectsOrdered();
  }
}
