import 'package:flutter/material.dart';
import 'package:grad/startpage.dart';

class Opening extends StatefulWidget {
  @override
  _OpeningState createState() => _OpeningState();
}

class _OpeningState extends State<Opening> {
  @override
  void initState() {
    super.initState();

    // Delay for 3 seconds before navigating to Startpage
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Startpage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 63, 198, 255),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(
              image: NetworkImage(
                  'https://st2.depositphotos.com/4362315/7819/v/450/dep_78194060-Medical-logo.health-care-center.jpg'),
              width: 200,
              height: 200,
            ),
            SizedBox(height: 10),
            Text(
              "Health Care",
              style: TextStyle(fontSize: 40, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
