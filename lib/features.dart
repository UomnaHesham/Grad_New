import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grad/appoinment.dart';
import 'package:grad/chatbot.dart';
import 'package:grad/finddoctor.dart';
import 'package:grad/login.dart';
import 'package:grad/my_drugs.dart';
import 'package:grad/profile_page.dart';
import 'package:grad/setReminder.dart';
import 'package:grad/medication_reminder_list_screen.dart';

class FeaturesPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Find your desire health solution'),
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {},
              color: Colors.black,
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                  (route) => false, // Prevent navigating back to the FeaturesPage
                );
              },
              color: Colors.black,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fixedSize: Size(150, 100),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FindDoctorsPage()),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Find a Doctor',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fixedSize: Size(150, 100),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MedicationReminderListScreen()),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medication_outlined, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Medication Reminders',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fixedSize: Size(150, 100),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SetReminderScreen()),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Talk to a Doctor',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fixedSize: Size(150, 100),
                      ),
                      onPressed: () {
                        // Navigate to Talk to Chat Bot page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatBotPage()),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Talk to Chat Bot',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        fixedSize: Size(150, 100),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyDrugsPage()),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medication, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'My Drugs',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),                    // Placeholder container with the same size as other buttons
                    Container(
                      width: 150,
                      height: 100,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Doctor Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDoctorCard('Dr. Marcus Horz', 'Cardiologist'),
                      _buildDoctorCard('Dr. Maria Elena', 'Psychologist'),
                      _buildDoctorCard('Dr. Stevi Jessi', 'Orthopedist'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentsPage()),
                  );
                },
                icon: Icon(Icons.calendar_today),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                icon: Icon(Icons.person),
              ),
              label: '',
            ),
          ],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDoctorCard(String name, String specialty) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8KAdt1tNrDt3W7OJlCf22Diav_eipKctRuAN4MZgrsGE3EI2V1iJdtItHXcmc40glYGQ&usqp=CAU'),
          ),
          SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            specialty,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
