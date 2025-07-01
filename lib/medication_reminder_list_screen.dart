import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grad/setReminder.dart';

class MedicationReminderListScreen extends StatefulWidget {
  const MedicationReminderListScreen({Key? key}) : super(key: key);

  @override
  _MedicationReminderListScreenState createState() => _MedicationReminderListScreenState();
}

class _MedicationReminderListScreenState extends State<MedicationReminderListScreen> with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF0F8FF),
        appBar: _buildAppBar(),
        body: const Center(child: Text('Please log in to view your reminders')),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0F8FF),
      appBar: _buildAppBar(),
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
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 
                                 AppBar().preferredSize.height - 
                                 MediaQuery.of(context).padding.top,
                    ),
                    child: Column(
                      children: [
                        // Hero Section
                        _buildHeroSection(),
                        // Medications List
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('medications')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildLoadingState();
                            }

                            if (snapshot.hasError) {
                              return _buildErrorState(snapshot.error.toString());
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            return _buildMedicationsList(snapshot.data!.docs, user.uid);
                          },
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Build App Bar with beautiful gradient design
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: true,
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
                'My Medications',
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
    );
  }

  // Build Hero Section
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: AnimatedBuilder(
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
                        color: Color(0xFF3B82F6),
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
                        Icons.medical_services_rounded,
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
                        'Medication Reminders',
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
                      'Stay on track with your health. Never miss a dose with our smart reminder system.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.fade,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build Loading State
  Widget _buildLoadingState() {
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
            'Loading your medications...',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade50,
              Colors.red.shade100.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade600,
            ),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No Medications Yet',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start adding your medications to never miss a dose again',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            _buildAddMedicationButton(),
          ],
        ),
      ),
    );
  }

  // Build Add Medication Button
  Widget _buildAddMedicationButton() {
    return GestureDetector(
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Medication',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Medications List
  Widget _buildMedicationsList(List<QueryDocumentSnapshot> docs, String userUid) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(docs.length, (index) {
          try {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _buildMedicationCard(doc, data, userUid);
          } catch (e) {
            return _buildErrorCard();
          }
        }),
      ),
    );
  }

  // Build Individual Medication Card
  Widget _buildMedicationCard(QueryDocumentSnapshot doc, Map<String, dynamic> data, String userUid) {
    final medicineName = data['medicineName']?.toString() ?? 'Unnamed Medication';
    final dose = data['dose']?.toString() ?? 'No dose specified';
    final frequency = data['frequency']?.toString() ?? 'Not specified';
    final isActive = data['isActive'] as bool? ?? true;
    
    final reminderTimes = List<Map<String, dynamic>>.from(data['reminderTimes'] ?? []);
    String timeString = '';
    for (var time in reminderTimes) {
      final hour = time['hour'] as int? ?? 0;
      final minute = time['minute'] as int? ?? 0;
      timeString += '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, ';
    }
    if (timeString.isNotEmpty) {
      timeString = timeString.substring(0, timeString.length - 2);
    } else {
      timeString = 'No times set';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with medicine name and status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive 
                        ? [Color(0xFF1E3A8A), Color(0xFF3B82F6)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
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
                        medicineName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.grey[800] : Colors.grey[500],
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                            ? Color(0xFF10B981).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Color(0xFF10B981) : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userUid)
                        .collection('medications')
                        .doc(doc.id)
                        .update({'isActive': value});
                  },
                  activeColor: Color(0xFF10B981),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Medication details
            _buildDetailRow(Icons.local_pharmacy_rounded, 'Dose', dose),
            SizedBox(height: 12),
            _buildDetailRow(Icons.schedule_rounded, 'Frequency', frequency),
            SizedBox(height: 12),
            _buildDetailRow(Icons.access_time_rounded, 'Times', timeString),
            
            SizedBox(height: 20),
            
            // Action button
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to edit screen with existing data
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SetReminderScreen(
                            medicationId: doc.id,
                            existingData: data,
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
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showDeleteDialog(doc, userUid),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Detail Row
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // Build Error Card
  Widget _buildErrorCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error displaying medication',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'There was a problem with this reminder data',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show Delete Dialog
  void _showDeleteDialog(QueryDocumentSnapshot doc, String userUid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this medication reminder? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userUid)
                  .collection('medications')
                  .doc(doc.id)
                  .delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Build Floating Action Button
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              label: Text(
                'Add Medication',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              icon: Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}