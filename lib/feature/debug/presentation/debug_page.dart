import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'package:registro_elettronico/core/data/local/moor_database.dart';
import 'package:registro_elettronico/core/infrastructure/app_injection.dart';
import 'package:registro_elettronico/core/infrastructure/notification/fcm_service.dart';
import 'package:registro_elettronico/feature/profile/domain/repository/profile_repository.dart';
import 'package:registro_elettronico/utils/constants/preferences_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugPage extends StatefulWidget {
  DebugPage({Key key}) : super(key: key);

  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  // static const platform = const MethodChannel(
  //     'com.riccardocalligaro.registro_elettronico/home_widget');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug mode'),
      ),
      body: Column(
        children: <Widget>[
          DebugButton(
            title: 'Open DB',
            onTap: () {
              final AppDatabase db = sl();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MoorDbViewer(db)));
            },
          ),
          DebugButton(
              title: 'Cancel token',
              onTap: () async {
                FlutterSecureStorage flutterSecureStorage = sl();
                ProfileRepository profileRepository = sl();
                SharedPreferences sharedPreferences = sl();

                final profile = await profileRepository.getProfile();

                await flutterSecureStorage.write(key: profile.ident, value: '');
                final profile2 = profile.copyWith(
                  token: '',
                  expire: DateTime.now()
                      .subtract(
                        Duration(
                          days: 1,
                        ),
                      )
                      .toIso8601String(),
                );

                await sharedPreferences.setString(
                    PrefsConstants.profile, profile2.toJson());
              }),
          DebugButton(
            title: 'Send notification',
            subtitle: 'With the local notifications plugin',
            onTap: () async {
              AndroidInitializationSettings androidInitializationSettings =
                  AndroidInitializationSettings('app_icon');

              var initializationSettingsIOS = IOSInitializationSettings(
                requestSoundPermission: false,
                requestBadgePermission: false,
                requestAlertPermission: false,
              );

              var initializationSettings = InitializationSettings(
                android: androidInitializationSettings,
                iOS: initializationSettingsIOS,
              );

              FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
                  FlutterLocalNotificationsPlugin();

              await flutterLocalNotificationsPlugin
                  .initialize(initializationSettings);

              var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                PushNotificationService.channelId,
                PushNotificationService.channelName,
                PushNotificationService.channelDescription,
                importance: Importance.max,
                priority: Priority.high,
              );

              var iOSPlatformChannelSpecifics = IOSNotificationDetails();
              var platformChannelSpecifics = NotificationDetails(
                android: androidPlatformChannelSpecifics,
                iOS: iOSPlatformChannelSpecifics,
              );

              await flutterLocalNotificationsPlugin.show(
                0,
                'Title',
                'Notification body',
                platformChannelSpecifics,
              );
            },
          ),
        ],
      ),
    );
  }
}

class DebugButton extends ListTile {
  final BuildContext context;
  final bool dangerous;

  DebugButton({
    @required String title,
    String subtitle,
    @required VoidCallback onTap,
    this.context,
    this.dangerous = false,
  })  : assert(!dangerous || context != null),
        super(
          onTap: (dangerous) ? () => safe(context, onTap) : onTap,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
        );

  static void safe(BuildContext context, VoidCallback callback) {
    Widget cancelButton = FlatButton(
      child: Text("Nope"),
      onPressed: () => Navigator.of(context).pop(),
    );
    Widget continueButton = FlatButton(
      child: Text("Yup"),
      onPressed: callback,
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Attention!"),
      content: Text("Are you sure you want to do this?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
