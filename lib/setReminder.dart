import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class SetReminderScreen extends StatefulWidget {
  const SetReminderScreen({Key? key}) : super(key: key);

  @override
  _SetReminderScreenState createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _doseController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  
  // Frequency options for medication
  final List<String> _frequencies = ['Once daily', 'Twice daily', 'Three times daily', 'Custom'];
  String _selectedFrequency = 'Once daily';
  
  // Days of the week for custom scheduling
  final Map<String, bool> _selectedDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': true,
  };

  // Notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  // Initialize the notifications plugin
  Future<void> _initializeNotifications() async {
    tz_init.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings with correct class for v19.0.0 - DarwinInitializationSettings instead of IOSInitializationSettings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request notification permissions for Android only
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      // iOS permissions are already handled in the initialization settings
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Schedule a notification
  Future<void> _scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          // Use DarwinNotificationDetails instead of IOSNotificationDetails
          iOS: const DarwinNotificationDetails(
            sound: 'default.sound',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Save the reminder to Firestore and schedule notifications
  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be logged in to set reminders')),
          );
          return;
        }

        // Create a document reference
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc();

        // Get the medication details
        final String medicineName = _medicineNameController.text;
        final String dose = _doseController.text;
        
        // Calculate notification times based on frequency
        List<TimeOfDay> notificationTimes = [];
        
        switch (_selectedFrequency) {
          case 'Once daily':
            notificationTimes.add(_selectedTime);
            break;
          case 'Twice daily':
            notificationTimes.add(_selectedTime);
            // Add a second time 12 hours later
            int hour = (_selectedTime.hour + 12) % 24;
            notificationTimes.add(TimeOfDay(hour: hour, minute: _selectedTime.minute));
            break;
          case 'Three times daily':
            notificationTimes.add(_selectedTime);
            // Add times 8 hours apart
            int hour1 = (_selectedTime.hour + 8) % 24;
            int hour2 = (_selectedTime.hour + 16) % 24;
            notificationTimes.add(TimeOfDay(hour: hour1, minute: _selectedTime.minute));
            notificationTimes.add(TimeOfDay(hour: hour2, minute: _selectedTime.minute));
            break;
          case 'Custom':
            notificationTimes.add(_selectedTime);
            break;
        }

        // Convert TimeOfDay to DateTime for storage
        List<Map<String, dynamic>> reminderTimes = notificationTimes.map((time) {
          return {
            'hour': time.hour,
            'minute': time.minute,
          };
        }).toList();

        // Save to Firestore
        await docRef.set({
          'medicineName': medicineName,
          'dose': dose,
          'frequency': _selectedFrequency,
          'reminderTimes': reminderTimes,
          'selectedDays': _selectedDays,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Schedule notifications for each time
        final int reminderId = docRef.id.hashCode;
        
        // Schedule notifications for each reminder time
        for (int i = 0; i < notificationTimes.length; i++) {
          final TimeOfDay notificationTime = notificationTimes[i];
          
          // Create DateTime for today with the notification time
          final now = DateTime.now();
          DateTime scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            notificationTime.hour,
            notificationTime.minute,
          );
          
          // If the time has already passed today, schedule for tomorrow
          if (scheduledDateTime.isBefore(now)) {
            scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
          }
          
          // Schedule the notification
          await _scheduleNotification(
            reminderId + i,
            'Medication Reminder',
            'Time to take $medicineName - Dose: $dose',
            scheduledDateTime,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication reminder saved successfully!')),
        );

        // Clear form
        _medicineNameController.clear();
        _doseController.clear();
        setState(() {
          _selectedTime = TimeOfDay.now();
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: $e')),
        );
      }
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Medication name input
                TextFormField(
                  controller: _medicineNameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Dose input
                TextFormField(
                  controller: _doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose (e.g., 1 tablet, 5ml)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the dose';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Frequency dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedFrequency,
                  items: _frequencies.map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Time selector
                ListTile(
                  title: const Text('Reminder Time'),
                  subtitle: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                ),
                const SizedBox(height: 16),
                
                // Days of week checkboxes (only shown for custom frequency)
                if (_selectedFrequency == 'Custom')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Select Days',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...List.generate(
                        _selectedDays.length,
                        (index) {
                          final day = _selectedDays.keys.elementAt(index);
                          return CheckboxListTile(
                            title: Text(day),
                            value: _selectedDays[day],
                            onChanged: (value) {
                              setState(() {
                                _selectedDays[day] = value ?? true;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),
                
                // Save button
                ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Set Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}