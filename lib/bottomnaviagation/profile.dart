import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    // Using Scaffold for Material style design
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'), // Title of the page
      ),
      body: Center(
        child: Text('Welcome to your Profile'), // Content of the page
      ),
    );
  }
}
