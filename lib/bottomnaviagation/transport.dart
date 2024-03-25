import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/bottomnaviagation/transportdetails.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class Transport extends StatefulWidget {
  @override
  _TransportState createState() => _TransportState();
}

class _TransportState extends State<Transport> {
  final FireStoreService fireStoreService = FireStoreService();
  final LoadingDialog loadingDialog = LoadingDialog();
  final Utils utils = Utils();

  List<Map<String, dynamic>> transportDataList = [];

  @override
  void initState() {
    super.initState();
    fetchTransportData();
  }

  Future<void> fetchTransportData() async {
    loadingDialog.showDefaultLoading('Getting the vehicle details..');
    print('Transport data fetching...');
    final ownerDetails = FirebaseFirestore.instance.doc('USERDETAILS/${utils.getCurrentUserUID()}');
    final ownerDocumentDetails = await fireStoreService.getDocumentDetails(ownerDetails);

    if (ownerDocumentDetails != null) {
      final vehicles = await fireStoreService.getDocumentNames(FirebaseFirestore.instance.collection('$ownerDetails/VECHILES'));
      print('VEHICLES: ${vehicles.toString()}');
      for (final vehicleId in vehicles) {
        final vehicleDetails = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/VEHICLES/$vehicleId');
        final vehicleDocumentDetails = await fireStoreService.getDocumentDetails(vehicleDetails);

        if (mounted) {
          if (vehicleDocumentDetails != null) {
            final mergedData = {...ownerDocumentDetails, ...vehicleDocumentDetails};
            print('MERGED DATA: ${mergedData.toString()}');
            transportDataList.add(mergedData);
            setState(() {});
          }
        }
      }
    }
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transport'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TransportDetails(transportData: {})),
              );
            },
          ),
        ],
      ),
      body: transportDataList.isNotEmpty
          ? ListView.builder(
        itemCount: transportDataList.length,
        itemBuilder: (context, index) {
          return TransportCard(transportData: transportDataList[index]);
        },
      )
          : Center(
        child: Text('No transport data found.'),
      ),
    );
  }
}

class TransportCard extends StatelessWidget {
  final Map<String, dynamic> transportData;

  TransportCard({required this.transportData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransportDetails(transportData: transportData)),
          );
        },
        child: ListTile(
          title: Text(transportData['COMPANY NAME'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle Number: ${transportData['VEHICLE NUMBER'] ?? ''}'),
              Text('Load capacity: ${transportData['WEIGHT CAPACITY'] ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: Transport()));
}
