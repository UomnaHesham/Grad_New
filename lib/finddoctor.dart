import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/SpecialistDoctorsPage.dart';
import 'package:grad/doctor_search_results.dart';


class FindDoctorsPage extends StatefulWidget {
  @override
  _FindDoctorsPageState createState() => _FindDoctorsPageState();
}

class _FindDoctorsPageState extends State<FindDoctorsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;
  final TextEditingController _searchController = TextEditingController();

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .get();

      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final fullName = (data['fullName'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        
        return fullName.contains(searchQuery) || name.contains(searchQuery);
      }).toList();

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to search results page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorSearchResultsPage(
            searchQuery: query,
            searchResults: filteredDocs,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching doctors: $e')),
      );
    }
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
                  'Find Doctors',
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
        leading: Container(
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
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            color: Colors.white,
            iconSize: 22,
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Section with floating effect
                        AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingAnimation.value),
                              child: Container(
                                padding: EdgeInsets.all(24),
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
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF3B82F6).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.search_rounded,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                      ).createShader(bounds),
                                      child: Text(
                                        'Find Your Doctor',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Search by name or browse categories',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 24),
                                    
                                    // Enhanced Search Bar
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.8),
                                            Colors.white.withOpacity(0.6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Color(0xFF3B82F6).withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF3B82F6).withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              decoration: InputDecoration(
                                                hintText: 'Search by doctor name...',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  color: Color(0xFF3B82F6),
                                                  size: 22,
                                                ),
                                                suffixIcon: _searchController.text.isNotEmpty
                                                    ? IconButton(
                                                        icon: Icon(
                                                          Icons.clear_rounded,
                                                          color: Colors.grey[500],
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          _searchController.clear();
                                                          setState(() {});
                                                        },
                                                      )
                                                    : null,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 16,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0xFF3B82F6).withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                HapticFeedback.mediumImpact();
                                                if (_searchController.text.trim().isNotEmpty) {
                                                  _performSearch(_searchController.text.trim());
                                                }
                                              },
                                              icon: Icon(
                                                Icons.search_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Categories Section
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 25,
                                offset: Offset(0, 10),
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
                                      Icons.category_rounded,
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
                                          'Specialties',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          'Choose by medical specialty',
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
                              SizedBox(height: 24),
                              
                              // Enhanced Categories Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.95,
                                children: [
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'General',
                                    Icons.medical_services_rounded,
                                    'General',
                                    [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Lungs Specialist',
                                    Icons.air_rounded,
                                    'Lungs Specialist',
                                    [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Cardio',
                                    Icons.favorite_rounded,
                                    'Cardio',
                                    [Color(0xFF2563EB), Color(0xFF93C5FD)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Dentist',
                                    Icons.medical_services_outlined,
                                    'Dentist',
                                    [Color(0xFF1E40AF), Color(0xFFDBEAFE)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Orthopedic',
                                    Icons.accessibility_rounded,
                                    'Orthopedic',
                                    [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Psychiatrist',
                                    Icons.psychology_rounded,
                                    'Psychiatrist',
                                    [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Cardiologist',
                                    Icons.favorite_border_rounded,
                                    'Cardiologist',
                                    [Color(0xFF2563EB), Color(0xFF93C5FD)],
                                  ),
                                  _buildEnhancedCategoryCard(
                                    context,
                                    'Surgeon',
                                    Icons.health_and_safety_rounded,
                                    'Surgeon',
                                    [Color(0xFF1E40AF), Color(0xFFDBEAFE)],
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
            ),
          );
        },
      ),
    );
  }

  // Enhanced Category Card Widget
  Widget _buildEnhancedCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    String specialization,
    List<Color> gradient,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SpecialistDoctorsPage(specialization: specialization),
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                  size: 28,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
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
}
