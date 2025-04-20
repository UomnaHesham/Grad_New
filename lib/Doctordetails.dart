import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  DoctorDetailsPage({required this.doctorData, required this.doctorId});

  @override
  _DoctorDetailsPageState createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  int selectedDateIndex = -1;
  int selectedTimeIndex = -1;
  List<String> bookedTimes = []; // To track booked times for the selected day

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchBookedTimes(String day) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Reservations')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('day', isEqualTo: day)
        .get();

    List<String> times = snapshot.docs.map((doc) => doc['time'] as String).toList();
    setState(() {
      bookedTimes = times;
    });
  }

  List<String> calculateReservationTimes(String startTime, String duration, int visitsLeft) {
    List<String> times = [];
    int durationInMinutes = int.parse(duration.split(' ')[0]);
    int startHour = int.parse(startTime.split(' ')[0]);
    String period = startTime.split(' ')[1];

    if (period == 'PM' && startHour != 12) {
      startHour += 12;
    }

    DateTime time = DateTime(2023, 1, 1, startHour, 0);
    for (int i = 0; i < visitsLeft; i++) {
      String formattedTime =
          "${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";

      if (!bookedTimes.contains(formattedTime)) {
        times.add(formattedTime);
      }

      time = time.add(Duration(minutes: durationInMinutes));
    }

    return times;
  }

  void bookAppointment(String day, String time, String patientName, String patientPhone, String patientId) async {
    if (bookedTimes.contains(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This time slot is already booked. Please choose another.')),
      );
      return;
    }

    final reservationDetails = {
      'doctorId': widget.doctorId,
      'patientId': patientId,
      'doctorName': widget.doctorData['fullName'],
      'specialization': widget.doctorData['Specialization'],
      'patientName': patientName,
      'patientPhone': patientPhone,
      'day': day,
      'time': time,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('Reservations').add(reservationDetails);

      setState(() {
        bookedTimes.add(time);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment reserved successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorData = widget.doctorData;

    final doctorName = doctorData['fullName'] ?? 'Unknown Doctor';
    final specialization = doctorData['Specialization'] ?? 'Unknown Specialization';
    final profileImage = doctorData['profileImage'] ?? 'https://via.placeholder.com/150';
    final rating = doctorData['rating'] ?? 'N/A';
    final aboutDoctor = doctorData['about'] ?? 'No information available about this doctor.';
    final availableDays = doctorData['Days'] ?? [];
    final startTime = doctorData['Start'] ?? '9:00 AM';
    final duration = doctorData['Duration'] ?? '15 min';
    final visitsLeft = int.tryParse(doctorData['Visits'].toString()) ?? 0;

    final reservationTimes = calculateReservationTimes(startTime, duration, visitsLeft);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Doctor Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor profile details
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(profileImage),
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        specialization,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          Text(rating.toString(), style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),

              // About Doctor Section
              Text(
                'About Doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                aboutDoctor,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),

              // Select Date Section
              Text(
                'Select Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableDays.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDateIndex = index;
                          fetchBookedTimes(availableDays[index]);
                        });
                      },
                      child: Container(
                        width: 80,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: selectedDateIndex == index ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            availableDays[index],
                            style: TextStyle(
                              color: selectedDateIndex == index ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Select Time Section
              Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: reservationTimes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTimeIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedTimeIndex == index ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        reservationTimes[index],
                        style: TextStyle(
                          color: selectedTimeIndex == index ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Book Appointment Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (selectedDateIndex == -1 || selectedTimeIndex == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please select a date and time'),
                    ));
                  } else {
                    String patientName = '';
                    String patientPhone = '';
                    User? user = FirebaseAuth.instance.currentUser;
                    String patientId = user?.uid ?? '';

                    if (patientId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('User not logged in!'),
                      ));
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirm Reservation'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: InputDecoration(labelText: 'Patient Name'),
                                onChanged: (value) {
                                  patientName = value;
                                },
                              ),
                              TextField(
                                decoration: InputDecoration(labelText: 'Patient Phone'),
                                keyboardType: TextInputType.phone,
                                onChanged: (value) {
                                  patientPhone = value;
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                bookAppointment(
                                  availableDays[selectedDateIndex],
                                  reservationTimes[selectedTimeIndex],
                                  patientName,
                                  patientPhone,
                                  patientId,
                                );
                                Navigator.pop(context);
                              },
                              child: Text('Confirm'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Center(
                  child: Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
