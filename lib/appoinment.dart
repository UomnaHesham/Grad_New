import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  Stream<QuerySnapshot>? _appointmentsStream;
  String? patientId;

  @override
  void initState() {
    super.initState();
    _loadPatientId();
  }

  Future<void> _loadPatientId() async {
    await Firebase.initializeApp(); // Ensure Firebase is initialized
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      patientId = user.uid;
      print("Authenticated User UID: $patientId");
      _fetchAppointments();
    } else {
      print("No user logged in");
    }
  }

  void _fetchAppointments() {
    if (patientId != null && patientId!.isNotEmpty) {
      _appointmentsStream = FirebaseFirestore.instance
          .collection('Reservations')
          .where('patientId', isEqualTo: patientId)
          .snapshots();
      setState(() {});
    } else {
      print("Patient ID is null or empty");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Appointments"),
        centerTitle: true,
      ),
      body: patientId == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: _appointmentsStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("No appointments found for patient ID: $patientId");
                  return Center(child: Text("No Appointments Found"));
                }

                print("Appointments retrieved: ${snapshot.data!.docs.length}");
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var appointment = snapshot.data!.docs[index];
                    print("Appointment data: ${appointment.data()}");
                    return AppointmentCard(
                      appointmentId: appointment.id,
                      doctorName: appointment['doctorName'],
                      specialization: appointment['specialization'],
                      date: appointment['day'],
                      time: appointment['time'],
                    );
                  },
                );
              },
            ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String doctorName;
  final String specialization;
  final String date;
  final String time;

  const AppointmentCard({
    required this.appointmentId,
    required this.doctorName,
    required this.specialization,
    required this.date,
    required this.time,
  });

  void _cancelAppointment(BuildContext context) async {
    await FirebaseFirestore.instance.collection('Reservations').doc(appointmentId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Appointment cancelled")));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dr. $doctorName",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(specialization, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(date),
                SizedBox(width: 10),
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(time),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _cancelAppointment(context),
                  child: Text("Cancel"),
                  style: TextButton.styleFrom(backgroundColor: Colors.grey[300]),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () {},
                  child: Text("Reschedule"),
                  style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
