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
}
