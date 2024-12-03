import 'package:app/ss_framework.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'study_sync_home_page.dart';
import 'user_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String name, email, password;

  String role = 'Student';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential user = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _firestore.collection('users').doc(user.user!.uid).set({
          'name': name,
          'email': email,
          'role': role,
        });

        await UserService().fetchUserData(user.user!.uid);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SsFramework()),
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                validator: (input) => input!.isEmpty ? 'Enter Name' : null,
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (input) => name = input!,
              ),
              TextFormField(
                validator: (input) => input!.isEmpty ? 'Enter Email' : null,
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (input) => email = input!,
              ),
              TextFormField(
                validator: (input) =>
                    input!.length < 6 ? 'Provide Minimum 6 Characters' : null,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (input) => password = input!,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      onPressed: () {
                        setState(() {
                          role = 'Student';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            role == 'Student' ? Colors.blueGrey : null,
                      ),
                      child: Text('Student')),
                  SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        role = 'Teacher';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          role == 'Teacher' ? Colors.blueGrey : null,
                    ),
                    child: Text('Teacher'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
