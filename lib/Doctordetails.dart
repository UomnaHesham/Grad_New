import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/doctor_rating_helper.dart';

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

  Future<bool> bookAppointment(String day, String time, String patientName, String patientPhone, String patientId) async {
    if (bookedTimes.contains(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This time slot is already booked. Please choose another.')),
      );
      return false;
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
      'status': 'scheduled',
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
      return true;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: $error')),
      );
      return false;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3A59),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorData = widget.doctorData;

    final doctorName = doctorData['fullName'] ?? 'Unknown Doctor';
    final specialization = doctorData['Specialization'] ?? 'Unknown Specialization';
    final profileImage = doctorData['profileImage'] ?? 'https://via.placeholder.com/150';
    final aboutDoctor = doctorData['about'] ?? 'No information available about this doctor.';
    final availableDays = doctorData['Days'] ?? [];
    final startTime = doctorData['Start'] ?? '9:00 AM';
    final duration = doctorData['Duration'] ?? '15 min';
    final visitsLeft = int.tryParse(doctorData['Visits'].toString()) ?? 0;

    final reservationTimes = calculateReservationTimes(startTime, duration, visitsLeft);

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
            'Doctor Details',
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
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Doctor Card with Glass Effect
                  Container(
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
                      children: [
                        Row(
                          children: [
                            // Enhanced Doctor Avatar with Glow Effect
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4A90E2).withOpacity(0.2),
                                    Color(0xFF57B9FF).withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4A90E2).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(4),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(profileImage),
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Doctor Name with Icon
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Color(0xFF4A90E2),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          doctorName,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E3A59),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  // Enhanced Specialization Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF4A90E2).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          specialization,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Rating and Stats Row
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFF4A90E2).withOpacity(0.1),
                            ),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: DoctorRatingHelper.calculateDoctorRating(widget.doctorId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    SizedBox(width: 6),
                                    Text('Loading...', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                );
                              }
                              
                              final ratingData = snapshot.data ?? {'rating': 'N/A', 'reviewCount': 0};
                              final rating = ratingData['rating'];
                              final reviewCount = ratingData['reviewCount'];
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      double ratingNum = double.tryParse(rating.toString()) ?? 0.0;
                                      return Icon(
                                        index < ratingNum.floor()
                                            ? Icons.star
                                            : index < ratingNum
                                                ? Icons.star_half
                                                : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$rating (${reviewCount} reviews)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // About Doctor Section with Enhanced Design
                  _buildSectionTitle('About Doctor', Icons.info_outline),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.description,
                                color: Color(0xFF4A90E2),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Professional Background',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E3A59),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          aboutDoctor,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Select Date Section with Enhanced Design
                  _buildSectionTitle('Select Date', Icons.calendar_month),
                  SizedBox(height: 20),
                  Container(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableDays.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedDateIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDateIndex = index;
                              fetchBookedTimes(availableDays[index]);
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 120,
                            margin: EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4A90E2),
                                        Color(0xFF57B9FF),
                                        Color(0xFF6EC6FF),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [Colors.white, Colors.white],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Color(0xFF4A90E2).withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                      ? Color(0xFF4A90E2).withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: isSelected ? 15 : 10,
                                  offset: Offset(0, isSelected ? 8 : 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: isSelected ? Colors.white : Color(0xFF4A90E2),
                                  size: 24,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  availableDays[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Color(0xFF2E3A59),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 32),

                  // Select Time Section with Enhanced Design
                  _buildSectionTitle('Select Time', Icons.access_time),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                      ),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: reservationTimes.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedTimeIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTimeIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [Color(0xFFF8FAFE), Colors.white],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Color(0xFF4A90E2).withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected 
                                      ? Color(0xFF4A90E2).withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.05),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: Offset(0, isSelected ? 6 : 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: isSelected ? Colors.white : Color(0xFF4A90E2),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  reservationTimes[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Color(0xFF2E3A59),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 40),

                  // Enhanced Book Appointment Button
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4A90E2),
                          Color(0xFF57B9FF),
                          Color(0xFF6EC6FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4A90E2).withOpacity(0.4),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedDateIndex == -1 || selectedTimeIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Please select a date and time'),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else {
                          User? user = FirebaseAuth.instance.currentUser;
                          String patientId = user?.uid ?? '';

                          if (patientId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('User not logged in!'),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(patientId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      content: Container(
                                        padding: EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                                            ),
                                            SizedBox(width: 20),
                                            Text(
                                              'Loading user data...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  String defaultName = '';
                                  String defaultPhone = '';
                                  
                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                    defaultName = userData?['name'] ?? '';
                                    defaultPhone = userData?['phone'] ?? '';
                                  }

                                  final nameController = TextEditingController(text: defaultName);
                                  final phoneController = TextEditingController(text: defaultPhone);

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
                                          Icon(Icons.book_online, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text(
                                            'Confirm Reservation',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.1)),
                                          ),
                                          child: TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              labelText: 'Patient Name',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                                              ),
                                              prefixIcon: Container(
                                                margin: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF4A90E2).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.person, color: Color(0xFF4A90E2)),
                                              ),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.1)),
                                          ),
                                          child: TextField(
                                            controller: phoneController,
                                            decoration: InputDecoration(
                                              labelText: 'Patient Phone',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                                              ),
                                              prefixIcon: Container(
                                                margin: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF4A90E2).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.phone, color: Color(0xFF4A90E2)),
                                              ),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                            ),
                                            keyboardType: TextInputType.phone,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
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
                                          onPressed: () async {
                                            final patientName = nameController.text.trim();
                                            final patientPhone = phoneController.text.trim();
                                            
                                            if (patientName.isEmpty || patientPhone.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(Icons.warning, color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Text('Please fill in all fields'),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.orange,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            
                                            final success = await bookAppointment(
                                              availableDays[selectedDateIndex],
                                              reservationTimes[selectedTimeIndex],
                                              patientName,
                                              patientPhone,
                                              patientId,
                                            );
                                            Navigator.pop(context);
                                            if (success) {
                                              Navigator.pop(context, true);
                                            }
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Confirm',
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
                            },
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Book Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
