import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'user_service.dart';
import 'navigation.dart'; // Presuming this contains your navigation logic

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    UserService().clearUserData();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final email = userService.email ?? "No Email";
    final name = userService.name ?? "User's Name";

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person,
                        size: 40), // Placeholder for a user icon
                  ),
                  title: Text(name,
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text(email, style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  padding:
                  EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                ),
                child: Text('Logout', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
    );
  }
}
