import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController addressController;

  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name']);
    phoneController = TextEditingController(text: widget.userData['phone']);
    emailController = TextEditingController(text: widget.userData['email']);
    dobController = TextEditingController(text: widget.userData['dob']);
    addressController = TextEditingController(text: widget.userData['address']);
    _uploadedImageUrl = widget.userData['profileImage'];
  }

  Future<void> saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updatedData = {
      'name': nameController.text,
      'phone': phoneController.text,
      'email': emailController.text,
      'dob': dobController.text,
      'address': addressController.text,
    };

    if (_uploadedImageUrl != null) {
      updatedData['profileImage'] = _uploadedImageUrl;
    }

    await _firestore.collection('users').doc(user.uid).update(updatedData);

    // Return updated data to ProfileScreen
    Navigator.pop(context, updatedData);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}.jpg');

    final uploadTask = storageRef.putFile(_selectedImage!);

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      _uploadedImageUrl = downloadUrl;
    });
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
          'Edit Profile',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF2F2F7),
                        border: Border.all(
                          color: Color(0xFFE5E5EA),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                      ? Image.network(
                                          _uploadedImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF8E8E93),
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF8E8E93),
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(0xFF007AFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Personal Information
            _buildEditSection('Personal Information', [
              _buildEditField('Full Name', nameController, Icons.person_outline),
              _buildEditField('Date of Birth', dobController, Icons.cake_outlined, isDateField: true),
              _buildEditField('Address', addressController, Icons.location_on_outlined, maxLines: 3),
            ]),
            
            SizedBox(height: 16),
            
            // Contact Information
            _buildEditSection('Contact Information', [
              _buildEditField('Phone Number', phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              _buildEditField('Email Address', emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            ]),
            
            SizedBox(height: 32),
            
            // Save Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection(String title, List<Widget> fields) {
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
          ...fields,
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isDateField = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF007AFF),
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: isDateField
                ? GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF007AFF),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.text = "${picked.day}/${picked.month}/${picked.year}";
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Select date',
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: Color(0xFF007AFF),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      hintText: 'Enter $label',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
