import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class Setreminder extends StatefulWidget {
  @override
  _SetreminderState createState() => _SetreminderState();
}

class _SetreminderState extends State<Setreminder> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay? _selectedTime;
  List<String> _days = [];
  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    await FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      _days.contains(day) ? _days.remove(day) : _days.add(day);
    });
  }

  Future<void> _scheduleNotification() async {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _selectedTime == null ||
        _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      // 1. First test with immediate notification
      await _showTestNotification();

      // 2. Save to Firestore
      final user = _auth.currentUser;
      if (user == null) return;

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .add({
        'name': _medicationNameController.text,
        'dosage': _dosageController.text,
        'time': '${_selectedTime!.hour}:${_selectedTime!.minute}',
        'days': _days,
        'createdAt': Timestamp.now(),
      });

      // 3. Schedule notifications
      for (final day in _days) {
        final dayIndex = _allDays.indexOf(day);
        if (dayIndex == -1) continue;

        final scheduledDate = _calculateNextOccurrence(dayIndex, _selectedTime!);
        final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

        print('Scheduling for $day at ${scheduledTime.toString()}');

        await FlutterLocalNotificationsPlugin().zonedSchedule(
          docRef.id.hashCode + dayIndex,
          'Medication Reminder: ${_medicationNameController.text}',
          'Take ${_dosageController.text}',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_channel',
              'Medication Reminders',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders set successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showTestNotification() async {
    await FlutterLocalNotificationsPlugin().show(
      999,
      'Notification Test',
      'Your notification system is working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
        ),
      ),
    );
  }

  DateTime _calculateNextOccurrence(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduledDate.weekday != dayOfWeek + 1) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  Widget _buildMedicationsList() {
    final user = _auth.currentUser;
    if (user == null) return Container();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Text('No medications added yet.');

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final medication = snapshot.data!.docs[index];
            final data = medication.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(data['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosage: ${data['dosage']}'),
                    Text('Time: ${data['time']}'),
                    Text('Days: ${(data['days'] as List).join(', ')}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMedication(medication.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMedication(String medicationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .doc(medicationId)
          .delete();

      // Cancel related notifications
      for (int i = 0; i < 7; i++) {
        await FlutterLocalNotificationsPlugin().cancel(medicationId.hashCode + i);
      }
    } catch (e) {
      print('Error deleting medication: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Medication Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _medicationNameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., 1 tablet)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : 'Selected Time: ${_selectedTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              const Text('Select Days:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allDays.map((day) => FilterChip(
                  label: Text(day),
                  selected: _days.contains(day),
                  onSelected: (selected) => _toggleDay(day),
                )).toList(),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _scheduleNotification,
                  child: const Text('Set Reminder'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Your Medications:', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMedicationsList(),
            ],
          ),
        ),
      ),
    );
  }
}