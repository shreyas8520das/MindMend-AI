import 'dart:async';
import 'dart:convert';
import 'package:caress/Assessment.dart';
import 'package:caress/Helpline.dart';
import 'package:caress/Prediction.dart';
import 'package:caress/main.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:usage_stats/usage_stats.dart';

import 'Instruction.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high importance channel', 'High Importance Notifications',
    description: 'This Channel is used for important notifications',
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class UserData extends StatefulWidget {
  const UserData({Key? key}) : super(key: key);

  @override
  State<UserData> createState() => _UserDataState();
}

bool run = true;
int? _steps = 0;
int? stepx = 0;
String? _heart_rate;
HealthValue? _bp_d;
HealthValue? _bp_s;
HealthValue? _oxygen;
HealthValue? _bodytemp;
int c = 0;

class _UserDataState extends State<UserData> {
  List<EventUsageInfo> events = [];
  Map<String?, NetworkInfo?> _netInfoMap = Map();

  String? heartRate;
  HealthValue? bpd;
  HealthValue? bps;
  HealthValue? oxygen;
  HealthValue? bodytemp;

  Future sendEmail(
      String name1, String name2, String message, String email) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    const serviceId = 'service_vc1tc92';
    const templateId = 'template_mak408l';
    const userId = 'C7ns8WoNqX9Ns9GvG';
    try {
      final response = await http.post(url,
          headers: {
            'origin': 'http:localhost',
            'Content-Type': 'application/json'
          },
          body: json.encode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
            'template_params': {
              'from_name': name1,
              'to_name': name2,
              'message': message,
              'to_email': email,
            }
          }));
      return response.statusCode;
    } catch (e) {
      print("feedback email response");
    }
  }

  void notification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    var x = events[1]
        .packageName!
        .replaceFirst("com.", "")
        .replaceFirst(".android", "");
    String statement = (x == 'whatsapp' ||
            x == 'instagram' ||
            x == 'snapchat' ||
            x == 'twitter' ||
            x == 'google.youtube')
        ? '4. Stop using $x'
        : '4. Stop using all the apps now.';

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    if (int.parse(_heart_rate!.split(".")[0]) > 100) {
      flutterLocalNotificationsPlugin.show(
        0,
        "Alert",
        "Your heartbeat is increasing",
        NotificationDetails(
          android: AndroidNotificationDetails(channel.id, channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              color: Colors.red,
              playSound: true,
              icon: '@mipmap/ic_launcher'),
        ),
        payload: "optional payload",
      );
    }

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'Alert',
            style: TextStyle(
                fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Anxiety attack detected!!',
                  style: TextStyle(fontSize: 15.00, color: Colors.blue),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Stop using your phone\n' +
                      '2. Take Deep breaths and Relax\n' +
                      '3. Take a Juice break\n' +
                      statement,
                  style: TextStyle(fontSize: 15.00, color: Colors.black),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
            FlatButton(
              child: Text('Call ${patientInfo.friendName}'),
              onPressed: () {
                FlutterPhoneDirectCaller.callNumber(patientInfo.phoneNo!);
              },
            ),
          ],
        ),
      );
    }, onDidReceiveBackgroundNotificationResponse: (NotificationResponse) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'Alert',
            style: TextStyle(
                fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Anxiety attack detected!!',
                  style: TextStyle(fontSize: 15.00, color: Colors.blue),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Stop using your phone\n' +
                      '2. Take Deep breaths and Relax\n' +
                      '3. Take a Juice break\n' +
                      statement,
                  style: TextStyle(fontSize: 15.00, color: Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
            FlatButton(
              child: Text('Call ${patientInfo.friendName}'),
              onPressed: () {
                FlutterPhoneDirectCaller.callNumber(patientInfo.phoneNo!);
              },
            ),
          ],
        ),
      );
    });
  }

  Future<void> initUsage() async {
    UsageStats.grantUsagePermission();
    DateTime endDate = new DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: 1));

    List<EventUsageInfo> queryEvents =
        await UsageStats.queryEvents(startDate, endDate);
    List<NetworkInfo> networkInfos =
        await UsageStats.queryNetworkUsageStats(startDate, endDate);
    Map<String?, NetworkInfo?> netInfoMap = Map.fromIterable(networkInfos,
        key: (v) => v.packageName, value: (v) => v);

    this.setState(() {
      events = queryEvents.reversed.toList();
      _netInfoMap = netInfoMap;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    if (run) {
      initUsage();
      //func();
      setState(() {
        run = false;
      });
    }
    Timer.periodic(Duration(minutes: 1), (timer) {
      //func();
    });
    Timer.periodic(Duration(minutes: 1), (timer) {
      notification();
      if (int.parse(_heart_rate!.split(".")[0]) > 100) {
        c = 1;
      }
    });
    Timer.periodic(Duration(hours: 3), (timer) {
      if (c == 1) {
        sendEmail(
          patientInfo.name!,
          patientInfo.friendName!,
          'Your friend ${patientInfo.name} had an anxiety attack',
          patientInfo.friendContact!,
        );
        sendEmail(
          patientInfo.name!,
          patientInfo.specialistName!,
          'Your patient ${patientInfo.name} had an anxiety attack',
          patientInfo.specialistContact!,
        );
        c = 0;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    var currentDateTime = DateTime.now();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Caress'),
          centerTitle: true,
          backgroundColor: Colors.redAccent.withOpacity(0.8),
        ),
        drawer: Menu(),
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: height / 40, horizontal: 0.04 * width),
                child: Text(
                  'Hey!! ${patientInfo.name}, Welcome to Caress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                'Today is ${currentDateTime.day}/${currentDateTime.month}/${currentDateTime.year}',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Quick Links',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20.0,
                        runSpacing: 20.0,
                        children: [
                          QuickLink(
                            icon: Icons.health_and_safety,
                            label: 'Self Assessment',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Assessment()),
                              );
                            },
                          ),
                          QuickLink(
                            icon: Icons.book_outlined,
                            label: 'Instructions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Instruction()),
                              );
                            },
                          ),
                          QuickLink(
                            icon: Icons.phone,
                            label: 'Helpline',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Helpline()),
                              );
                            },
                          ),
                          QuickLink(
                            icon: FontAwesomeIcons.stethoscope,
                            label: 'Smart Prediction',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PredictionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Container(
      width: width * 0.6, // Adjust width as needed
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

FlatButton({required Text child, required void Function() onPressed}) {}

class DataValue extends StatelessWidget {
  const DataValue(
      {required this.data, required this.dataName, required this.dataIcon});

  final String data;
  final String dataName;
  final IconData dataIcon;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Container(
      width: width / 2.3,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200]!.withOpacity(0.7)),
      child: Column(
        children: [
          Icon(dataIcon, size: 0.174 * width, color: Colors.pink[600]),
          SizedBox(height: height / 40),
          Text(
            dataName,
            style: TextStyle(
                fontSize: 0.036 * width,
                color: Colors.blue,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height / 40),
          Text(data),
        ],
      ),
    );
  }
}

class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    Color color = Colors.black;
    return Drawer(
      backgroundColor: Colors.white,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(top: 40, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.black,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Home',
                      textScaleFactor: 1,
                      style: TextStyle(fontSize: 25, color: color),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Assessment()));
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: Colors.black,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Self Assesment',
                      textScaleFactor: 1,
                      style: TextStyle(fontSize: 25, color: color),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                child: Row(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      color: Colors.black,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Instructions',
                      textScaleFactor: 1,
                      style: TextStyle(fontSize: 25, color: color),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Instruction()));
                },
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.black,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Helpline',
                      textScaleFactor: 1,
                      style: TextStyle(fontSize: 25, color: color),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Helpline()));
                },
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.stethoscope,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 15),
                    Text(
                      'Smart Prediction',
                      textScaleFactor: 1,
                      style: TextStyle(fontSize: 25),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PredictionScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: height / 2),
              Text(
                '',
                textAlign: TextAlign.center,
                textScaleFactor: 1,
                style: TextStyle(fontSize: 15, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
