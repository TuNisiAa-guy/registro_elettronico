import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registro_elettronico/component/navigator.dart';
import 'package:registro_elettronico/data/network/exception/server_exception.dart';
import 'package:registro_elettronico/ui/bloc/agenda/bloc.dart';
import 'package:registro_elettronico/ui/bloc/auth/bloc.dart';
import 'package:registro_elettronico/ui/bloc/grades/bloc.dart';
import 'package:registro_elettronico/ui/bloc/grades/subject_grades/bloc.dart';
import 'package:registro_elettronico/ui/bloc/lessons/bloc.dart';
import 'package:registro_elettronico/ui/feature/grades/components/grades_tab.dart';
import 'package:registro_elettronico/ui/feature/home/components/sections/agenda_section.dart';
import 'package:registro_elettronico/ui/feature/home/components/sections/last_grades_section.dart';
import 'package:registro_elettronico/ui/feature/home/components/sections/lessons_cards_section.dart';
import 'package:registro_elettronico/ui/feature/home/components/sections/noticeboard_section.dart';
import 'package:registro_elettronico/ui/feature/home/components/sections/subjects_grid_section.dart';
import 'package:registro_elettronico/ui/feature/widgets/app_drawer.dart';
import 'package:registro_elettronico/ui/feature/widgets/custom_app_bar.dart';
import 'package:registro_elettronico/ui/feature/widgets/section_header.dart';
import 'package:registro_elettronico/ui/global/localizations/app_localizations.dart';
import 'package:registro_elettronico/utils/constants/drawer_constants.dart';
import 'package:registro_elettronico/utils/constants/preferences_constants.dart';
import 'package:registro_elettronico/utils/constants/tabs_constants.dart';
import 'package:registro_elettronico/utils/global_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The [home] page of the application
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Key necessaery for the [drawer]
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  int _lastUpdate = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    // we need to get shared preferences to change the grades we show in the home page
    getPreferences();
    BlocProvider.of<AgendaBloc>(context)
        .add(GetNextEvents(dateTime: DateTime.now(), numberOfevents: 3));
    BlocProvider.of<GradesBloc>(context).add(GetGrades(limit: 3));
    BlocProvider.of<LessonsBloc>(context).add(GetLastLessons());

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Updates [shared preferences]
  getPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    _lastUpdate = sharedPreferences.getInt(PrefsConstants.LAST_UPDATE_HOME) ??
        DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      appBar: CustomAppBar(
        title: Text('Home'),
        scaffoldKey: _drawerKey,
        // actions: <Widget>[
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: () {
        //       WidgetsFlutterBinding.ensureInitialized();
        //       Workmanager.cancelAll();
        //       Workmanager.initialize(
        //         callbackDispatcher,
        //         //! set to false in production
        //         isInDebugMode: true,
        //       );

        //       Workmanager.registerOneOffTask(
        //         "checkForNewContent",
        //         "checkForNewContent",
        //         initialDelay: Duration(seconds: 2),
        //       );
        //     },
        //   )
        // ],
      ),
      bottomSheet: Container(
        // height: 20,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[800]),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            'Ultimo aggiornamento: ${GlobalUtils.getLastUpdateMessage(context, DateTime.fromMillisecondsSinceEpoch(_lastUpdate))}',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
      drawer: AppDrawer(
        position: DrawerConstants.HOME,
      ),
      body: BlocListener<LessonsBloc, LessonsState>(
        listener: (context, state) {
          _mapStateToUI(state, context);
        },
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: ScrollConfiguration(
            behavior: NoGlowBehavior(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Lessons
                    _buildLastLessonsHeader(),
                    LessonsCardsSection(),
                    // Noticeboard
                    Divider(color: Colors.grey[300]),
                    NoticeboardSection(),
                    // Next events
                    Divider(color: Colors.grey[300]),
                    _buildNextEventsHeader(),
                    AgendaSection(),
                    // My subjects
                    Divider(color: Colors.grey[300]),
                    _buildMySubjectsHeader(),
                    SubjectsGridSection(),
                    // Last grades
                    Divider(color: Colors.grey[300]),
                    _buildLastGradesHeader(),
                    LastGradesSection()
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //----- HEADERS -------- //
  Widget _buildLastLessonsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11.0),
      child: SectionHeader(
        headingText: AppLocalizations.of(context).translate('last_lessons'),
      ),
    );
    // return SectionHeader(
    //   headingText: AppLocalizations.of(context).translate('last_lessons'),
    // );
  }

  Widget _buildNextEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: SectionHeader(
        headingText: AppLocalizations.of(context).translate('next_events'),
      ),
    );
    // return SectionHeader(
    //   headingText: AppLocalizations.of(context).translate('next_events'),
    // );
  }

  Widget _buildMySubjectsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11.0),
      child: SectionHeader(
        headingText: AppLocalizations.of(context).translate('my_subjects'),
      ),
    );
  }

  Widget _buildLastGradesHeader() {
    return SectionHeader(
      headingText: AppLocalizations.of(context).translate('last_grades'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title:
                    Text(AppLocalizations.of(context).translate('last_grades')),
              ),
              body: GradeTab(
                period: TabsConstants.ULTIMI_VOTI,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns a different element basing on the [state]
  void _mapStateToUI(LessonsState state, BuildContext context) {
    final trans = AppLocalizations.of(context);
    print(state);
    if (state is LessonsLoadServerError) {
      if (state.serverError.response != null &&
          state.serverError.response.statusCode == 422) {
        final exception =
            ServerException.fromJson(state.serverError.response.data);
        Scaffold.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(exception.message),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: trans.translate('log_out'),
                onPressed: () {
                  AppNavigator.instance.navToLogin(context);
                  BlocProvider.of<AuthBloc>(context).add(SignOut());
                },
              ),
            ),
          );
      } else {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(state.serverError.error.toString()),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context).translate('log_out'),
              onPressed: () {
                AppNavigator.instance.navToLogin(context);
                BlocProvider.of<AuthBloc>(context).add(SignOut());
              },
            ),
          ),
        );
      }
    } else if (state is LessonsUpdateLoadSuccess) {
      // We remove the current snackbar
      Scaffold.of(context)..removeCurrentSnackBar();
    }
  }

  // Function that is called when refresh]is pulled
  /// Updates lessons, agenda, grades for the [user]
  Future<void> _refreshData() async {
    // Update lessons
    BlocProvider.of<LessonsBloc>(context).add(UpdateTodayLessons());
    BlocProvider.of<LessonsBloc>(context).add(GetLastLessons());

    // // Update grades
    BlocProvider.of<GradesBloc>(context).add(UpdateGrades());
    BlocProvider.of<GradesBloc>(context).add(GetGrades(limit: 3));
    //BlocProvider.of<PeriodsBloc>(context).add(FetchPeriods());
    BlocProvider.of<SubjectsGradesBloc>(context).add(GetGradesAndSubjects());
    // Update agenda
    BlocProvider.of<AgendaBloc>(context).add(UpdateAllAgenda());
    BlocProvider.of<AgendaBloc>(context)
        .add(GetNextEvents(dateTime: DateTime.now(), numberOfevents: 3));
  }
}

class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
