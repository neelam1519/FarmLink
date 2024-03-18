import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:farmlink/main.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Firebase/firestore.dart';

class RegisterUserPage extends StatefulWidget {
  @override
  _RegisterUserPageState createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>(); // Add this line

  FireStoreService fireStoreService = new FireStoreService();
  FirebaseAuth auth = FirebaseAuth.instance;
  Utils utils=Utils();

  String _name = '';
  String _email = '';
  String _password = '';
  bool _isTransporter = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyApp()),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Register User'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Add this line
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    onChanged: (value) => _name = value,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 3) {
                        return 'Please enter at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                    onChanged: (value) => _email = value,
                    validator: (value) {
                      if (value == null || value.isEmpty || !EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: !_showPassword,
                    onChanged: (value) => _password = value,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 8) {
                        return 'Password must be at least 8 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ListTile(
                    title: Text('Are you a transporter?'),
                    trailing: Switch(
                      value: _isTransporter,
                      onChanged: (bool value) {
                        setState(() {
                          _isTransporter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // If the form is valid, display a Snackbar.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Processing Data')),
                          );
                          // Add your Firestore upload logic here

                          registerUserWithEmailPassword(_email, _password);
                        }
                      },
                      child: Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> registerUserWithEmailPassword(String email, String password) async {
    try {
      print('REGISTER USER STARTED');
      // Create a new user with email and password
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      print('UserCredentials: ${userCredential.toString()}');
      final User? user = userCredential.user;
      print('User: ${user.toString()}');
      if (user != null) {
        // Registration successful, proceed with updating Firestore data and navigating to the next screen
        print('Registration successful');
        // Update Firestore data with the UID
        Map<String, dynamic> data = {'NAME': _name, 'EMAIL': _email, 'isTransporter': _isTransporter, 'UID': user.uid};
        DocumentReference documentReference = FirebaseFirestore.instance.doc('USERSDETAILS/$_email');
        fireStoreService.uploadMapDataToFirestore(data, documentReference);
        // Navigate to the desired destination
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyApp()), // Update with your desired destination
        );
      }

    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuthException and display appropriate error messages
      if (e.code == 'email-already-in-use') {
        print('The email address is already in use by another account.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The email address is already in use by another account.')),
        );
        utils.showToastMessage('The email is already in use',context);
      } else {
        print('Error during registration: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during registration: ${e.message}')),
        );
      }
    } catch (e) {
      // Handle other exceptions
      print('An error occurred. Please try again later.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<List<String>> checkExistingAccount(String email) async {
    try {
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return signInMethods;
    } catch (e) {
      print("Error checking existing account: $e");
      return [];
    }
  }


}
