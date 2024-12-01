import 'package:cloud_firestore/cloud_firestore.dart';

//For storing all methods involving searching classes
class ClassSearch {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /*
    Takes an email. Returns a list of Document IDS for classes
    that are created with the specified email
  */
  Future<List<String>> getClassDocumentIdsByEmail(String? email) async {
    List<String> documentIds = [];

    try {
      // Query the 'classes' collection for documents with the matching email
      QuerySnapshot snapshot = await _firestore
          .collection('classes')
          .where('userEmail', isEqualTo: email)
          .get();

      // Collect the document IDs from the query results
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        documentIds.add(doc.id);
      }
    } catch (e) {
      //Error fecting classes
    }

    return documentIds;
  }

  // Helper method to get enrolled class IDs by student email
  Future<List<String>> getEnrolledClassIds(String email) async {
    final enrolledClassIds = <String>[]; // List to store class document IDs

    try {
      // Get all class documents in the "classes" collection
      final classCollection =
          await FirebaseFirestore.instance.collection('classes').get();

      // Iterate through each class document
      for (var classDoc in classCollection.docs) {
        final classId = classDoc.id;

        // Check the "students" subcollection for a document matching the student's email
        final studentDocRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(email);

        final studentDocSnapshot = await studentDocRef.get();

        // If the document exists, the student is enrolled in the class
        if (studentDocSnapshot.exists) {
          enrolledClassIds.add(classId);
        }
      }
    } catch (e) {
      print('Error fetching enrolled classes: $e');
    }

    return enrolledClassIds;
  }
}
