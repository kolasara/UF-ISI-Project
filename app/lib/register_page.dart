import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _name, _email, _password;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential user = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        await _firestore.collection('users').doc(user.user!.uid).set({
          'name': _name,
          'email': _email,
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user.user)),
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
                onSaved: (input) => _name = input!,
              ),
              TextFormField(
                validator: (input) => input!.isEmpty ? 'Enter Email' : null,
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (input) => _email = input!,
              ),
              TextFormField(
                validator: (input) =>
                    input!.length < 6 ? 'Provide Minimum 6 Characters' : null,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (input) => _password = input!,
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
