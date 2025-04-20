import 'package:flutter/material.dart';
import 'package:grad/verificationpassword.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool isPhoneSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Your Password?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Forgot Your Password?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Enter your email or your phone number, we will send you a confirmation code",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPhoneSelected = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: !isPhoneSelected ?Color.fromARGB(255, 63, 198, 255) : Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      child: Text(
                        "Email",
                        style: TextStyle(
                          color: !isPhoneSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPhoneSelected = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPhoneSelected ?Color.fromARGB(255, 63, 198, 255) : Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      child: Text(
                        "Phone",
                        style: TextStyle(
                          color: isPhoneSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: isPhoneSelected ? "Phone" : "Email",
                prefixIcon: isPhoneSelected
                    ? Icon(Icons.phone)
                    : Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:const Color.fromARGB(255, 63, 198, 255),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                    Navigator.push(context,MaterialPageRoute(builder: (context)=> EnterCodePage()),);

                },
                child: Text("Reset Password",style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
