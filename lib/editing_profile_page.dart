import 'dart:io';

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
  late TextEditingController genderController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name']);
    genderController = TextEditingController(text: widget.userData['gender']);
    addressController = TextEditingController(text: widget.userData['address']);
    dobController = TextEditingController(text: widget.userData['dob']);
    phoneController = TextEditingController(text: widget.userData['phone']);
    emailController = TextEditingController(text: widget.userData['email']);
    _uploadedImageUrl = widget.userData['profileImage'];
  }

  Future<void> saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updatedData = {
      'name': nameController.text,
      'gender': genderController.text,
      'address': addressController.text,
      'dob': dobController.text,
      'phone': phoneController.text,
      'email': emailController.text,
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
      appBar: AppBar(
        title: Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 99, 181, 248),
                        const Color.fromARGB(255, 215, 229, 232)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : NetworkImage(_uploadedImageUrl ?? 'https://via.placeholder.com/150')
                                  as ImageProvider,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to change profile picture',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildEditableRow('Name', nameController),
            _buildEditableRow('Gender', genderController),
            _buildEditableRow('Address', addressController),
            _buildEditableRow('Date of Birth', dobController),
            _buildEditableRow('Phone', phoneController),
            _buildEditableRow('Email', emailController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
