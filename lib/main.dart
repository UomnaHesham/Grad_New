import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grad/opening.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global variable to access Firebase initialization status throughout the app
bool isFirebaseInitialized = false;

// Define the background message handler at the top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with different configurations for web and mobile
    if (kIsWeb) {
      // Web-specific Firebase options - required for web
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD7x2Q1oq8_aYrstmF-6SOkb99njNYMY_A",
          authDomain: "grad-545d4.firebaseapp.com",
          projectId: "grad-545d4",
          storageBucket: "grad-545d4.firebasestorage.app",
          messagingSenderId: "1084808501135",
          appId: "1:1084808501135:web:66f5a2ead9979175c81dfa",
          measurementId: "G-T3FYDKKGJ2",
        ),
      );
      print("Firebase initialized for web successfully");
    } else {
      // Mobile platforms use the default options from google-services.json
      await Firebase.initializeApp();
      print("Firebase initialized for mobile successfully");
      
      // Initialize Android Alarm Manager for periodic background tasks
      await AndroidAlarmManager.initialize();
      print("Android Alarm Manager initialized");
      
      // Initialize time zones for scheduled notifications
      tz_init.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      print("Time zones initialized");
    }
    
    // Set background message handler for Firebase Messaging
    // Skip this on web as it's not fully supported
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    
    // Request permission for notifications (optional but recommended)
    if (!kIsWeb) { // Messaging permissions only needed on mobile
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    isFirebaseInitialized = true;
    print("Firebase core services initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Set up notification channels after Firebase is initialized
  // Only needed for mobile
  if (!kIsWeb) {
    await setupNotifications();
  }

  // Run the app after Firebase is initialized
  runApp(const MyApp());
}

Future<void> setupNotifications() async {
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
    
    // Set up a listener for Firebase Messaging foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If the message contains a notification and we're on Android, show it
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
    
    print("Notification channel created successfully");
  } catch (e) {
    print("Error setting up notifications: $e");
  }
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
