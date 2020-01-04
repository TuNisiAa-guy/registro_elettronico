import 'package:meta/meta.dart';

@immutable
abstract class SubjectsEvent {}

class UpdateSubjects extends SubjectsEvent {}

class GetSubjects extends SubjectsEvent {}

class GetSubjectsAndProfessors extends SubjectsEvent {}

class GetProfessors extends SubjectsEvent {}