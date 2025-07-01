import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grad/login.dart';

class Signup extends StatefulWidget {
  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  var namecontroller = TextEditingController();
  var phonecontroller = TextEditingController();
  var emailcontroller = TextEditingController();
  var passcontroller = TextEditingController();
  var dobcontroller = TextEditingController();
  var addresscontroller = TextEditingController();
  var formKey = GlobalKey<FormState>();
  bool isPassword = true;
  bool _isLoading = false;
  String? selectedGender;

  void signUp() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Make sure Firebase is initialized
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }

        // Get Firebase auth instance
        final auth = FirebaseAuth.instance;
        
        // Create user with Firebase Authentication
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: emailcontroller.text.trim(),
          password: passcontroller.text.trim(),
        );

        // Get the user's unique ID
        String userId = userCredential.user!.uid;

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': namecontroller.text.trim(),
          'phone': phonecontroller.text.trim(),
          'email': emailcontroller.text.trim(),
          'password': passcontroller.text.trim(),
          'dob': dobcontroller.text.trim(),
          'address': addresscontroller.text.trim(),
          'gender': selectedGender,
          'created_at': DateTime.now(),
        });

        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created successfully")),
        );

        // Navigate to login screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);

        // Handle Firebase Authentication errors
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'This email is already in use.';
        } else if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else {
          message = 'Authentication error: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        setState(() => _isLoading = false);

        // Handle any other errors
        print('Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Join us to get started!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      
                      // Email Address Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: emailcontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty || !value.contains('@')) {
                                return 'Invalid Email';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your Email Address',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF4A90E2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Full Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: namecontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name must not be empty';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: 'Enter your Full Name',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4A90E2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: passcontroller,
                            obscureText: isPassword,
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value == null || value.trim().length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF4A90E2)),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPassword = !isPassword;
                                  });
                                },
                                icon: Icon(
                                  isPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Phone Number Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: phonecontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number must not be empty';
                              }
                              if (value.length < 10) {
                                return 'Phone number must be at least 10 digits';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter your Phone Number',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF4A90E2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Date of Birth Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: dobcontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Date of birth must not be empty';
                              }
                              return null;
                            },
                            readOnly: true,
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                dobcontroller.text = "${picked.day}/${picked.month}/${picked.year}";
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your Date of Birth',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFF4A90E2)),
                              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Address Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: addresscontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Address must not be empty';
                              }
                              return null;
                            },
                            maxLines: 2,
                            keyboardType: TextInputType.streetAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your Address',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF4A90E2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Gender Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Gender must be selected';
                              }
                              return null;
                            },
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGender = newValue;
                              });
                            },
                            items: <String>['Male', 'Female'].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      value == 'Male' ? Icons.male : Icons.female,
                                      color: Color(0xFF4A90E2),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              hintText: 'Select your Gender',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.people_outline, color: Color(0xFF4A90E2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(height: 30),
                      
                      // Create Account Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4A90E2).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: _isLoading ? null : signUp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => Login()),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
