import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoctorSurveyPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorSurveyPage({
    Key? key, 
    required this.doctorId,
    required this.doctorName,
  }) : super(key: key);

  @override
  _DoctorSurveyPageState createState() => _DoctorSurveyPageState();
}

class _DoctorSurveyPageState extends State<DoctorSurveyPage> {
  // Survey responses
  String? _clinicRating;
  String? _staffHelpfulness;
  String? _doctorCourtesy;
  String? _explanationClarity;
  String? _waitTimeRating;
  String? _appointmentEase;
  String? _chooseAgain;
  String? _mainReason;
  
  bool _isSubmitting = false;

  // Questions and options
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Compared to other clinics, how would you rate this one?',
      'options': ['Much better', 'Slightly better', 'About the same', 'Worse'],
      'response': '_clinicRating',
    },
    {
      'question': 'Were the front-desk staff helpful and polite?',
      'options': ['Extremely helpful', 'Somewhat helpful', 'Unhelpful'],
      'response': '_staffHelpfulness',
    },
    {
      'question': 'Was the doctor courteous and respectful?',
      'options': ['Very satisfied', 'Satisfied', 'Neutral', 'Dissatisfied', 'Very dissatisfied'],
      'response': '_doctorCourtesy',
    },
    {
      'question': 'Did the doctor explain your condition and treatment clearly?',
      'options': ['Yes, very clearly', 'Somewhat clearly', 'Not clearly', 'Not at all'],
      'response': '_explanationClarity',
    },
    {
      'question': 'How would you rate your wait time?',
      'options': ['Very short', 'Acceptable', 'Long', 'Very long'],
      'response': '_waitTimeRating',
    },
    {
      'question': 'How easy was it to schedule or reschedule your appointment?',
      'options': ['Very easy', 'Easy', 'Neutral', 'Difficult', 'Very difficult'],
      'response': '_appointmentEase',
    },
    {
      'question': 'Would you choose this doctor again?',
      'options': ['Definitely', 'Probably', 'No'],
      'response': '_chooseAgain',
    },
    {
      'question': 'What is the main reason for your rating?',
      'options': ['Doctor\'s expertise', 'Wait time', 'Communication', 'Facility quality'],
      'response': '_mainReason',
    },
  ];

  // Validates if all questions have been answered
  bool _validateForm() {
    return _clinicRating != null &&
        _staffHelpfulness != null &&
        _doctorCourtesy != null &&
        _explanationClarity != null &&
        _waitTimeRating != null &&
        _appointmentEase != null &&
        _chooseAgain != null &&
        _mainReason != null;
  }
  
  // Submit survey to Firestore
  Future<void> _submitSurvey() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please answer all questions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50), // Green background
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.login_outlined,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You must be logged in to submit a survey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50), // Green background
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Reports').add({
        'patientId': currentUser.uid,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'clinicRating': _clinicRating,
        'staffHelpfulness': _staffHelpfulness,
        'doctorCourtesy': _doctorCourtesy,
        'explanationClarity': _explanationClarity,
        'waitTimeRating': _waitTimeRating,
        'appointmentEase': _appointmentEase,
        'chooseAgain': _chooseAgain,
        'mainReason': _mainReason,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Return true to indicate successful submission
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error submitting survey: $e',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50), // Green background
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(
      backgroundColor: Color(0xFFF0F8FF), // Light blue background
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Rate Doctor',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting your feedback...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor info card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF0F8FF),
                              Color(0xFFE6F3FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF3B82F6).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF1E3A8A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF3B82F6).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.transparent,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.doctorName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFD700),
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Please rate your experience',
                                        style: TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Survey questions
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    
                    // Determine which response variable should be updated
                    String responseVar = question['response'];
                    String? currentResponse;
                    
                    // Get the current response value based on the response variable
                    switch(responseVar) {
                      case '_clinicRating': currentResponse = _clinicRating; break;
                      case '_staffHelpfulness': currentResponse = _staffHelpfulness; break;
                      case '_doctorCourtesy': currentResponse = _doctorCourtesy; break;
                      case '_explanationClarity': currentResponse = _explanationClarity; break;
                      case '_waitTimeRating': currentResponse = _waitTimeRating; break;
                      case '_appointmentEase': currentResponse = _appointmentEase; break;
                      case '_chooseAgain': currentResponse = _chooseAgain; break;
                      case '_mainReason': currentResponse = _mainReason; break;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF1E3A8A),
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question['question'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              question['options'].length,
                              (optionIndex) {
                                final option = question['options'][optionIndex];
                                return RadioListTile<String>(
                                  title: Text(option),
                                  value: option,
                                  groupValue: currentResponse,
                                  activeColor: Color(0xFFFFD700),
                                  selectedTileColor: Color(0xFFFFD700).withValues(alpha: 0.1),
                                  onChanged: (value) {
                                    setState(() {
                                      // Update the appropriate response variable
                                      switch(responseVar) {
                                        case '_clinicRating': _clinicRating = value; break;
                                        case '_staffHelpfulness': _staffHelpfulness = value; break;
                                        case '_doctorCourtesy': _doctorCourtesy = value; break;
                                        case '_explanationClarity': _explanationClarity = value; break;
                                        case '_waitTimeRating': _waitTimeRating = value; break;
                                        case '_appointmentEase': _appointmentEase = value; break;
                                        case '_chooseAgain': _chooseAgain = value; break;
                                        case '_mainReason': _mainReason = value; break;
                                      }
                                    });
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  dense: true,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 20),
                  
                  // Submit button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1E3A8A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF3B82F6).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submitSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Submit Rating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}