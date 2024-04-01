import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:farmlink/profile/vehicledetails.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/utils.dart';

class Vehicles extends StatefulWidget {
  @override
  _VehiclesState createState() => _VehiclesState();
}

class _VehiclesState extends State<Vehicles> {
  LoadingDialog loadingDialog = new LoadingDialog();
  Utils utils = new Utils();
  late String uid = '';
  List<Map<String, dynamic>> vehicleMaps = []; // Store all vehicle maps

  @override
  void initState() {
    super.initState();
    loadingDialog.showDefaultLoading('Getting Vehicle Details');
    getDetails(); // Fetch UID once when the widget initializes
  }

  Future<void> getDetails() async {
    // Fetch the UID
    uid = await utils.getCurrentUserUID();
    print('UID: $uid');
    setState(() {}); // Update the UI after getting the UID
  }

  @override
  Widget build(BuildContext context) {
    // Check if UID is empty, meaning it hasn't been fetched yet
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Vehicles'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Once UID is fetched, proceed with building the widget
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicles'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Implement logic for adding a new vehicle
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VehicleDetails(vehicle: {}),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('/USERDETAILS/$uid/VEHICLES').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
            );
          }
          if (snapshot.hasError) {
            EasyLoading.dismiss(); // Dismiss loading dialog when an error occurs
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // Dismiss loading dialog once vehicle details are fetched successfully
          EasyLoading.dismiss();

          vehicleMaps = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          if (vehicleMaps.isEmpty) {
            return Center(
              child: Text('No vehicles found.'),
            );
          }

          return ListView.builder(
            itemCount: vehicleMaps.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> vehicle = vehicleMaps[index];
              return Card(
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle Number: ${vehicle['VEHICLE NUMBER']}'),
                      SizedBox(height: 4), // Adjust as needed for spacing
                      Text('Model: ${vehicle['VEHICLE MODEL']}'),
                      SizedBox(height: 4), // Adjust as needed for spacing
                      Text('Capacity: ${vehicle['VEHICLE CAPACITY']} tons'),
                    ],
                  ),
                  onTap: () {
                    // Implement onTap logic here
                    // For example, navigate to a vehicle details screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VehicleDetails(vehicle: vehicle),
                      ),
                    );
                    print('Tapped on vehicle: ${vehicle['VEHICLE NUMBER']}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
