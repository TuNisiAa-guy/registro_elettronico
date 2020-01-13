import 'dart:io';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:registro_elettronico/component/navigator.dart';
import 'package:registro_elettronico/main.dart';
import 'package:registro_elettronico/ui/feature/settings/components/about/about_developers_page.dart';
import 'package:registro_elettronico/ui/feature/settings/components/account/account_settings.dart';
import 'package:registro_elettronico/ui/feature/settings/components/customization/customization_settings.dart';
import 'package:registro_elettronico/ui/feature/settings/components/general/general_settings.dart';
import 'package:registro_elettronico/ui/feature/settings/components/header_text.dart';
import 'package:registro_elettronico/ui/feature/settings/components/notifications/notifications_interval_settings_dialog.dart';
import 'package:registro_elettronico/ui/feature/widgets/app_drawer.dart';
import 'package:registro_elettronico/ui/feature/widgets/custom_app_bar.dart';
import 'package:registro_elettronico/ui/feature/widgets/double_back_to_close_app.dart';
import 'package:registro_elettronico/ui/global/localizations/app_localizations.dart';
import 'package:registro_elettronico/utils/constants/drawer_constants.dart';
import 'package:registro_elettronico/utils/constants/preferences_constants.dart';
import 'package:registro_elettronico/utils/global_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'components/notifications/notifications_type_settings_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();

  int _updateInterval = 30;
  SharedPreferences sharedPrefs;
  bool _notificationsActivated;

  @override
  void initState() {
    super.initState();
    restore();
  }

  restore() async {
    sharedPrefs = await SharedPreferences.getInstance();
    setState(() {
      _updateInterval =
          (sharedPrefs.getInt(PrefsConstants.UPDATE_INTERVAL)) ?? 30;
      _notificationsActivated =
          (sharedPrefs.getBool(PrefsConstants.NOTIFICATIONS)) ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      appBar: CustomAppBar(
        scaffoldKey: _drawerKey,
        title: Text(
          AppLocalizations.of(context).translate('settings'),
        ),
      ),
      drawer: AppDrawer(
        position: DrawerConstants.SETTINGS,
      ),
      body: DoubleBackToCloseApp(
        snackBar: AppNavigator.instance.getLeaveSnackBar(context),
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Notification settins
                _buildNotificationsSettingsSection(),

                /// General settings
                GeneralSettings(),

                CustomizationSettings(),

                AccountSettings(),

                _buildAboutSection()
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Notifcation settings, you can set [what] to notify, the interval, and chose if wifi and battery options
  Widget _buildNotificationsSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0),
          child: HeaderText(
            text: AppLocalizations.of(context).translate('notifications'),
          ),
        ),
        ListTile(
          title: Text(
              AppLocalizations.of(context).translate('notifications_title')),
          subtitle: Text(
              AppLocalizations.of(context).translate('notifications_message')),
          trailing: Checkbox(
            value: _notificationsActivated ?? false,
            onChanged: (value) {
              setState(() {
                _notificationsActivated = value;
              });

              _setWorkmanager(value);

              save(PrefsConstants.NOTIFICATIONS, value);
            },
          ),
        ),
        ListTile(
          enabled: _notificationsActivated ?? false,
          title: Text(
              AppLocalizations.of(context).translate('choose_what_to_notify')),
          subtitle: Text(
            AppLocalizations.of(context)
                .translate('press_to_set_notifications'),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) {
                return SimpleDialog(
                  children: <Widget>[
                    Container(
                      width: 100,
                      child: NotificationsSettingsDialog(),
                    ),
                  ],
                );
              },
            );
          },
        ),
        ListTile(
          enabled: _notificationsActivated ?? false,
          title: Text(
            AppLocalizations.of(context).translate('choose_interval'),
          ),
          subtitle: Text(_getUpdateTimeMessage(_updateInterval)),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (ctx) {
                return SimpleDialog(
                  children: <Widget>[
                    NotificationsIntervalSettingsDialog(
                      updateInterval: _updateInterval,
                    ),
                  ],
                );
              },
            ).then((value) {
              setState(() {
                if (value != null) {
                  _updateInterval = value;
                  save(PrefsConstants.UPDATE_INTERVAL, value);
                }
              });
            });
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final trans = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0),
          child: HeaderText(
            text: AppLocalizations.of(context).translate('about_title'),
          ),
        ),
        ListTile(
          title: Text(trans.translate('about_developers_title')),
          subtitle: Text(trans.translate('about_developers_subtitle')),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AboutDevelopersPage()));
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context).translate('report_bug_title')),
          subtitle: Text(AppLocalizations.of(context).translate('report_bug_message')),
          onTap: () async {
            await FLog.exportLogs();
            final path = await _localPath + "/" + PrefsConstants.DIRECTORY_NAME;
            var file = File("$path/flog.txt");
            var exists = await file.exists();
            if (exists) {
              final random = GlobalUtils.getRandomNumber();
              final subject =
                  'Bug report #$random - ${DateTime.now().toString()}';
              String userMessage;
              userMessage =
                  '${AppLocalizations.of(context).translate("email_message")}\n  -';

              final Email reportEmail = Email(
                body: userMessage,
                subject: subject,
                recipients: ['riccardocalligaro@gmail.com'],
                attachmentPath: '$path/flog.txt',
                isHTML: false,
              );
              await FlutterEmailSender.send(reportEmail);
            }
          },
        ),
        ListTile(
          title: Text(trans.translate('about_donate_title')),
          subtitle: Text(trans.translate('about_donate_subtitle')),
        ),
      ],
    );
  }

  String _getUpdateTimeMessage(int interval) {
    if (interval >= 60)
      return AppLocalizations.of(context)
          .translate('every_hours')
          .replaceAll('{h}', (interval / 60).toString());
    return AppLocalizations.of(context)
        .translate('every_minutes')
        .replaceAll('{m}', interval.toString());
  }

  static save(String key, dynamic value) async {
    FLog.info(text: 'Changed value $key -> $value');
    final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    if (value is bool) {
      sharedPrefs.setBool(key, value);
    } else if (value is String) {
      sharedPrefs.setString(key, value);
    } else if (value is int) {
      sharedPrefs.setInt(key, value);
    } else if (value is double) {
      sharedPrefs.setDouble(key, value);
    } else if (value is List<String>) {
      sharedPrefs.setStringList(key, value);
    }
  }

  void _setWorkmanager(bool value) async {
    if (value) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      final refreshInterval =
          sharedPreferences.getInt(PrefsConstants.UPDATE_INTERVAL) ?? 60;

      FLog.info(
        text: '-> Set new time for notifications -> interval $refreshInterval',
      );
      WidgetsFlutterBinding.ensureInitialized();
      Workmanager.cancelAll();
      Workmanager.initialize(
        callbackDispatcher,
        //! set to false in production
        isInDebugMode: true,
      );

      Workmanager.registerPeriodicTask(
        'checkForNewContent', 'checkForNewContent',
        initialDelay: Duration(minutes: 60),
        // minimum frequency for android is 15 minutes
        frequency: Duration(minutes: refreshInterval),
        constraints: Constraints(
          // we need the user to be conntected, these parameters will be customizable in the future
          //TODO: let user customize these params
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      FLog.info(text: '-> Set notifications every $refreshInterval');
    } else {
      WidgetsFlutterBinding.ensureInitialized();
      Workmanager.cancelAll();
      FLog.info(text: '-> Cancelled all notifications intervals');
    }
  }

  Future<String> get _localPath async {
    var directory;

    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getExternalStorageDirectory();
    }

    return directory.path;
  }
}
