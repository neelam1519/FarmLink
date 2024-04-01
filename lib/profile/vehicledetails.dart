import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/profile/vehicles.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';

class VehicleDetails extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  VehicleDetails({required this.vehicle});

  @override
  _VehicleDetailsState createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  FireStoreService fireStoreService = new FireStoreService();
  Utils utils = new Utils();

  TextEditingController _vehicleModelController = TextEditingController();
  TextEditingController _vehicleNumberController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _additionalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clearControllers();
    if (widget.vehicle.isNotEmpty) {
      _vehicleModelController.text = widget.vehicle['VEHICLE MODEL'];
      _vehicleNumberController.text = widget.vehicle['VEHICLE NUMBER'];
      _weightController.text = widget.vehicle['VEHICLE CAPACITY'];
      _additionalNotesController.text = widget.vehicle['ADDITIONAL NOTES'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _vehicleModelController,
              decoration: InputDecoration(
                labelText: 'Vehicle Model',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight Capacity (in tons)',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _additionalNotesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveVehicleDetails,
              child: Text(widget.vehicle.isNotEmpty ? 'Update Details' : 'Upload Vehicle Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearControllers() {
    _vehicleModelController.clear();
    _vehicleNumberController.clear();
    _weightController.clear();
    _additionalNotesController.clear();
  }

  Future<void> _saveVehicleDetails() async {
    String vehicleModel = _vehicleModelController.text;
    String vehicleNumber = _vehicleNumberController.text;
    String weight = _weightController.text;
    String additionalNotes = _additionalNotesController.text;

    Map<String, dynamic> data = {
      'VEHICLE MODEL': vehicleModel,
      'VEHICLE NUMBER': vehicleNumber,
      'VEHICLE CAPACITY': weight,
      'ADDITIONAL NOTES': additionalNotes,
    };
    DocumentReference vehicleRef = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/VEHICLES/${vehicleNumber}');
    await fireStoreService.uploadMapDataToFirestore(data, vehicleRef);
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Vehicles(),
      ),
    );
  }
}

