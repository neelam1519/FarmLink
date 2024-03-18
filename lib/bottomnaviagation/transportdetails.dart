import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;

class TransportDetails extends StatefulWidget {
  final Map<String, dynamic> transportData;

  TransportDetails({required this.transportData});

  @override
  _TransportDetailsState createState() => _TransportDetailsState();
}

class _TransportDetailsState extends State<TransportDetails> {
  final _formKey = GlobalKey<FormState>();
  final FireStoreService fireStoreService = FireStoreService();
  final LoadingDialog loadingDialog = LoadingDialog();
  final Utils utils = Utils();

  String _locationMessage = '';
  // TextEditingControllers for each input field
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverNumberController = TextEditingController();
  final TextEditingController startLocationController = TextEditingController();
  List<TextEditingController> dropLocationControllers = [];

  @override
  void initState() {
    super.initState();
    print('TRANSPORT DATA: ${widget.transportData.toString()}');
    if (widget.transportData.isNotEmpty) {
      vehicleNumberController.text = widget.transportData['VEHICLE NUMBER'] ?? '';
      vehicleModelController.text = widget.transportData['VEHICLE MODEL'] ?? '';
      weightController.text = widget.transportData['WEIGHT CAPACITY'] ?? '';
      driverNameController.text = widget.transportData['DRIVER NAME'] ?? '';
      driverNumberController.text = widget.transportData['DRIVER NUMBER'] ?? '';
      startLocationController.text = widget.transportData['START LOCATION'] ?? '';
      List<dynamic> dropLocations = widget.transportData['DROP LOCATIONS'];
      dropLocationControllers.addAll(dropLocations.map((location) => TextEditingController(text: location.toString())));
    } else {
      // Ensure at least one drop location controller is present
      dropLocationControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transport Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: vehicleNumberController,
                  decoration: InputDecoration(labelText: 'Vehicle Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the vehicle number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: vehicleModelController,
                  decoration: InputDecoration(labelText: 'Vehicle Model'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the vehicle model';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'Weight capacity'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the weight';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: driverNameController,
                  decoration: InputDecoration(labelText: 'Driver Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the driver\'s name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: driverNumberController,
                  decoration: InputDecoration(labelText: 'Driver Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the driver\'s number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: startLocationController,
                  decoration: InputDecoration(
                    labelText: 'Start Location',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.my_location),
                      onPressed: () async {
                        //print('Current Location: ${getCurrentLocation().toString()}');
                        _getLocation();
                        print('Current Location: ${_locationMessage}');

                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the start location';
                    }
                    return null;
                  },
                ),
                ...List.generate(dropLocationControllers.length, (index) =>
                    TextFormField(
                      controller: dropLocationControllers[index],
                      decoration: InputDecoration(labelText: 'Drop Location ${index + 1}'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter drop location ${index + 1}';
                        }
                        return null;
                      },
                    ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addAnotherDropLocation,
                  child: Text('Add Another Drop Location'),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      loadingDialog.showDefaultLoading('Uploading the Details...');
                      if (_formKey.currentState!.validate()) {
                        List<String> dropLocations = dropLocationControllers.map((controller) => controller.text).toList();
                        Map<String, dynamic> uploadData = {
                          'VEHICLE NUMBER': vehicleNumberController.text,
                          'VEHICLE MODEL': vehicleModelController.text,
                          'WEIGHT CAPACITY': weightController.text,
                          'DRIVER NAME': driverNameController.text,
                          'DRIVER NUMBER': driverNumberController.text,
                          'START LOCATION': startLocationController.text,
                          'DROP LOCATIONS': dropLocations,
                        };
                        DocumentReference docRef = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/VEHICLES/${vehicleNumberController.text}');
                        fireStoreService.uploadMapDataToFirestore(uploadData, docRef);
                        Navigator.pop(context);
                        utils.showToastMessage('Your Vehicle ${vehicleNumberController.text} added successfully', context);
                        EasyLoading.dismiss();
                      } else {
                        utils.showToastMessage('Error occurred while uploading the details retry after sometime', context);
                        EasyLoading.dismiss();
                      }
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    final String subscriptionKey = '4e6921a3-4a31-491d-9127-7fc01ca1628b';
    final String azureMapsUrl = 'https://atlas.microsoft.com/geolocation/ip/json?subscription-key=$subscriptionKey';

    try {
      final response = await http.get(Uri.parse(azureMapsUrl));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Decoded Response: $decodedResponse');

        final latitude = decodedResponse['location']['lat'];
        final longitude = decodedResponse['location']['lon'];

        setState(() {
          _locationMessage = 'Latitude: $latitude, Longitude: $longitude';
        });
      } else {
        setState(() {
          _locationMessage = 'Failed to get location: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _locationMessage = 'Error: $e';
      });
    }
  }

  void _addAnotherDropLocation() {
    setState(() {
      dropLocationControllers.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    vehicleNumberController.dispose();
    vehicleModelController.dispose();
    weightController.dispose();
    driverNameController.dispose();
    driverNumberController.dispose();
    startLocationController.dispose();
    dropLocationControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
