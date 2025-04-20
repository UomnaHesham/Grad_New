import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grad/opening.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase configuration
  FirebaseOptions firebaseOptions = const FirebaseOptions(
    apiKey: "AIzaSyD7x2Q1oq8_aYrstmF-6SOkb99njNYMY_A",
    authDomain: "grad-545d4.firebaseapp.com",
    projectId: "grad-545d4",
    storageBucket: "grad-545d4.firebasestorage.app",
    messagingSenderId: "1084808501135",
    appId: "1:1084808501135:web:66f5a2ead9979175c81dfa",
    measurementId: "G-T3FYDKKGJ2",
  );

  // Firebase initialization
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Notification setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'medication_channel',
    'Medication Reminders',
    description: 'Reminders for taking medications',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableVibration: true,
  );

  try {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    
    // Request permissions for Android 13+ (with null safety check)
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    print("Notification channel created successfully");
  } catch (e) {
    print("Error creating notification channel: $e");
  }

  // Test notification
  try {
    await flutterLocalNotificationsPlugin.show(
      9999,
      'App Started',
      'Notification system is working',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
        ),
      ),
    );
  } catch (e) {
    print("Error showing test notification: $e");
  }

  // Run the app after Firebase is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Opening(),
      debugShowCheckedModeBanner: false,
    );
  }
}
