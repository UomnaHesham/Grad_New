import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad/Doctordetails.dart';
import 'package:grad/doctor_rating_helper.dart';

class DoctorSearchResultsPage extends StatelessWidget {
  final String searchQuery;
  final List<QueryDocumentSnapshot> searchResults;

  const DoctorSearchResultsPage({
    Key? key,
    required this.searchQuery,
    required this.searchResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Results for "$searchQuery" (${searchResults.length} found)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No doctors found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try searching with a different name',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final docData = searchResults[index].data();
                      final doctorData = docData as Map<String, dynamic>? ?? {};
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              doctorData['profileImage'] ?? 'https://via.placeholder.com/150',
                            ),
                          ),
                          title: Text(
                            doctorData['fullName'] ?? 'Unknown Doctor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  doctorData['Specialization'] ?? 'General',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              FutureBuilder<Map<String, dynamic>>(
                                future: DoctorRatingHelper.calculateDoctorRating(searchResults[index].id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    );
                                  }
                                  
                                  final ratingData = snapshot.data ?? {'rating': 'N/A', 'reviewCount': 0};
                                  final rating = ratingData['rating'].toString();
                                  final reviewCount = ratingData['reviewCount'] as int;
                                  
                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.star, 
                                        color: DoctorRatingHelper.getRatingColor(rating), 
                                        size: 16
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        rating,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                      if (reviewCount > 0) ...[
                                        SizedBox(width: 4),
                                        Text(
                                          '($reviewCount)',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              if (doctorData['about'] != null && doctorData['about'].toString().isNotEmpty) ...[
                                SizedBox(height: 6),
                                Text(
                                  doctorData['about'].toString().length > 80 
                                      ? '${doctorData['about'].toString().substring(0, 80)}...'
                                      : doctorData['about'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorDetailsPage(
                                  doctorData: doctorData,
                                  doctorId: searchResults[index].id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
