import 'package:flutter/material.dart';
import 'package:grad/SpecialistDoctorsPage.dart';


class FindDoctorsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Find Doctors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Find a doctor',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildCategoryButton(context, 'General', Icons.medical_services, 'General'),
                  _buildCategoryButton(context, 'Lungs Specialist', Icons.air, 'Lungs Specialist'),
                  _buildCategoryButton(context, 'Cardio', Icons.favorite, 'Cardio'),
                  _buildCategoryButton(context, 'Dentist', Icons.medical_services, 'Dentist'),
                  _buildCategoryButton(context, 'Orthopedic', Icons.accessibility, 'Orthopedic'),
                  _buildCategoryButton(context, 'Psychiatrist', Icons.psychology, 'Psychiatrist'),
                  _buildCategoryButton(context, 'Cardiologist', Icons.favorite_border, 'Cardiologist'),
                  _buildCategoryButton(context, 'Surgeon', Icons.health_and_safety, 'Surgeon'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String title, IconData icon, String specialization) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shadowColor: Colors.grey[200],
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpecialistDoctorsPage(specialization: specialization),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
