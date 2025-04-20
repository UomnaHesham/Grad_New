import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/Doctordetails.dart';

class SpecialistDoctorsPage extends StatelessWidget {
  final String specialization;

  SpecialistDoctorsPage({required this.specialization});

  // Function to fetch doctors from Firestore based on specialization
  Future<List<QueryDocumentSnapshot>> _fetchDoctors() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Doctors') // Firestore collection
        .where('Specialization', isEqualTo: specialization) // Filter by specialization
        .get();

    return snapshot.docs; // Return all matching documents
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$specialization Specialists'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading doctors: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No doctors found for this specialization'));
          }

          List<QueryDocumentSnapshot> doctors = snapshot.data!;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              // Map doctor data from Firestore
              Map<String, dynamic> doctorData = doctors[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      doctorData['profileImage'] ??
                          'https://via.placeholder.com/150', // Fallback image
                    ),
                  ),
                  title: Text(doctorData['fullName'] ?? 'Unknown Doctor'),
                  subtitle: Text('${doctorData['Visits'] ?? 0} visits'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to Doctor Details Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorDetailsPage(
                          doctorData: doctorData,
                          doctorId: doctors[index].id, // Pass the doctorId
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
