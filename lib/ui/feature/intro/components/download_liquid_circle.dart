import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injector/injector.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:registro_elettronico/component/navigator.dart';
import 'package:registro_elettronico/component/routes.dart';
import 'package:registro_elettronico/main.dart';
import 'package:registro_elettronico/ui/bloc/intro/bloc.dart';
import 'package:registro_elettronico/ui/global/localizations/app_localizations.dart';
import 'package:registro_elettronico/utils/constants/preferences_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class IntroDownloadLiquidCircle extends StatefulWidget {
  IntroDownloadLiquidCircle({Key key}) : super(key: key);

  @override
  _IntroDownloadLiquidCircleState createState() =>
      _IntroDownloadLiquidCircleState();
}

class _IntroDownloadLiquidCircleState extends State<IntroDownloadLiquidCircle>
    with SingleTickerProviderStateMixin {
  double value = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        BlocListener<IntroBloc, IntroState>(
          listener: (context, state) {
            if (state is IntroError) {
              AppNavigator.instance.navToHome(context);
            }
          },
          child: BlocBuilder<IntroBloc, IntroState>(
            builder: (context, state) {
              if (state is IntroInitial) {
                return Container(
                  height: 300,
                  width: 300,
                  child: GestureDetector(
                    onTap: () async {
                      BlocProvider.of<IntroBloc>(context).add(FetchAllData());
                    },
                    child: LiquidCircularProgressIndicator(
                      value: 0.0,
                      valueColor: AlwaysStoppedAnimation(Colors.red),
                      backgroundColor: Colors.white,
                      borderWidth: 2.0,
                      borderColor:
                          (Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[900]
                              : Colors.white),
                      //  (Theme.of(context).brightness == Brightness.dark
                      //      ? Colors.white
                      //      : Colors.grey[900]),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.arrow_downward,
                            size: 84,
                            color: Colors.black,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            AppLocalizations.of(context).translate('download'),
                            style: TextStyle(fontSize: 24, color: Colors.black),
                          )
                        ],
                      ), // Defaults to the current Theme's backgroundColor.
                    ),
                  ),
                );
              }

              if (state is IntroLoading) {
                return Container(
                  height: 300,
                  width: 300,
                  child: LiquidCircularProgressIndicator(
                    value: state.progress / 100,
                    valueColor: AlwaysStoppedAnimation(Colors.red),
                    backgroundColor: Colors
                        .white, // Defaults to the current Theme's backgroundColor.
                    borderWidth: 2.0,
                    borderColor:
                        (Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[900]
                            : Colors.white),
                  ),
                );
              }
              if (state is IntroLoaded) {
                return Container(
                  height: 300,
                  width: 300,
                  child: GestureDetector(
                    onTap: () async {
                      FLog.info(
                          text:
                              'Checking shared prefrences for notifications!');
                      SharedPreferences prefs =
                          Injector.appInstance.getDependency();

                      prefs.setBool(PrefsConstants.NOTIFICATIONS, true);
                      prefs.setBool(PrefsConstants.GRADES_NOTIFICATIONS, true);
                      prefs.setBool(PrefsConstants.NOTICES_NOTIFICATIONS, true);

                      prefs.setInt(PrefsConstants.UPDATE_INTERVAL, 360);

                      WidgetsFlutterBinding.ensureInitialized();
                      Workmanager.cancelAll();
                      Workmanager.initialize(
                        callbackDispatcher,
                        isInDebugMode: false,
                      );

                      Workmanager.registerPeriodicTask(
                        'checkForNewContent',
                        'checkForNewContent',
                        initialDelay: Duration(minutes: 60),
                        frequency: Duration(minutes: 360),
                        constraints: Constraints(
                          networkType: NetworkType.connected,
                        ),
                      );
                      FLog.info(text: 'Set everything for periodic task!');
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.HOME,
                        (r) => false,
                      );
                    },
                    child: LiquidCircularProgressIndicator(
                      value: 1.0,
                      valueColor: AlwaysStoppedAnimation(Colors.green),
                      backgroundColor: Colors.white,
                      borderWidth: 2.0,
                      borderColor:
                          (Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[900]
                              : Colors.white),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.check,
                            size: 84,
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            AppLocalizations.of(context)
                                .translate('press_here'),
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (state is IntroError) {
                return Container(
                  height: 300,
                  width: 300,
                  child: GestureDetector(
                    onDoubleTap: () {
                      AppNavigator.instance.navToHome(context);
                    },
                    onTap: () {
                      BlocProvider.of<IntroBloc>(context).add(FetchAllData());
                    },
                    child: LiquidCircularProgressIndicator(
                      value: 0.0,
                      valueColor: AlwaysStoppedAnimation(Colors.red),
                      backgroundColor: Colors.white,
                      borderWidth: 2.0,
                      borderColor:
                          (Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[900]
                              : Colors.white),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.sync_problem,
                            size: 84,
                            color: Colors.black,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('data_not_downloaded_message'),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ), // Defaults to the current Theme's backgroundColor.
                    ),
                  ),
                );
              }

              if (state is IntroNotConnected) {
                return Container(
                  height: 300,
                  width: 300,
                  child: GestureDetector(
                    onTap: () async {
                      BlocProvider.of<IntroBloc>(context).add(FetchAllData());
                    },
                    child: LiquidCircularProgressIndicator(
                      value: 0.0,
                      valueColor: AlwaysStoppedAnimation(Colors.red),
                      backgroundColor: Colors.white,
                      borderWidth: 2.0,
                      borderColor:
                          (Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[900]
                              : Colors.white),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.error,
                            size: 84,
                            color: Colors.black,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '${AppLocalizations.of(context).translate('not_connected')}\n${AppLocalizations.of(context).translate('press_to_retry')}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          )
                        ],
                      ), // Defaults to the current Theme's backgroundColor.
                    ),
                  ),
                );
              }
              return Container(
                height: 250,
                width: 250,
                child: LiquidCircularProgressIndicator(
                  value: 0.0,
                  valueColor: AlwaysStoppedAnimation(Colors.red),
                  backgroundColor: Colors.white,
                  borderWidth: 2.0,
                  borderColor: (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[900]
                      : Colors.white),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
