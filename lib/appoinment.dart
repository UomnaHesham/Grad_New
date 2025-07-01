import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grad/Doctordetails.dart';

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
      backgroundColor: Color(0xFFF8FAFE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            "My Appointments",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A90E2),
            ),
          ),
        ),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4A90E2), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A90E2).withOpacity(0.1),
                  Color(0xFFF8FAFE),
                  Colors.white,
                ],
              ),
            ),
          ),
          patientId == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                )
              : StreamBuilder(
                  stream: _appointmentsStream,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print("No appointments found for patient ID: $patientId");
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 80,
                                    color: Color(0xFF4A90E2).withOpacity(0.5),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "No Appointments Found",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E3A59),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "You don't have any scheduled appointments",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    print("Appointments retrieved: ${snapshot.data!.docs.length}");
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var appointment = snapshot.data!.docs[index];
                          print("Appointment data: ${appointment.data()}");
                          return AppointmentCard(
                            appointmentId: appointment.id,
                            doctorId: appointment['doctorId'],
                            doctorName: appointment['doctorName'],
                            specialization: appointment['specialization'],
                            date: appointment['day'],
                            time: appointment['time'],
                            status: appointment['status'] ?? 'Scheduled',
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String date;
  final String time;
  final String status;

  const AppointmentCard({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.date,
    required this.time,
    required this.status,
  });

  void _cancelAppointment(BuildContext context) async {
    await FirebaseFirestore.instance.collection('Reservations').doc(appointmentId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Appointment cancelled")));
  }

  void _rescheduleAppointment(BuildContext context) async {
    // Show confirmation dialog first
    final shouldReschedule = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Reschedule Appointment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current appointment:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3A59),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF4A90E2).withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: Color(0xFF4A90E2), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Dr. $doctorName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        specialization,
                        style: TextStyle(
                          color: Color(0xFF4A90E2),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '$date',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '$time',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Do you want to reschedule this appointment?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4A90E2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Reschedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReschedule != true) return;

    try {
      // Get doctor data from Firestore
      final doctorDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data() as Map<String, dynamic>;
        
        // Navigate to doctor details page for rescheduling
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailsPage(
              doctorData: doctorData,
              doctorId: doctorId,
            ),
          ),
        );

        // If a new appointment was booked, cancel the old one
        if (result == true) {
          await FirebaseFirestore.instance
              .collection('Reservations')
              .doc(appointmentId)
              .delete();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Appointment rescheduled successfully!")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Doctor information not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rescheduling appointment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.15),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 20,
            offset: Offset(-5, -5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Color(0xFF4A90E2),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Dr. $doctorName",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        specialization,
                        style: TextStyle(
                          color: Color(0xFF4A90E2),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Appointment Details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF4A90E2).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4A90E2),
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: Color(0xFF4A90E2),
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Time",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Status Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Status: ${status.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _cancelAppointment(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4A90E2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => _rescheduleAppointment(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Reschedule",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'Scheduled':
        return Color(0xFF4A90E2);
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in-progress':
        return Colors.orange;
      default:
        return Color(0xFF4A90E2);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'Scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'in-progress':
        return Icons.timer;
      default:
        return Icons.schedule;
    }
  }
}
