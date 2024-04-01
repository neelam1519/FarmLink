import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Apis/googlemaps.dart';
import 'package:farmlink/bottomnaviagation/profile.dart';
import 'package:farmlink/bottomnaviagation/selling.dart';
import 'package:farmlink/bottomnaviagation/transport.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class Home extends StatefulWidget {
  final bool isTransporter;

  Home({required this.isTransporter});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  LoadingDialog loadingDialog = LoadingDialog();
  SharedPreferences sharedPreferences = SharedPreferences();
  Utils utils = Utils();
  GoogleMaps googleMaps = GoogleMaps();
  List<bool> itemVisibility = [true, true, true];

  @override
  void initState() {
    super.initState();
    print('HOME');
    loadingDialog.showDefaultLoading("Getting details...");
    getUserDetails().then((userDetails) {
      if (userDetails['ROLE'] == 'TRANSPORTER') {
        itemVisibility = [true, true, true];
      } else if (userDetails["ROLE"] == 'FARMER') {
        itemVisibility = [false, true, true];
      } else {
        itemVisibility = [false, true, true];
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      if (itemVisibility[0]) Transport(),
      if (itemVisibility[1]) FarmSell(),
      if (itemVisibility[2]) Profile(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          if (itemVisibility[0]) BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Transport'),
          if (itemVisibility[1]) BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Sells'),
          if (itemVisibility[2]) BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    String uid = await utils.getCurrentUserUID();
    print('UID: $uid');
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.doc('/USERDETAILS/$uid').get();
      if (snapshot.exists) {
        Map<String, dynamic> userDetails = snapshot.data() as Map<String, dynamic>;

        await Future.forEach(userDetails.entries, (MapEntry<String, dynamic> entry) async {
          if (entry.value is GeoPoint) {
            GeoPoint geoPoint = entry.value as GeoPoint;
            String? address = await googleMaps.getAddressFromCoordinates(geoPoint);
            userDetails[entry.key] = address;
          }
        });

        sharedPreferences.storeMapValuesInSecureStorage(userDetails);
        print('User details: $userDetails');
        EasyLoading.dismiss();
        return userDetails;
      } else {
        print('Document does not exist or contains no data.');
        EasyLoading.dismiss();
        return {};
      }
    } catch (error) {
      print('Error fetching user details: $error');
      EasyLoading.dismiss();
      return {};
    }
  }

  void _onItemTapped(int index) {
    print('Tapped Index: $index');
    setState(() {
      _selectedIndex = index;
    });
  }
}
