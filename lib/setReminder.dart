import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

class SetReminderScreen extends StatefulWidget {
  final String? medicationId;
  final Map<String, dynamic>? existingData;
  
  const SetReminderScreen({
    Key? key, 
    this.medicationId,
    this.existingData,
  }) : super(key: key);

  @override
  _SetReminderScreenState createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _doseController = TextEditingController();
  
  // Multiple times support
  List<TimeOfDay> _selectedTimes = [TimeOfDay.now()];
  
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
    _populateFormIfEditing();
  }

  // Populate form if editing existing medication
  void _populateFormIfEditing() {
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _medicineNameController.text = data['medicineName']?.toString() ?? '';
      _doseController.text = data['dose']?.toString() ?? '';
      _selectedFrequency = data['frequency']?.toString() ?? 'Once daily';
      
      // Handle reminder times if they exist
      final reminderTimes = data['reminderTimes'] as List<dynamic>?;
      if (reminderTimes != null && reminderTimes.isNotEmpty) {
        _selectedTimes = reminderTimes.map((timeData) {
          final timeMap = timeData as Map<String, dynamic>;
          final hour = timeMap['hour'] as int? ?? TimeOfDay.now().hour;
          final minute = timeMap['minute'] as int? ?? TimeOfDay.now().minute;
          return TimeOfDay(hour: hour, minute: minute);
        }).toList();
      } else {
        _updateTimesBasedOnFrequency();
      }
    }
  }

  // Update times based on selected frequency
  void _updateTimesBasedOnFrequency() {
    switch (_selectedFrequency) {
      case 'Once daily':
        if (_selectedTimes.isEmpty) {
          _selectedTimes = [TimeOfDay.now()];
        } else {
          _selectedTimes = [_selectedTimes.first];
        }
        break;
      case 'Twice daily':
        if (_selectedTimes.length != 2) {
          final firstTime = _selectedTimes.isNotEmpty ? _selectedTimes.first : TimeOfDay.now();
          final secondTime = TimeOfDay(
            hour: (firstTime.hour + 12) % 24,
            minute: firstTime.minute,
          );
          _selectedTimes = [firstTime, secondTime];
        }
        break;
      case 'Three times daily':
        if (_selectedTimes.length != 3) {
          final firstTime = _selectedTimes.isNotEmpty ? _selectedTimes.first : TimeOfDay.now();
          final secondTime = TimeOfDay(
            hour: (firstTime.hour + 8) % 24,
            minute: firstTime.minute,
          );
          final thirdTime = TimeOfDay(
            hour: (firstTime.hour + 16) % 24,
            minute: firstTime.minute,
          );
          _selectedTimes = [firstTime, secondTime, thirdTime];
        }
        break;
      case 'Custom':
        if (_selectedTimes.isEmpty) {
          _selectedTimes = [TimeOfDay.now()];
        }
        break;
    }
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

        // Create or get document reference
        final docRef = widget.medicationId != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('medications')
                .doc(widget.medicationId)
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('medications')
                .doc();

        // Get the medication details
        final String medicineName = _medicineNameController.text;
        final String dose = _doseController.text;
        
        // Use the selected times directly
        List<TimeOfDay> notificationTimes = List.from(_selectedTimes);

        // Convert TimeOfDay to DateTime for storage
        List<Map<String, dynamic>> reminderTimes = notificationTimes.map((time) {
          return {
            'hour': time.hour,
            'minute': time.minute,
          };
        }).toList();

        // Prepare data for saving
        Map<String, dynamic> medicationData = {
          'medicineName': medicineName,
          'dose': dose,
          'frequency': _selectedFrequency,
          'reminderTimes': reminderTimes,
          'selectedDays': _selectedDays,
          'isActive': true,
        };

        // Add appropriate timestamp field
        if (widget.medicationId != null) {
          medicationData['updatedAt'] = FieldValue.serverTimestamp();
        } else {
          medicationData['createdAt'] = FieldValue.serverTimestamp();
        }

        // Save to Firestore
        if (widget.medicationId != null) {
          await docRef.update(medicationData);
        } else {
          await docRef.set(medicationData);
        }

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
          SnackBar(content: Text(widget.medicationId != null 
              ? 'Medication reminder updated successfully!' 
              : 'Medication reminder saved successfully!')),
        );

        // Clear form and navigate back
        if (widget.medicationId == null) {
          _medicineNameController.clear();
          _doseController.clear();
          setState(() {
            _selectedTimes = [TimeOfDay.now()];
            _selectedFrequency = 'Once daily';
          });
        }
        
        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: $e')),
        );
      }
    }
  }
  // Show time picker for specific time index
  Future<void> _selectTime(BuildContext context, int timeIndex) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: timeIndex < _selectedTimes.length ? _selectedTimes[timeIndex] : TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      setState(() {
        if (timeIndex < _selectedTimes.length) {
          _selectedTimes[timeIndex] = pickedTime;
        } else {
          _selectedTimes.add(pickedTime);
        }
      });
    }
  }

  // Add new time slot (for custom frequency)
  void _addTimeSlot() {
    setState(() {
      _selectedTimes.add(TimeOfDay.now());
    });
  }

  // Remove time slot (for custom frequency)
  void _removeTimeSlot(int index) {
    if (_selectedTimes.length > 1) {
      setState(() {
        _selectedTimes.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
              Color(0xFFF0F0F0),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildMedicationNameField(),
                const SizedBox(height: 20),
                _buildDoseField(),
                const SizedBox(height: 20),
                _buildFrequencyField(),
                const SizedBox(height: 20),
                _buildTimeSelector(),
                const SizedBox(height: 20),
                if (_selectedFrequency == 'Custom') _buildDaysSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.medicationId != null ? 'Edit Medication Reminder' : 'Set Medication Reminder',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(-10, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create New Reminder',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your medication schedule to never miss a dose',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationNameField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _medicineNameController,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'Medication Name',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter medication name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDoseField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _doseController,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'Dose (e.g., 1 tablet, 5ml)',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the dose';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFrequencyField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFrequency,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'Frequency',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.repeat_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
          filled: true,
          fillColor: Colors.transparent,
        ),
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
              _updateTimesBasedOnFrequency();
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  'Reminder Times',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_selectedFrequency == 'Custom')
                GestureDetector(
                  onTap: _addTimeSlot,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_selectedTimes.length, (index) {
            final time = _selectedTimes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectTime(context, index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF3B82F6).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _getTimeLabel(index),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedFrequency == 'Custom' && _selectedTimes.length > 1)
                        GestureDetector(
                          onTap: () => _removeTimeSlot(index),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove_rounded,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getTimeLabel(int index) {
    return 'Time ${index + 1}';
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const Text(
                'Select Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _selectedDays.length,
            (index) {
              final day = _selectedDays.keys.elementAt(index);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selectedDays[day]!
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDays[day]!
                        ? const Color(0xFF3B82F6).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selectedDays[day]!
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[700],
                    ),
                  ),
                  value: _selectedDays[day],
                  activeColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (value) {
                    setState(() {
                      _selectedDays[day] = value ?? true;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              widget.medicationId != null ? 'Update Reminder' : 'Set Reminder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}