import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorRatingHelper {
  
  /// Calculate average rating based on user reports for a specific doctor
  static Future<Map<String, dynamic>> calculateDoctorRating(String doctorId) async {
    try {
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('Reports')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (reportsSnapshot.docs.isEmpty) {
        return {'rating': 'N/A', 'reviewCount': 0};
      }

      // Convert text ratings to numerical values
      Map<String, int> ratingMap = {
        'Very satisfied': 5,
        'Satisfied': 4,
        'Neutral': 3,
        'Dissatisfied': 2,
        'Very dissatisfied': 1,
        'Excellent': 5,
        'Good': 4,
        'Average': 3,
        'Poor': 2,
        'Very poor': 1,
        'Much better': 5,
        'Slightly better': 4,
        'About the same': 3,
        'Worse': 2,
        'Extremely helpful': 5,
        'Somewhat helpful': 4,
        'Unhelpful': 2,
        'Yes, very clearly': 5,
        'Somewhat clearly': 4,
        'Not clearly': 2,
        'Not at all': 1,
        'Very short': 5,
        'Acceptable': 4,
        'Long': 2,
        'Very long': 1,
        'Very easy': 5,
        'Easy': 4,
        'Difficult': 2,
        'Very difficult': 1,
      };

      double totalRating = 0;
      int ratingCount = 0;

      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        
        // Get all rating fields
        List<String> ratingFields = [
          'clinicRating',
          'staffHelpfulness', 
          'doctorCourtesy',
          'explanationClarity',
          'waitTimeRating',
          'appointmentEase'
        ];

        for (String field in ratingFields) {
          final ratingText = data[field] as String?;
          if (ratingText != null && ratingMap.containsKey(ratingText)) {
            totalRating += ratingMap[ratingText]!;
            ratingCount++;
          }
        }
      }

      if (ratingCount == 0) {
        return {'rating': 'N/A', 'reviewCount': 0};
      }

      double averageRating = totalRating / ratingCount;
      return {
        'rating': averageRating.toStringAsFixed(1),
        'reviewCount': reportsSnapshot.docs.length
      };

    } catch (e) {
      print('Error calculating rating: $e');
      return {'rating': 'N/A', 'reviewCount': 0};
    }
  }
  
  /// Get star color based on rating value
  static Color getRatingColor(String rating) {
    if (rating == 'N/A') return Colors.grey;
    
    double ratingValue = double.tryParse(rating) ?? 0;
    if (ratingValue >= 4.0) return Colors.green;
    if (ratingValue >= 3.0) return Colors.orange;
    return Colors.red;
  }
}
