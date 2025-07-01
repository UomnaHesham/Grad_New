import 'package:flutter/material.dart';
import 'package:grad/startpage.dart';

class Opening extends StatefulWidget {
  @override
  _OpeningState createState() => _OpeningState();
}

class _OpeningState extends State<Opening> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
    Future.delayed(Duration(milliseconds: 600), () {
      _slideController.forward();
    });

    // Navigate to next screen after animations complete
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Startpage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF48CAE4),
              Color(0xFF023E8A),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating medical icons background
            Positioned(
              top: 80,
              left: 30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Icon(
                    Icons.favorite,
                    size: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 50,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.medical_services,
                    size: 35,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              left: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Icon(
                    Icons.healing,
                    size: 30,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: 30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Icon(
                    Icons.health_and_safety,
                    size: 45,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with pulse animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF8F9FA),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Color(0xFF6C63FF).withOpacity(0.4),
                                  blurRadius: 40,
                                  offset: Offset(0, -10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF48CAE4),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.local_hospital_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 50),
                  
                  // App name with typewriter effect
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, Color(0xFFE3F2FD)],
                        ).createShader(bounds),
                        child: Text(
                          "HealthCare+",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                offset: Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Animated subtitle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Smart Healthcare Solutions",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 80),
                  
                  // Custom loading animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _fadeController,
                              builder: (context, child) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                      0.3 + (0.7 * (((_fadeController.value + index * 0.3) % 1.0))),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
