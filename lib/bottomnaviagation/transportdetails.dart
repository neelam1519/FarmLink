import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

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
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverNumberController = TextEditingController();
  late final TextEditingController startLocationController = TextEditingController();

  late GoogleMapsPlaces _places;

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
    }

    // Initialize _places with your Google Places API key
    _places = GoogleMapsPlaces(apiKey: 'AIzaSyA3ewNEKXzUC1IYVkhya9OqK5DPefBr5AI');
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
                      icon: Icon(Icons.my_location_outlined),
                      onPressed: _getCurrentLocation,
                    ),
                  ),
                  onTap: _onStartLocationTextFieldTapped,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the start location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      loadingDialog.showDefaultLoading('Uploading the Details...');
                      if (_formKey.currentState!.validate()) {
                        Map<String, dynamic> uploadData = {
                          'VEHICLE NUMBER': vehicleNumberController.text,
                          'VEHICLE MODEL': vehicleModelController.text,
                          'WEIGHT CAPACITY': weightController.text,
                          'DRIVER NAME': driverNameController.text,
                          'DRIVER NUMBER': driverNumberController.text,
                          'START LOCATION': startLocationController.text,
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

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission denied permanently';
        });
        return;
      } else if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = 'Location permission denied';
          });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Position: ${position.toString()}');
      final response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyA3ewNEKXzUC1IYVkhya9OqK5DPefBr5AI'));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse['status'] == 'OK') {
          final formattedAddress = decodedResponse['results'][0]['formatted_address'];
          setState(() {
            _locationMessage = formattedAddress;
            startLocationController.text = _locationMessage;
          });
        } else {
          setState(() {
            _locationMessage = 'Error: Unable to fetch location data';
          });
        }
      } else {
        setState(() {
          _locationMessage = 'Error: Unable to fetch location data';
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error: $e';
      });
    }
  }

  void _onStartLocationTextFieldTapped() async {
    print("Location Field on tapped");
    // Show Google Places autocomplete
    Prediction? prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: 'AIzaSyA3ewNEKXzUC1IYVkhya9OqK5DPefBr5AI',
      mode: Mode.overlay,
      language: "en",
    );
    print('Pridiction: ${prediction.toString()}');
    if (prediction != null) {
      // Retrieve details for the selected place
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(prediction.placeId!);
      print('Plces: ${detail.toString()}');
      if (detail.status == "OK") {
        setState(() {
          startLocationController.text = detail.result.formattedAddress!;
        });
      }
    }
  }
}
