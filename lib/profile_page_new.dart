import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/editing_profile_page.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<Map<String, dynamic>> userDataFuture;

  @override
  void initState() {
    super.initState();
    userDataFuture = fetchUserData();
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user is logged in");

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: Color(0xFF1A1A1A)),
              onPressed: () {
                // Add settings functionality if needed
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "Error loading profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(color: Color(0xFF8E8E93)),
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
                  Icon(Icons.person_outline, color: Color(0xFF8E8E93), size: 48),
                  SizedBox(height: 16),
                  Text(
                    "No profile data found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF2F2F7),
                          border: Border.all(
                            color: Color(0xFFE5E5EA),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: userData['profileImage'] != null && userData['profileImage'].isNotEmpty
                              ? Image.network(
                                  userData['profileImage'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFF8E8E93),
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF8E8E93),
                                ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Name
                      Text(
                        userData['name'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      // Email
                      Text(
                        userData['email'] ?? 'No email provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Edit Profile Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(userData: userData),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                userDataFuture = fetchUserData();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Profile Information
                _buildInfoSection('Personal Information', [
                  _buildInfoItem('Full Name', userData['name'] ?? 'N/A', Icons.person_outline),
                  _buildInfoItem('Date of Birth', userData['dob'] ?? 'N/A', Icons.cake_outlined),
                  _buildInfoItem('Address', userData['address'] ?? 'N/A', Icons.location_on_outlined),
                ]),
                
                SizedBox(height: 16),
                
                _buildInfoSection('Contact Information', [
                  _buildInfoItem('Phone Number', userData['phone'] ?? 'N/A', Icons.phone_outlined),
                  _buildInfoItem('Email Address', userData['email'] ?? 'N/A', Icons.email_outlined),
                ]),
                
                SizedBox(height: 24),
                
                // Action Buttons
                _buildActionSection(),
                
                SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionItem('Privacy & Security', Icons.security_outlined, () {}),
          Divider(height: 1, color: Color(0xFFE5E5EA)),
          _buildActionItem('Help & Support', Icons.help_outline, () {}),
          Divider(height: 1, color: Color(0xFFE5E5EA)),
          _buildActionItem('About', Icons.info_outline, () {}),
          Divider(height: 1, color: Color(0xFFE5E5EA)),
          _buildActionItem('Logout', Icons.logout, () {
            _showLogoutDialog();
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive ? Color(0xFFFFEBEE) : Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Color(0xFF007AFF),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(0xFFAEAEB2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
