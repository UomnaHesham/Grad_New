import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grad/appoinment.dart';
import 'package:grad/chatbot.dart';
import 'package:grad/finddoctor.dart';
import 'package:grad/login.dart';
import 'package:grad/profile_page.dart';
import 'package:grad/setReminder.dart';
import 'package:grad/medication_reminder_list_screen.dart';
import 'package:grad/doctor_recommendations.dart';
import 'package:grad/Doctordetails.dart';
import 'package:grad/my_drugs_new_clean.dart';

class FeaturesPage extends StatefulWidget {
  @override
  _FeaturesPageState createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _recommendedDoctors = [];
  bool _loadingRecommendations = true;
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _floatingAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _floatingController.repeat(reverse: true);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations = await DoctorRecommendations.getRecommendedDoctors();
      setState(() {
        _recommendedDoctors = recommendations;
        _loadingRecommendations = false;
      });
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() {
        _loadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable back button
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF0F8FF),
        appBar: AppBar(
          automaticallyImplyLeading: false,
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
                    'HealthCare Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 90,
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
                BoxShadow(
                  color: Color(0xFF1E3A8A).withOpacity(0.2),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              // child: IconButton(
              //   icon: Icon(Icons.notifications_outlined),
              //   onPressed: () {
              //     HapticFeedback.lightImpact();
              //     // Add notification functionality
              //   },
              //   color: Colors.white,
              //   iconSize: 22,
              // ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.logout_outlined),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
                },
                color: Colors.white,
                iconSize: 22,
              ),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
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
                    child: Column(
                      children: [
                        // Enhanced Hero Section
                        Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: Column(
                              children: [
                                // Floating welcome card with glassmorphism effect
                                AnimatedBuilder(
                                  animation: _floatingAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatingAnimation.value),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.9),
                                              Colors.white.withOpacity(0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.4),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF3B82F6).withOpacity(0.15),
                                              blurRadius: 40,
                                              offset: Offset(0, 20),
                                              spreadRadius: 0,
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.8),
                                              blurRadius: 20,
                                              offset: Offset(-10, -10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF3B82F6), // Solid blue color
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFF3B82F6).withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.favorite_rounded,
                                                size: 36,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 24),
                                            ShaderMask(
                                              shaderCallback: (bounds) => LinearGradient(
                                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                              ).createShader(bounds),
                                              child: Text(
                                                'Your Health Journey',
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Discover premium healthcare services designed just for you. Your wellness is our priority.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                                height: 1.6,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 40),
                                
                                // Enhanced Features Grid
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.95,
                                  children: [
                                    _buildEnhancedFeatureCard(
                                      icon: Icons.search_rounded,
                                      title: 'Find a Doctor',
                                      subtitle: 'Search specialists nearby',
                                      gradient: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => FindDoctorsPage(),
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
                                    ),
                                    _buildEnhancedFeatureCard(
                                      icon: Icons.medical_services_rounded,
                                      title: 'Set Medication',
                                      subtitle: 'Smart reminders',
                                      gradient: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => MedicationReminderListScreen(),
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
                                    ),
                                    _buildEnhancedFeatureCard(
                                      icon: Icons.medication_liquid_rounded,
                                      title: 'My Drugs',
                                      subtitle: 'Prescribed medications',
                                      gradient: [Color(0xFF059669), Color(0xFF10B981)],
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => MyDrugsPage(),
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
                                    ),
                                    _buildEnhancedFeatureCard(
                                      icon: Icons.video_call_rounded,
                                      title: 'Talk to Doctor',
                                      subtitle: 'Instant consultation',
                                      gradient: [Color(0xFF2563EB), Color(0xFF93C5FD)],
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => SetReminderScreen(),
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
                                    ),
                                    _buildEnhancedFeatureCard(
                                      icon: Icons.psychology_rounded,
                                      title: 'AI Assistant',
                                      subtitle: 'Health chat bot',
                                      gradient: [Color(0xFF1E40AF), Color(0xFFDBEAFE)],
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => ChatBotPage(),
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                
                // Doctor Recommendations Section
                Container(
                  width: double.infinity,
                  color: Colors.grey[50],
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recommended Doctors',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          'Handpicked for you',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                height: 350,
                                child: _loadingRecommendations
                                    ? Center(
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
                                              'Finding the best doctors for you...',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _recommendedDoctors.isEmpty
                                        ? Center(
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
                                                  'No recommendations available',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Check back later for personalized suggestions',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            itemCount: _recommendedDoctors.length,
                                            itemBuilder: (context, index) {
                                              final doctor = _recommendedDoctors[index];
                                              return _buildDoctorCard(
                                                doctor['fullName'] ?? 'Unknown Doctor',
                                                doctor['Specialization'] ?? 'General',
                                                doctor['profileImage'] ?? 'https://via.placeholder.com/150',
                                                () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => DoctorDetailsPage(
                                                        doctorData: doctor,
                                                        doctorId: doctor['doctorId'] ?? '',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF3B82F6),
            unselectedItemColor: Colors.grey[400],
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home page
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FindDoctorsPage()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentsPage()),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  // Enhanced Feature Card Widget
  Widget _buildEnhancedFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: Offset(-8, -8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Doctor Card Widget
  Widget _buildEnhancedDoctorCard(String name, String specialty, String imageUrl, VoidCallback onTap) {
    return Container(
      width: 220,
      margin: EdgeInsets.only(right: 20),
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
        child: Column(
          children: [
            // Doctor Avatar with enhanced styling
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
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[100],
                child: CircleAvatar(
                  radius: 37,
                  backgroundImage: NetworkImage(imageUrl),
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Doctor Name
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10),
            
            // Specialty Badge with enhanced styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3B82F6).withOpacity(0.15),
                    Color(0xFF1E3A8A).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Color(0xFF3B82F6).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                specialty,
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16),
            
            // Enhanced Book Now Button
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Book Now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep the old methods for backward compatibility
  Widget _buildDoctorCard(String name, String specialty, [String? imageUrl, VoidCallback? onTap]) {
    return _buildEnhancedDoctorCard(
      name,
      specialty,
      imageUrl ?? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8KAdt1tNrDt3W7OJlCf22Diav_eipKctRuAN4MZgrsGE3EI2V1iJdtItHXcmc40glYGQ&usqp=CAU',
      onTap ?? () {},
    );
  }
}
