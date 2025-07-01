import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/Doctordetails.dart';
import 'package:grad/doctor_rating_helper.dart';

class SpecialistDoctorsPage extends StatefulWidget {
  final String specialization;

  SpecialistDoctorsPage({required this.specialization});

  @override
  _SpecialistDoctorsPageState createState() => _SpecialistDoctorsPageState();
}

class _SpecialistDoctorsPageState extends State<SpecialistDoctorsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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

  // Function to fetch doctors from Firestore based on specialization
  Future<List<QueryDocumentSnapshot>> _fetchDoctors() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Doctors') // Firestore collection
        .where('Specialization', isEqualTo: widget.specialization) // Filter by specialization
        .get();

    return snapshot.docs; // Return all matching documents
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: [Colors.white, Colors.white.withOpacity(0.8)],
                ).createShader(bounds),
                child: Text(
                  '${widget.specialization} Specialists',
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
                Color(0xFF60A5FA), // Light blue
                Color(0xFF1E3A8A), // Deep blue in middle
                Color(0xFF93C5FD), // Very light blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
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
                child: FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: _fetchDoctors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Color(0xFF3B82F6).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Loading specialists...',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red[400],
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Error loading doctors',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                                Icons.medical_services_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No specialists found',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No doctors available for ${widget.specialization}',
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

                    List<QueryDocumentSnapshot> doctors = snapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.all(20),
                      physics: BouncingScrollPhysics(),
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> doctorData = doctors[index].data() as Map<String, dynamic>;
                        return _buildEnhancedDoctorCard(context, doctorData, doctors[index].id);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedDoctorCard(BuildContext context, Map<String, dynamic> doctorData, String doctorId) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withOpacity(0.12),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 15,
            offset: Offset(-8, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            // Doctor Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3B82F6).withOpacity(0.2),
                    Color(0xFF1E3A8A).withOpacity(0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[100],
                child: CircleAvatar(
                  radius: 27,
                  backgroundImage: NetworkImage(
                    doctorData['profileImage'] ?? 
                    'https://via.placeholder.com/150'
                  ),
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),
            SizedBox(width: 16),
            
            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorData['fullName'] ?? 'Dr. Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.grey[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  
                  // Specialty Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6).withOpacity(0.15),
                          Color(0xFF1E3A8A).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Color(0xFF3B82F6).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      doctorData['Specialization'] ?? widget.specialization,
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Rating
                  FutureBuilder<Map<String, dynamic>>(
                    future: DoctorRatingHelper.calculateDoctorRating(doctorId),
                    builder: (context, ratingSnapshot) {
                      if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }
                      
                      final ratingData = ratingSnapshot.data ?? {'rating': 'N/A', 'reviewCount': 0};
                      final rating = ratingData['rating'].toString();
                      final reviewCount = ratingData['reviewCount'] as int;
                      
                      return Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: DoctorRatingHelper.getRatingColor(rating),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            rating,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (reviewCount > 0) ...[
                            SizedBox(width: 4),
                            Text(
                              '($reviewCount)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // View Details Button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => DoctorDetailsPage(
                      doctorData: doctorData,
                      doctorId: doctorId,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
