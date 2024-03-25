import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/bottomnaviagation/selling.dart';
import 'package:farmlink/bottomnaviagation/transport.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'bottomnaviagation/profile.dart';

class Home extends StatefulWidget {
  final bool isTransporter; // Define the boolean parameter
  Home({required this.isTransporter}); // Constructor to receive the boolean value

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Keep track of the selected index
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences=new SharedPreferences();
  Utils utils = new Utils();
  List<bool> itemVisibility = [true, true, true];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadingDialog.showDefaultLoading("Getting your details...");
    getUserDetails().then((userDetails) {
      // Update visibility based on user's role
      if (userDetails['ROLE'] == 'TRANSPORTER') {
        itemVisibility = [true, true, true];
      } else {
        itemVisibility = [false, true, true];
      }
      setState(() {});
    });  }

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
        return Profile(); // Replace with your Sells page
      case 2:
        return Profile(); // Replace with your Profile page
      default:
        return Profile(); // Default to Transport page if index is invalid
    }
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      // Get the document snapshot from Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}').get();

      // Check if the document exists and contains data
      if (snapshot.exists) {
        // Retrieve all fields and their values as a map
        Map<String, dynamic> userDetails = snapshot.data() as Map<String, dynamic>;
        sharedPreferences.storeMapValuesInSecureStorage(userDetails);
        // Print or use the retrieved map as needed
        print('User details: $userDetails');
        EasyLoading.dismiss();
        return userDetails;
      } else {
        print('Document does not exist or contains no data.');
        EasyLoading.dismiss();
        return {}; // Return an empty map if the document doesn't exist or contains no data
      }
    } catch (error) {
      print('Error fetching user details: $error');
      EasyLoading.dismiss();
      return {}; // Return an empty map in case of an error
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }
}
