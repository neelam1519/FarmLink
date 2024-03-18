import 'package:farmlink/bottomnaviagation/selling.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:flutter/material.dart';
import 'package:farmlink/main.dart'; // Assume these are your actual pages
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'bottomnaviagation/profile.dart';
import 'bottomnaviagation/transport.dart';

class Home extends StatefulWidget {
  final bool isTransporter; // Define the boolean parameter
  Home({required this.isTransporter}); // Constructor to receive the boolean value

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Keep track of the selected index
  LoadingDialog loadingDialog = new LoadingDialog();

  // Assuming initial visibility; adjust as needed
  List<bool> itemVisibility = [true, true, true];

  @override
  Widget build(BuildContext context) {
    // Filter items based on visibility and create them dynamically
    List<BottomNavigationBarItem> navBarItems = [
      if (itemVisibility[0]) BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Transport'),
      if (itemVisibility[1]) BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sells'),
      if (itemVisibility[2]) BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile')
    ];

    return Scaffold(
      body: _buildPage(_selectedIndex), // Add this line to show selected page content
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex, // Set initial index here
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to build the page corresponding to the selected index
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return Transport(); // Replace with your Transport page
      case 1:
        return FarmSell(); // Replace with your Sells page
      case 2:
        return Profile(); // Replace with your Profile page
      default:
        return Profile(); // Default to Transport page if index is invalid
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  void _signOut(BuildContext context) async {
    loadingDialog.showDefaultLoading('Loading...'); // Assuming you meant to use FlutterEasyLoading
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
      EasyLoading.dismiss();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
    } catch (e) {
      EasyLoading.dismiss();
      print("Error signing out: $e");
    }
  }
}
