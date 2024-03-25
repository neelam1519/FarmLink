import 'package:farmlink/profile/vehicledetails.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicles extends StatefulWidget {
  @override
  _VehiclesState createState() => _VehiclesState();
}

class _VehiclesState extends State<Vehicles> {
  Utils utils = new Utils();
  late String uid;

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  Future<void> getDetails() async {
    uid = await utils.getCurrentUserUID(); // Await the result
    setState(() {}); // Trigger a rebuild after getting the uid
  }

  @override
  Widget build(BuildContext context) {
    getDetails();
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicles'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VehicleDetails(vehicle: {},),
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
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          List<Map<String, dynamic>> vehicleMaps = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            itemCount: vehicleMaps.length,
            itemBuilder: (context, index) {
              var vehicle = vehicleMaps[index];
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
