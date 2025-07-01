import 'package:flutter/material.dart';
import 'package:grad/createnewpassword.dart';

class EnterCodePage extends StatefulWidget {
  final String email;
  final String verificationCode;

  const EnterCodePage({
    Key? key,
    required this.email,
    required this.verificationCode,
  }) : super(key: key);

  @override
  _EnterCodePageState createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getEnteredCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _verifyCode() {
    final enteredCode = _getEnteredCode();
    
    if (enteredCode.length != 6) {
      _showErrorDialog('Please enter the complete 6-digit verification code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate verification process
    Future.delayed(Duration(seconds: 2), () {
      if (enteredCode == widget.verificationCode) {
        setState(() {
          _isLoading = false;
        });
        // Navigate to reset password page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: widget.email),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Invalid verification code. Please try again.');
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _resendCode() {
    // Implement resend functionality here
    _showSuccessDialog('Verification code has been resent to ${widget.email}');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Verification Code'),
        backgroundColor: Color.fromARGB(255, 63, 198, 255),
        foregroundColor: Colors.white,
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
              "Enter the 6-digit code that we have sent to ${widget.email}",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 63, 198, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      
                      // Auto-verify when all digits are entered
                      if (index == 5 && value.isNotEmpty) {
                        _verifyCode();
                      }
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 63, 198, 255),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Verifying...",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        "Verify",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _resendCode,
                child: Text(
                  "Didn't receive the code? Resend",
                  style: TextStyle(color: Color.fromARGB(255, 63, 198, 255)),
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                "Code expires in 15 minutes",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
