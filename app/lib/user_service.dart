import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  String? role;
  String? email;
  String? name;

  Future<void> fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      role = userDoc['role'];
      email = userDoc['email'];
      name = userDoc['name'];
    } catch (e) {
      print("Error fetching user data: $e");
      // Handle error appropriately
    }
  }

  void clearUserData() {
    role = null;
    email = null;
    name = null;
  }
}
