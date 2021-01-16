import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart';
import 'package:registro_elettronico/core/infrastructure/localizations/app_localizations.dart';
import 'package:registro_elettronico/core/presentation/widgets/cusotm_placeholder.dart';
import 'package:registro_elettronico/core/presentation/widgets/custom_refresher.dart';
import 'package:registro_elettronico/core/presentation/widgets/grade_card.dart';
import 'package:registro_elettronico/feature/grades/presentation/bloc/subjects_grades/subjects_grades_bloc.dart';

/// Page of the [last grades]
class LastGradesPage extends StatefulWidget {
  final List<Grade> grades;

  const LastGradesPage({
    Key key,
    @required this.grades,
  }) : super(key: key);

  @override
  _LastGradesPageState createState() => _LastGradesPageState();
}

class _LastGradesPageState extends State<LastGradesPage> {
  Completer<void> _refreshCompleter;

  @override
  void initState() {
    super.initState();

    _refreshCompleter = Completer<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomRefresher(
        onRefresh: () {
          BlocProvider.of<SubjectsGradesBloc>(context)
              .add(UpdateSubjectGrades());
          BlocProvider.of<SubjectsGradesBloc>(context)
              .add(GetGradesAndSubjects());
          return _refreshCompleter.future;
        },
        child: _buildGradesList(),
      ),
    );
  }

  Widget _buildGradesList() {
    if (widget.grades.isNotEmpty) {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 16.0),
        itemCount: widget.grades.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: GradeCard(
                grade: widget.grades[index],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GradeCard(
              grade: widget.grades[index],
            ),
          );
        },
      );
    } else {
      return CustomPlaceHolder(
        icon: Icons.timeline,
        showUpdate: true,
        onTap: () {
          BlocProvider.of<SubjectsGradesBloc>(context)
              .add(UpdateSubjectGrades());
          BlocProvider.of<SubjectsGradesBloc>(context)
              .add(GetGradesAndSubjects());
          return _refreshCompleter.future;
        },
        text: AppLocalizations.of(context).translate('no_grades'),
      );
    }
  }
}