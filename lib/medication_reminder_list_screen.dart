import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grad/setReminder.dart';

class MedicationReminderListScreen extends StatefulWidget {
  const MedicationReminderListScreen({Key? key}) : super(key: key);

  @override
  _MedicationReminderListScreenState createState() => _MedicationReminderListScreenState();
}

class _MedicationReminderListScreenState extends State<MedicationReminderListScreen> {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Medications'),
        ),
        body: const Center(child: Text('Please log in to view your reminders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No medication reminders set'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              try {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // Add null safety checks to all field accesses
                final medicineName = data['medicineName']?.toString() ?? 'Unnamed Medication';
                final dose = data['dose']?.toString() ?? 'No dose specified';
                final frequency = data['frequency']?.toString() ?? 'Not specified';
                final isActive = data['isActive'] as bool? ?? true;
                
                // Format the reminder times with null safety
                final reminderTimes = List<Map<String, dynamic>>.from(
                    data['reminderTimes'] ?? []);
                
                String timeString = '';
                for (var time in reminderTimes) {
                  final hour = time['hour'] as int? ?? 0;
                  final minute = time['minute'] as int? ?? 0;
                  timeString += '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, ';
                }
                if (timeString.isNotEmpty) {
                  timeString = timeString.substring(0, timeString.length - 2);
                } else {
                  timeString = 'No times set';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      medicineName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black : Colors.grey,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dose: $dose'),
                        Text('Frequency: $frequency'),
                        Text('Times: $timeString'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            // Toggle the active status
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('medications')
                                .doc(doc.id)
                                .update({'isActive': value});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Reminder'),
                                content: const Text(
                                    'Are you sure you want to delete this reminder?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Delete the reminder
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('medications')
                                          .doc(doc.id)
                                          .delete();

                                      // Close the dialog
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                // Handle any parsing errors gracefully
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red.shade100,
                  child: const ListTile(
                    title: Text(
                      "Error displaying this medication",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text("There was a problem with this reminder data"),
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SetReminderScreen(),
            ),
          );
        },
        tooltip: 'Add new medication reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
}