import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'doctor_survey.dart';

class MyDrugsPage extends StatefulWidget {
  const MyDrugsPage({Key? key}) : super(key: key);

  @override
  _MyDrugsPageState createState() => _MyDrugsPageState();
}

class _MyDrugsPageState extends State<MyDrugsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  // Cache for doctor names to avoid repetitive fetches
  Map<String, String> _doctorNameCache = {};
  
  // Selected doctor ID - null means we're on the doctor selection screen
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get month name from month number
  String _getMonthName(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  // Fetch doctor name from Firestore
  Future<String> _getDoctorName(String doctorId) async {
    // Check cache first
    if (_doctorNameCache.containsKey(doctorId)) {
      return _doctorNameCache[doctorId]!;
    }
    
    try {
      // Try the Doctors collection first
      final doctorsDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();
          
      if (doctorsDoc.exists) {
        final data = doctorsDoc.data();
        final name = data?['name'] ?? data?['fullName'] ?? data?['displayName'] ?? 'Unknown Doctor';
        final formattedName = !name.toLowerCase().startsWith('dr') ? 'Dr. $name' : name;
        _doctorNameCache[doctorId] = formattedName;
        return formattedName;
      }
      
      // Fallback
      final fallbackName = 'Dr. ' + doctorId.substring(0, doctorId.length > 8 ? 8 : doctorId.length);
      _doctorNameCache[doctorId] = fallbackName;
      return fallbackName;
    } catch (e) {
      final fallbackName = 'Dr. ' + doctorId.substring(0, doctorId.length > 8 ? 8 : doctorId.length);
      _doctorNameCache[doctorId] = fallbackName;
      return fallbackName;
    }
  }

  // Navigate to the doctor survey page
  void _navigateToSurvey(String doctorName, String doctorId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorSurveyPage(
          doctorName: doctorName,
          doctorId: doctorId,
        ),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thank you for your feedback!',
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
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF0F8FF),
        appBar: AppBar(
          title: Text('Login Required', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF3B82F6),
        ),
        body: Center(
          child: Text('Please log in to view your medications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0F8FF),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
                ).createShader(bounds),
                child: Text(
                  _selectedDoctorId == null 
                    ? 'My Medications'
                    : 'My Medications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B82F6), // Blue
                Color(0xFF1D4ED8), // Darker blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_selectedDoctorId != null) {
                setState(() {
                  _selectedDoctorId = null;
                });
              } else {
                Navigator.pop(context);
              }
            },
            color: Colors.white,
            iconSize: 20,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF0F8FF), // Alice blue
                      Color(0xFFFFFFFF), // White
                      Color(0xFFE6F3FF), // Very light blue
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _selectedDoctorId == null
                    ? _buildDoctorSelection(user)
                    : _buildMedicationsView(user),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorSelection(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Drugs')
          .where('patientId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_liquid_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('No medications found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        // Group medications by doctor
        Map<String, List<Map<String, dynamic>>> medicationsByDoctor = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final doctorId = data['doctorId'] ?? 'unknown';
          
          if (!medicationsByDoctor.containsKey(doctorId)) {
            medicationsByDoctor[doctorId] = [];
          }
          
          // Check if medications exist in the nested array format
          if (data['medications'] != null && data['medications'] is List) {
            final medicationsList = List<Map<String, dynamic>>.from(data['medications']);
            for (var medication in medicationsList) {
              medicationsByDoctor[doctorId]!.add({
                ...medication,
                'updatedAt': data['updatedAt'],
                'createdAt': data['createdAt'],
              });
            }
          }
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: medicationsByDoctor.keys.length,
          itemBuilder: (context, index) {
            final doctorId = medicationsByDoctor.keys.elementAt(index);
            final medications = medicationsByDoctor[doctorId]!;
            
            return _buildDoctorCard(doctorId, medications);
          },
        );
      },
    );
  }

  Widget _buildDoctorCard(String doctorId, List<Map<String, dynamic>> medications) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withValues(alpha: 0.12),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: Offset(-8, -8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedDoctorId = doctorId;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3B82F6).withValues(alpha: 0.2),
                        Color(0xFF1E3A8A).withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF3B82F6),
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getDoctorName(doctorId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Loading...',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.grey[800],
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 6),
                      
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3B82F6).withValues(alpha: 0.15),
                              Color(0xFF1E3A8A).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color(0xFF3B82F6).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${medications.length} medication${medications.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(12),                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationsView(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Drugs')
          .where('patientId', isEqualTo: user.uid)
          .where('doctorId', isEqualTo: _selectedDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final drugRecords = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
        
        return _buildMedicationsList(drugRecords);
      },
    );
  }

  Widget _buildMedicationsList(List<Map<String, dynamic>> drugRecords) {
    // Extract all medications from the nested structure
    List<Map<String, dynamic>> allMedications = [];
    
    for (var record in drugRecords) {
      if (record['medications'] != null && record['medications'] is List) {
        final medicationsList = List<Map<String, dynamic>>.from(record['medications']);
        // Add the parent record info to each medication
        for (var medication in medicationsList) {
          medication['updatedAt'] = record['updatedAt'];
          medication['createdAt'] = record['createdAt'];
          allMedications.add(medication);
        }
      }
    }
    
    if (allMedications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_liquid_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No medications found',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This doctor hasn\'t prescribed any medications yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Doctor Info and Rate Button
        Container(
          margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withValues(alpha: 0.15),
                blurRadius: 25,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 15,
                offset: Offset(-8, -8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Doctor Info
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6).withValues(alpha: 0.2),
                            Color(0xFF1E3A8A).withValues(alpha: 0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF3B82F6),
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: _getDoctorName(_selectedDoctorId!),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Colors.grey[800],
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your Prescribing Doctor',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Rate Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final doctorName = await _getDoctorName(_selectedDoctorId!);
                      _navigateToSurvey(doctorName, _selectedDoctorId!);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6), // Blue
                            Color(0xFF1E3A8A), // Darker blue
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD700), // Yellow star
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD700), // Yellow star
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD700), // Yellow star
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Rate This Doctor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Medications List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            physics: BouncingScrollPhysics(),
            itemCount: allMedications.length,
            itemBuilder: (context, index) {
              final medication = allMedications[index];
              final drugName = medication['name']?.toString() ?? 'Unnamed Medication';
              final dosage = medication['dose']?.toString() ?? '';
              final times = List<String>.from(medication['times'] ?? []);
              
              final Timestamp? updatedTimestamp = medication['updatedAt'] as Timestamp?;
              final String updatedAt = updatedTimestamp != null 
                  ? '${updatedTimestamp.toDate().day} ${_getMonthName(updatedTimestamp.toDate().month)} ${updatedTimestamp.toDate().year}'
                  : 'Date not available';

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withValues(alpha: 0.12),
                      blurRadius: 25,
                      offset: Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 15,
                      offset: Offset(-8, -8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF3B82F6).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.medication_liquid_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drugName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (dosage.isNotEmpty)
                                  Text(
                                    'Dose: $dosage',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (times.isNotEmpty)
                                  Text(
                                    '${times.length} time${times.length != 1 ? 's' : ''} daily',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                SizedBox(height: 4),
                                Text(
                                  'Updated: $updatedAt',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (times.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Scheduled Times:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: times.map((time) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  Color(0xFF1E3A8A).withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFF3B82F6).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
