import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a survey')),
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
        SnackBar(content: Text('Error submitting survey: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Survey',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade700,
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.doctorName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Please rate your experience',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text('${index + 1}', 
                                    style: TextStyle(color: Colors.blue.shade700)),
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
                                  activeColor: Colors.blue.shade700,
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Survey',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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