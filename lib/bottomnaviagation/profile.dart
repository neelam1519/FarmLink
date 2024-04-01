import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/main.dart';
import 'package:farmlink/profile/driverdetails.dart';
import 'package:farmlink/profile/requests.dart';
import 'package:farmlink/profile/userdetails.dart';
import 'package:farmlink/profile/vehicles.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/utils.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Utils utils = Utils();
  final LoadingDialog loadingDialog = LoadingDialog();
  final FireStoreService fireStoreService = FireStoreService();
  final SharedPreferences sharedPreferences = SharedPreferences();

  String username = "FarmLink";
  String role = 'Farmer';
  String transporterType = 'OWNER';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getUserDetails();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: ListView(
        children: [
          Center(
            child: CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/images/FarmLink.png'),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              '$username',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text('Your Details'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetails(),
                ),
              );
            },
          ),
          if (role == 'TRANSPORTER' && transporterType == 'OWNER') ...[
            ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text('Driver Details'),
              onTap: () {
                // Add navigation logic here
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DriverDetails(),
                  ),
                );
              },
            ),
            ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text('Vehicles'),
              onTap: () {
                // Add navigation logic here
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Vehicles(),
                  ),
                );
              },
            ),
            ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text('Requests'),
              onTap: () {
                // Add navigation logic here
              },
            ),
          ] else if (role == 'TRANSPORTER' && transporterType == 'DRIVER') ...[
            ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text('Requests'),
              onTap: () {
                // Add navigation logic here
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Requests(),
                  ),
                );
              },
            ),
          ]else if (role == 'FARMER') ...[
            ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text('Crops'),
              onTap: () {
                // Add navigation logic here

              },
            ),
          ],
          ListTile(
            trailing: Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: Text(
              'Logout',
            ),
            onTap: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> getUserDetails() async {
    try {
      username = (await sharedPreferences.getSecurePrefsValue('USERNAME'))!;
      role = (await sharedPreferences.getSecurePrefsValue('ROLE'))!;
      transporterType = (await sharedPreferences.getSecurePrefsValue('TRANSPORTER TYPE'))!;

      setState(() {});
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  void _signOut(BuildContext context) async {
    loadingDialog.showDefaultLoading('Loading...');
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
