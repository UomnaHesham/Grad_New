import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grad/features.dart';
import 'package:grad/forgetpassword.dart';
import 'package:grad/signup.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Controllers for email and password input
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // State for password visibility toggle
  bool isPassword = true;
  bool _isLoading = false;

  // Login function
  Future<void> loginUser() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Make sure Firebase is initialized
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        
        // Get Firebase instances
        final auth = FirebaseAuth.instance;
        final firestore = FirebaseFirestore.instance;
        
        // Authenticate with Firebase Authentication
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Log the authenticated user's UID
        final String userId = userCredential.user!.uid;
        print('Authenticated User UID: $userId');

        // Fetch user data from Firestore
        DocumentSnapshot userData = await firestore.collection('users').doc(userId).get();

        setState(() => _isLoading = false);

        if (userData.exists) {
          print('User data exists: ${userData.data()}');

          // Navigate to FeaturesPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FeaturesPage()),
          );
        } else {
          print('User data does not exist in Firestore');
          await auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not found in the database.")),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        
        // Handle Firebase authentication errors
        print('FirebaseAuthException: ${e.code}');
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        } else {
          message = 'Authentication error: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } on FirebaseException catch (e) {
        setState(() => _isLoading = false);
        
        // Handle Firestore-specific errors
        print('FirebaseException: ${e.code}');
        print('Message: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore error: ${e.message}')),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        
        // Catch any other errors
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 198, 255),
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email Input Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email must not be empty';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    labelText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Input Field
                TextFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: isPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password must not be empty';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPassword = !isPassword;
                        });
                      },
                      icon: Icon(
                        isPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    labelText: 'Enter your password',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forget Password?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 63, 198, 255),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : loginUser,
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                  ),
                ),
                const SizedBox(height: 20),

                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
                      child: const Text('Register now'),
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
