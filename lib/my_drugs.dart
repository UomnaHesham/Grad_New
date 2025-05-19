import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'doctor_survey.dart';

class MyDrugsPage extends StatefulWidget {
  const MyDrugsPage({Key? key}) : super(key: key);

  @override
  _MyDrugsPageState createState() => _MyDrugsPageState();
}

class _MyDrugsPageState extends State<MyDrugsPage> {
  // Cache for doctor names to avoid repetitive fetches
  Map<String, String> _doctorNameCache = {};
  
  // Selected doctor ID - null means we're on the doctor selection screen
  String? _selectedDoctorId;
  
  // Helper method to get month name from month number
  String _getMonthName(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];  }
  
  // Fetch doctor name from Firestore
  Future<String> _getDoctorName(String doctorId) async {
    // Check cache first
    if (_doctorNameCache.containsKey(doctorId)) {
      return _doctorNameCache[doctorId]!;
    }
    
    try {
      // First try the Doctors collection (capital D) - main collection for doctors
      final doctorsCapitalDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();
          
      if (doctorsCapitalDoc.exists) {
        final data = doctorsCapitalDoc.data();
        final name = data?['name'] ?? data?['fullName'] ?? data?['displayName'] ?? 'Unknown Doctor';
        final formattedName = !name.toLowerCase().startsWith('dr') ? 'Dr. $name' : name;
        // Cache the result
        _doctorNameCache[doctorId] = formattedName;
        print('Found doctor name in Doctors collection: $formattedName for ID: $doctorId');
        return formattedName;
      }
      
      // Try doctors collection (lowercase d) as fallback
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      
      if (doctorDoc.exists) {
        final data = doctorDoc.data();
        final name = data?['name'] ?? data?['fullName'] ?? 'Unknown Doctor';
        final formattedName = !name.toLowerCase().startsWith('dr') ? 'Dr. $name' : name;
        // Cache the result
        _doctorNameCache[doctorId] = formattedName;
        print('Found doctor name in doctors collection: $formattedName for ID: $doctorId');
        return formattedName;
      } 
      
      // If not found in doctors collections, try users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final name = data?['name'] ?? data?['fullName'] ?? data?['displayName'] ?? 'Unknown Doctor';
        // Check if this is actually a doctor
        final role = data?['role']?.toString().toLowerCase() ?? '';
        final isDoctor = role.contains('doctor') || role == 'dr' || data?['isDoctor'] == true;
        
        // Cache the result, adding "Dr." prefix if this is a doctor
        final formattedName = isDoctor && !name.toLowerCase().startsWith('dr') ? 'Dr. $name' : name;
        _doctorNameCache[doctorId] = formattedName;
        print('Found doctor name in users collection: $formattedName for ID: $doctorId');
        return formattedName;
      }
      
      // If not found in any collection
      final fallbackName = 'Dr. ' + doctorId.substring(0, doctorId.length > 8 ? 8 : doctorId.length);
      _doctorNameCache[doctorId] = fallbackName;
      print('Could not find doctor name for ID: $doctorId, using fallback: $fallbackName');
      return fallbackName;
    } catch (e) {
      print('Error fetching doctor name: $e');
      final fallbackName = 'Dr. ' + doctorId.substring(0, doctorId.length > 8 ? 8 : doctorId.length);
      _doctorNameCache[doctorId] = fallbackName;
      return fallbackName;
    }
  }
  
  // Method to fetch drugs for a specific patient ID (useful for testing)
  Future<void> _fetchDrugsForPatient(String patientId) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Drugs')
          .where('patientId', isEqualTo: patientId)
          .get();
      
      print('Found ${snapshot.docs.length} documents for patient ID: $patientId');
      
      int totalMedications = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> medications = data['medications'] ?? [];
        
        print('Document ID: ${doc.id}');
        print('Doctor ID: ${data['doctorId']}');
        print('Created: ${data['createdAt']?.toDate()}');
        print('Updated: ${data['updatedAt']?.toDate()}');
        print('Total medications in this document: ${medications.length}');
        
        for (int i = 0; i < medications.length; i++) {
          final med = medications[i];
          print('  Medication #${i+1}:');
          print('    Name: ${med['name']}');
          print('    Times: ${med['times']}');
          totalMedications++;
        }
        print('--------------------');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found $totalMedications medications for test patient')),
      );
      
      setState(() {
        // Refresh the UI after testing
      });
    } catch (e) {
      print('Error fetching drugs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drugs: $e')),
      );    }
  }
  
  // Navigate to the doctor survey page
  void _navigateToSurvey(String doctorName, String doctorId) async {
    // Navigate to the survey page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorSurveyPage(
          doctorId: doctorId,
          doctorName: doctorName,
        ),
      ),
    );
    
    // Show thank you message if survey was submitted
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Build the doctor selection screen
  Widget _buildDoctorSelectionScreen(List<String> doctorIds, Map<String, List<Map<String, dynamic>>> medicationsByDoctor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Doctor to View Medications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: doctorIds.length,
              itemBuilder: (context, index) {
                final doctorId = doctorIds[index];
                final medications = medicationsByDoctor[doctorId] ?? [];
                
                return FutureBuilder<String>(
                  future: _getDoctorName(doctorId),
                  builder: (context, snapshot) {
                    final doctorName = snapshot.data ?? 'Loading doctor name...';
                      return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedDoctorId = doctorId;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.person,
                                  size: 36,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [                                    Text(
                                      doctorName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${medications.length} medication(s)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Drugs'),
        ),
        body: const Center(child: Text('Please log in to view your drugs')),
      );
    }      return Scaffold(
      appBar: AppBar(
        title: _selectedDoctorId == null 
          ? const Text('Select Doctor')
          : FutureBuilder<String>(
              future: _getDoctorName(_selectedDoctorId!),
              builder: (context, snapshot) {                final doctorName = snapshot.data ?? 'Loading...';
                return Text('$doctorName\'s Medications');
              },
            ),
        // Add back button if a doctor is selected
        leading: _selectedDoctorId != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedDoctorId = null;
                });
              },
            ) 
          : null,
        actions: [
          if (_selectedDoctorId != null)
            TextButton.icon(
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('Change Doctor', style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedDoctorId = null;
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Drugs')
            .where('patientId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }          
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No drugs found'));
          }
            // Group medications by doctor
          Map<String, List<Map<String, dynamic>>> medicationsByDoctor = {};
          
          // Collect doctor IDs
          Set<String> doctorIds = {};
            // Iterate through all documents and collect medication items
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final medications = data['medications'] as List<dynamic>?;
            final doctorId = data['doctorId']?.toString() ?? 'unknown';
            
            // Add doctor to the set
            doctorIds.add(doctorId);
            
            if (medications != null) {
              // Initialize the doctor's list if it doesn't exist
              if (!medicationsByDoctor.containsKey(doctorId)) {
                medicationsByDoctor[doctorId] = [];
              }
              
              for (var med in medications) {
                if (med is Map<String, dynamic>) {
                  // Add document ID and timestamp information to each medication
                  final Map<String, dynamic> medicationWithMeta = {...med};
                  medicationWithMeta['documentId'] = doc.id;
                  medicationWithMeta['updatedAt'] = data['updatedAt'];
                  medicationWithMeta['createdAt'] = data['createdAt'];
                  medicationWithMeta['doctorId'] = doctorId;
                  medicationsByDoctor[doctorId]!.add(medicationWithMeta);
                }
              }
            }
          }
          
          if (medicationsByDoctor.isEmpty) {
            return const Center(child: Text('No medications found'));
          }
          
          // If no doctor is selected, show doctor selection screen
          if (_selectedDoctorId == null) {
            return _buildDoctorSelectionScreen(doctorIds.toList(), medicationsByDoctor);
          }
            // If doctor is selected, show medications for that doctor
          final medications = medicationsByDoctor[_selectedDoctorId] ?? [];
          
          return FutureBuilder<String>(
            future: _getDoctorName(_selectedDoctorId!),
            builder: (context, doctorSnapshot) {
              final doctorName = doctorSnapshot.data ?? 'Loading doctor name...';
              
              if (medications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [                      Text(doctorName, 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text('No medications found for this doctor'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDoctorId = null;
                          });
                        },
                        child: const Text('Back to Doctor Selection'),
                      ),
                    ],
                  ),
                );
              }
                return Column(
                children: [                  // Doctor information header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                doctorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Text(
                              '${medications.length} medications',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.star, color: Colors.amber),
                            label: const Text('Rate This Doctor'),
                            onPressed: () {
                              _navigateToSurvey(doctorName, _selectedDoctorId!);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Medications list
                  Expanded(
                    child: ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {              
              try {
                final medication = medications[index];
                
                // Get drug name and times directly from medication
                final drugName = medication['name']?.toString() ?? 'Unnamed Drug';
                
                // Handle times array 
                final times = List<String>.from(medication['times'] ?? []);
                
                // Get updatedAt timestamp if available
                final Timestamp? updatedTimestamp = medication['updatedAt'] as Timestamp?;
                final String updatedAt = updatedTimestamp != null 
                    ? '${updatedTimestamp.toDate().day} ${_getMonthName(updatedTimestamp.toDate().month)} ${updatedTimestamp.toDate().year}'
                    : 'Date not available';
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 63, 198, 255),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drugName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),                                  const SizedBox(height: 4),
                                  Text(
                                    'Schedule: ${times.length} times a day',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated: $updatedAt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scheduled Times:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: times.map((time) => Chip(
                            backgroundColor: const Color.fromARGB(255, 236, 249, 255),
                            label: Text(
                              time,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 63, 198, 255),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: Color.fromARGB(255, 63, 198, 255),
                                width: 1,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last Updated: $updatedAt',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              onPressed: () {
                                // Edit functionality can be added here
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              onPressed: () {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Drug'),
                                    content: const Text(
                                        'Are you sure you want to delete this drug?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Get document reference
                                          final docId = medication['documentId'];
                                          final docRef = FirebaseFirestore.instance
                                              .collection('Drugs')
                                              .doc(docId);
                                              
                                          // Get current medications array
                                          final docSnapshot = await docRef.get();
                                          if (docSnapshot.exists) {
                                            final data = docSnapshot.data() as Map<String, dynamic>;
                                            final medications = List<dynamic>.from(data['medications'] ?? []);
                                            
                                            // Find and remove the medication with same name
                                            int indexToRemove = -1;
                                            for (int i = 0; i < medications.length; i++) {
                                              if (medications[i]['name'] == drugName) {
                                                indexToRemove = i;
                                                break;
                                              }
                                            }
                                            
                                            if (indexToRemove >= 0) {
                                              medications.removeAt(indexToRemove);
                                              
                                              // Update the document with new medications array
                                              await docRef.update({
                                                'medications': medications,
                                                'updatedAt': FieldValue.serverTimestamp(),
                                              });
                                            }
                                          }

                                          // Close the dialog
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
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
                      "Error displaying this drug",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text("There was a problem with this drug data"),
                  ),
                );              }
            },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
