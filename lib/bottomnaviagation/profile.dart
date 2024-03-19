import 'package:farmlink/main.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  LoadingDialog loadingDialog=new LoadingDialog();
  bool showYourDetails = true;
  bool showDriverDetails = true;
  bool showVehicles = true;
  bool showRequests = true;

  // Placeholder values for company name and username
  String companyName = "Company Name";
  String username = "John Doe";

  @override
  Widget build(BuildContext context) {
    // Using Scaffold for Material style design
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'), // Title of the page
      ),
      body: ListView(
        children: [
          // Profile image
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/profile_image.jpg'), // Replace with your profile image asset
            ),
          ),
          SizedBox(height: 20),
          // Company name
          Center(
            child: Text(
              companyName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          // Username
          Center(
            child: Text(
              'Username: $username',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          // Text and icons with visibility control
          Visibility(
            visible: showYourDetails, // Change visibility based on your logic
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios), // Icon
              title: Text('Your Details'), // Text
              onTap: () {
                // Add navigation logic here
              },
            ),
          ),
          Visibility(
            visible: showDriverDetails, // Change visibility based on your logic
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios), // Icon
              title: Text('Driver Details'), // Text
              onTap: () {
                // Add navigation logic here
              },
            ),
          ),
          Visibility(
            visible: showVehicles, // Change visibility based on your logic
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios), // Icon
              title: Text('Vehicles'), // Text
              onTap: () {
                // Add navigation logic here
              },
            ),
          ),
          Visibility(
            visible: showRequests, // Change visibility based on your logic
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios), // Icon
              title: Text('Requests'), // Text
              onTap: () {
                // Add navigation logic here
              },
            ),
          ),
          Visibility(
            visible: true, // Change visibility based on your logic
            child: ListTile(
              trailing: Icon(
                Icons.logout,
                color: Colors.red, // Set icon color to red
              ), // Icon
              title: Text('Logout',), // Text
              onTap: () {
                // Add navigation logic here
                _signOut(context);
              },
            ),
          ),
        ],
      ),
    );
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
