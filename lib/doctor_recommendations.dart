import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorRecommendations {
  
  /// Get recommended doctors based on user's visit history
  static Future<List<Map<String, dynamic>>> getRecommendedDoctors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Get user's appointment history
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('Reservations')
          .where('patientId', isEqualTo: user.uid)
          .get();

      // Get unique doctor IDs from appointments
      Set<String> visitedDoctorIds = {};
      Map<String, int> doctorVisitCount = {};
      
      for (var appointment in appointmentsSnapshot.docs) {
        final doctorId = appointment.data()['doctorId'] as String?;
        if (doctorId != null) {
          visitedDoctorIds.add(doctorId);
          doctorVisitCount[doctorId] = (doctorVisitCount[doctorId] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> recommendations = [];

      if (visitedDoctorIds.isNotEmpty) {
        // Sort doctors by visit count
        var sortedDoctors = doctorVisitCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Get detailed information for the most visited doctors
        for (var entry in sortedDoctors.take(3)) {
          final doctorDoc = await FirebaseFirestore.instance
              .collection('Doctors')
              .doc(entry.key)
              .get();

          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            doctorData['doctorId'] = entry.key;
            doctorData['visitCount'] = entry.value;
            doctorData['recommendationReason'] = 'You\'ve visited this doctor ${entry.value} time(s)';
            recommendations.add(doctorData);
          }
        }

        // If we have visited doctors, also recommend doctors from the same specializations
        if (recommendations.isNotEmpty) {
          Set<String> visitedSpecializations = recommendations
              .map((doc) => doc['Specialization'] as String?)
              .where((spec) => spec != null)
              .cast<String>()
              .toSet();

          for (String specialization in visitedSpecializations.take(2)) {
            final similarDoctorsSnapshot = await FirebaseFirestore.instance
                .collection('Doctors')
                .where('Specialization', isEqualTo: specialization)
                .limit(2)
                .get();

            for (var doc in similarDoctorsSnapshot.docs) {
              if (!visitedDoctorIds.contains(doc.id) && 
                  !recommendations.any((r) => r['doctorId'] == doc.id)) {
                final doctorData = doc.data();
                doctorData['doctorId'] = doc.id;
                doctorData['visitCount'] = 0;
                doctorData['recommendationReason'] = 'Similar to doctors you\'ve visited ($specialization)';
                recommendations.add(doctorData);
                
                if (recommendations.length >= 6) break;
              }
            }
            if (recommendations.length >= 6) break;
          }
        }
      }

      // If no visit history or need more recommendations, add highly-rated doctors
      if (recommendations.length < 3) {
        final topDoctorsSnapshot = await FirebaseFirestore.instance
            .collection('Doctors')
            .orderBy('rating', descending: true)
            .limit(5)
            .get();

        for (var doc in topDoctorsSnapshot.docs) {
          if (!recommendations.any((r) => r['doctorId'] == doc.id)) {
            final doctorData = doc.data();
            doctorData['doctorId'] = doc.id;
            doctorData['visitCount'] = 0;
            doctorData['recommendationReason'] = 'Highly rated doctor';
            recommendations.add(doctorData);
            
            if (recommendations.length >= 6) break;
          }
        }
      }

      return recommendations.take(6).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get recently visited doctors
  static Future<List<Map<String, dynamic>>> getRecentlyVisitedDoctors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final recentAppointments = await FirebaseFirestore.instance
          .collection('Reservations')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> recentDoctors = [];
      Set<String> addedDoctorIds = {};

      for (var appointment in recentAppointments.docs) {
        final doctorId = appointment.data()['doctorId'] as String?;
        final appointmentDate = (appointment.data()['timestamp'] as Timestamp?)?.toDate();
        
        if (doctorId != null && !addedDoctorIds.contains(doctorId)) {
          final doctorDoc = await FirebaseFirestore.instance
              .collection('Doctors')
              .doc(doctorId)
              .get();

          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            doctorData['doctorId'] = doctorId;
            doctorData['lastVisit'] = appointmentDate;
            doctorData['recommendationReason'] = 'Recently visited';
            recentDoctors.add(doctorData);
            addedDoctorIds.add(doctorId);
          }
        }
      }

      return recentDoctors;
    } catch (e) {
      print('Error getting recently visited doctors: $e');
      return [];
    }
  }
}
