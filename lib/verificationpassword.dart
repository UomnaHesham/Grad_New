import 'package:flutter/material.dart';
import 'package:grad/createnewpassword.dart';

class EnterCodePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Verification Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter Verification Code",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Enter code that we have sent to your number",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:Color.fromARGB(255, 63, 198, 255),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                      Navigator.push(context,MaterialPageRoute(builder: (context)=> ResetPasswordPage()),);

                },
                child: Text("Verify",style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Didn’t receive the code? Resend",
                  style: TextStyle(color:Color.fromARGB(255, 63, 198, 255)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
