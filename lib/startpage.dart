import 'package:flutter/material.dart';
import 'package:grad/login.dart';
import 'package:grad/signup.dart';

class Startpage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Adding the image above the text
            Image(
              image: NetworkImage(
                  'https://st2.depositphotos.com/4362315/7819/v/450/dep_78194060-Medical-logo.health-care-center.jpg'),
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),

            // Title text
            Text(
              "Health Clinic Care",
              style: TextStyle(
                fontSize: 40,
                color: const Color.fromARGB(255, 63, 198, 255),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Login Button (Blue Background)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 63, 198, 255), // Blue background
                foregroundColor: Colors.white, // White text color
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Login'),
            ),
            SizedBox(height: 10),

            // Sign Up Button (Blue Border)
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signup()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: const Color.fromARGB(255, 63, 198, 255), width: 2), // Blue border
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Sign Up',
                style: TextStyle(color: const Color.fromARGB(255, 63, 198, 255)), // Blue text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
