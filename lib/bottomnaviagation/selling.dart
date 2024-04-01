import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Apis/googlemaps.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


class FarmSell extends StatefulWidget {
  @override
  _FarmSellState createState() => _FarmSellState();
}

class _FarmSellState extends State<FarmSell> {

  GoogleMaps googleMaps=new GoogleMaps();
  LoadingDialog loadingDialog= new LoadingDialog();
  FireStoreService fireStoreService = new FireStoreService();
  Utils utils = new Utils();

  TextEditingController weightController = TextEditingController();
  TextEditingController pickupLocationController = TextEditingController();
  String buttonText = '';
  String currentLocation = '';
  GeoPoint currentGeoPoint = GeoPoint(0, 0);
  late DateTime selectedDateTime;


  List<String> locationSuggestions = []; // List to hold location suggestions

  @override
  void initState() {
    super.initState();
    buttonText='Book a Transport';
    weightController = TextEditingController();
    pickupLocationController = TextEditingController();
    currentLocation = '';
    selectedDateTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm Sell'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight of the Product(Tons)',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextFormField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter weight',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the weight';
                }
                return null;
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Pickup Location',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TypeAheadField<String>(
              suggestionsCallback: (pattern) async {
                return await getPlaceRecommendations(pattern);
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSelected: (String suggestion) async {
                print('OnSelected: $suggestion');
                try {
                  currentGeoPoint = await googleMaps.convertAddressToGeoPoint(suggestion);
                  print('selectedLocation :$suggestion');
                  pickupLocationController.text = suggestion;
                  print("Current GeoPoint: ${currentGeoPoint.latitude},${currentGeoPoint.longitude}");
                } catch (e) {
                  print("Error converting address to GeoPoint: $e");
                  // Handle error here, maybe show a message to the user
                }
              },
              builder: (context, controller, FocusNode focusNode) {
                pickupLocationController = controller;
                return TextFormField(
                  controller: pickupLocationController,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter pickup location',
                    suffixIcon: GestureDetector(
                      onTap: () async {
                        Position? position = await googleMaps.getCurrentLocation();
                        currentGeoPoint = (position != null ? GeoPoint(position.latitude, position.longitude) : null)!;
                        currentLocation = (await googleMaps.getAddressFromCoordinates(currentGeoPoint))!;
                        pickupLocationController.text = currentLocation.toString();
                      },
                      child: Icon(Icons.location_on),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Type of Selling',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButtonFormField<String>(
              value: 'MARKET', // Set the initial value to 'MARKET'
              items: [
                DropdownMenuItem(
                  child: Text('Sell to high priced market'),
                  value: 'MARKET',
                ),
                DropdownMenuItem(
                  child: Text('Bid the crop'),
                  value: 'BID',
                ),
              ],
              onChanged: (value) {
                // Add your logic for handling dropdown selection here
                setState(() {
                  if (value == 'MARKET') {
                    buttonText = 'Book a Transport';
                  } else if (value == 'BID') {
                    buttonText = 'Send for Bidding'; // Changed from '==' to '='
                  }
                });
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Time of Crop Selling',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}'),
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          _selectDate(context);
                        },
                        child: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: '${selectedDateTime.hour}:${selectedDateTime.minute}'),
                    decoration: InputDecoration(
                      hintText: 'Select Time',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          _selectTime(context);
                        },
                        child: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add your logic here
                  if(buttonText=='Send for Bidding'){
                    sendToBid();
                  }else{
                    bookTransport();
                  }
                },
                child: Text(buttonText),
              ),
            ),
            // Location suggestions list
            SizedBox(height: 10.0), // Adding space between text field and suggestions
            Expanded(
              child: Container(
                child: ListView.builder(
                  itemCount: locationSuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(locationSuggestions[index]),
                      onTap: () async {
                        // Set the selected suggestion to the text field
                        pickupLocationController.text = locationSuggestions[index];
                        // Clear suggestions after selection
                        setState(() {
                          locationSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> bookTransport() async{
    loadingDialog.showDefaultLoading('Booking Transport');
    print('Clicked to Book Transport');
    print('Geo Point: ${currentGeoPoint.latitude},${currentGeoPoint.longitude}');

    try{

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('USERDETAILS')
          .where('ROLE', isEqualTo: 'TRANSPORTER')
          .where('TRANSPORTER TYPE', whereIn: ['DRIVER', 'BOTH'])
          .where('isWorking', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .get();

      List<String> isTransporting = [];
      List<String> isNotTransporting = [];

      querySnapshot.docs.forEach((doc) {
        String name = doc['UID'];

        // Assuming the field is named 'isTransportation', change it accordingly if different
        bool transportationStatus = doc['isTransporting'];

        if (transportationStatus) {
          isTransporting.add(name);
        } else {
          isNotTransporting.add(name);
        }
      });
      print('Transporting: $isTransporting');
      print('Not Transporting: $isNotTransporting');

      Map<String, dynamic> isNotTransportingDistances = {};

      double shortestDistance = double.infinity;
      String shortestDriver = '';

      if (isTransporting.isEmpty) {
        isNotTransporting.forEach((driver) async {
          DocumentSnapshot driverDetails = await FirebaseFirestore.instance.doc('USERDETAILS/$driver').get();
          Map<String, dynamic>? data = driverDetails.data() as Map<String, dynamic>?; // Explicit casting

          if (data != null) {
            GeoPoint driverGeoPoint = data['LOCATION'];
            double distance = googleMaps.calculateDistance(currentGeoPoint.latitude, currentGeoPoint.longitude, driverGeoPoint.latitude, driverGeoPoint.longitude);
            print("Distance: $distance");

            isNotTransportingDistances[driver] = distance;
          }
        });

        isNotTransportingDistances.forEach((driver, distance) {
          if (distance < shortestDistance) {
            shortestDistance = distance;
            shortestDriver = driver;
          }
        });
      }

      EasyLoading.dismiss();
      loadingDialog.showSuccessMessage('Transportation Booked');
      EasyLoading.dismiss();
      utils.showToastMessage('Transport is Booked', context);

    }catch(e){

      loadingDialog.showErrorMessage('Unable to Book Transport');
      EasyLoading.dismiss();
      utils.showToastMessage('Error while Booking', context);
      print('Error fetching filtered Details: $e');

    }
  }
  
  Future<void> sendToBid() async{
    print('Clicked to send to Bidding');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != selectedDateTime) {
      setState(() {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: selectedDateTime.hour, minute: selectedDateTime.minute),
    );
    if (pickedTime != null) {
      setState(() {
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}


  Future<List<String>> getPlaceRecommendations(String pattern) async {
    String apiKey='AIzaSyA3ewNEKXzUC1IYVkhya9OqK5DPefBr5AI';
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$pattern&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List<dynamic>;

        List<String> recommendations = [];
        for (var prediction in predictions) {
          recommendations.add(prediction['description']);
        }

        return recommendations;
      } else {
        throw Exception('Failed to load place recommendations');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
}

