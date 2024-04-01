import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Apis/googlemaps.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/profile/driverdetailsview.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';

class DriverDetails extends StatefulWidget {
  @override
  _DriverDetailsState createState() => _DriverDetailsState();
}

class _DriverDetailsState extends State<DriverDetails> {
  Utils utils = new Utils();
  FireStoreService fireStoreService=new FireStoreService();
  SharedPreferences sharedPreferences= new SharedPreferences();
  GoogleMaps googleMaps= new GoogleMaps();
  LoadingDialog loadingDialog = new LoadingDialog();
  bool _showSearchBar = false;
  TextEditingController _searchController = TextEditingController(); // Add controller
  List<String> _suggestedCompanies = [];
  String? companyName,uid;

  @override
  void initState(){
    // TODO: implement initState
    super.initState();
    getDetails();
  }

  Future<void> getDetails() async{
    companyName=await sharedPreferences.getSecurePrefsValue('COMPANY NAME') ?? '';
    uid=await utils.getCurrentUserUID();
    setState(() {}); // Trigger a rebuild after getting the uid
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar ? _buildSearchBar() : Text('Driver Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('USERDETAILS').doc(uid).collection('DRIVER').doc('DRIVERS').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            loadingDialog.showDefaultLoading('Getting Driver Details....');
          }
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          print('SnapShot: ${snapshot.data}');
          var data = snapshot.data?.data();
          print('Main Document Data: $data');
          if (data == null || !(data is Map<String, dynamic>)) {
            return Center(
              child: Text('No reference available'),
            );
          }

          DocumentReference mainDocumentRef = snapshot.data!.reference;

          return FutureBuilder<DocumentSnapshot>(
            future: mainDocumentRef.get(),
            builder: (context, mainSnapshot) {
              if (mainSnapshot.connectionState == ConnectionState.waiting) {

              }
              if (mainSnapshot.hasError) {
                print('Main Document Error: ${mainSnapshot.error}');
                return Center(
                  child: Text('Error: ${mainSnapshot.error}'),
                );
              }
              if (!mainSnapshot.hasData || mainSnapshot.data == null) {
                return Center(
                  child: Text('Document not found'),
                );
              }

              Map<String, dynamic>? mainDocumentData = mainSnapshot.data!.data() as Map<String, dynamic>?;
              print('Main Document Data: ${mainDocumentData.toString()}');

              // Initialize an empty list to store driver references
              List<DocumentReference> driverReferences = [];

              // Loop through all fields in mainDocumentData
              mainDocumentData?.forEach((key, value) {
                if (value is DocumentReference) {
                  driverReferences.add(value);
                }
              });

              print('Driver References: $driverReferences');

              if (driverReferences.isEmpty) {
                return Center(
                  child: Text('No driver details found'),
                );
              }

              // Build widgets for each driver
              return ListView.builder(
                itemCount: driverReferences.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: driverReferences[index].get(),
                    builder: (context, driverSnapshot) {
                      if (driverSnapshot.connectionState == ConnectionState.waiting) {
                        return Center();
                      }
                      if (driverSnapshot.hasError) {
                        print('Driver Document Error: ${driverSnapshot.error}');
                        return Center(
                          child: Text('Error: ${driverSnapshot.error}'),
                        );
                      }
                      if (!driverSnapshot.hasData || driverSnapshot.data == null) {
                        return Center(
                          child: Text('Driver document not found'),
                        );
                      }

                      // Extract driver details
                      Map<String, dynamic>? driverData = driverSnapshot.data!.data() as Map<String, dynamic>?;
                      print('Driver Data: ${driverData.toString()}');
                      if (driverData == null) {
                        EasyLoading.dismiss();
                        return Center(
                          child: Text('No driver details available'),
                        );
                      }

                      String name = driverData['NAME'] ?? '';
                      String number = driverData['NUMBER'] ?? '';
                      print('Driver Name: $name, Number: $number');
                      EasyLoading.dismiss();

                      // Display driver details in a card
                      return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number: $number'),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DriverDetailsView(driverDetails: driverData),
                                ),
                              );
                            },
                          ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300, // Set the width of the search bar
      height: 50, // Set the height of the search bar
      child: TypeAheadField<Map<String, String>>(
        suggestionsCallback: (pattern) async {
          // Return suggestions based on the pattern
          return _fetchSuggestedCompanies(pattern);
        },
        itemBuilder: (context, Map<String, String> suggestion) {
          String name = suggestion['NAME']!;
          String number = suggestion['NUMBER']!;
          String location = suggestion['LOCATION']!;
          String uid = suggestion['UID']!;

          return ListTile(
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number: $number'),
                Text('Location: $location'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.handshake),
              onPressed: ()  {
                // Hide the keyboard
                SystemChannels.textInput.invokeMethod('TextInput.hide');

                // Handle button press for this suggestion
                DocumentReference requestRef = FirebaseFirestore.instance.doc('USERDETAILS/$uid/REQUESTS/PENDING');
                DocumentReference userRef = FirebaseFirestore.instance.doc('USERDETAILS/${utils.getCurrentUserUID()}');
                Map<String, dynamic> data = {companyName!: userRef};

                try {
                  fireStoreService.uploadMapDataToFirestore(data, requestRef);
                  print('RequestRef: $requestRef  UserRef: $userRef  Data: $data');

                  if (mounted) {
                    // Check if the widget is mounted before showing the toast message
                    utils.showToastMessage('Request sent to the driver', context);
                  }
                } catch (error) {
                  print('Error uploading data to Firestore: $error');
                  // Handle error if needed
                }
              },
            ),
          );
        },
        onSelected: (Map<String, String> suggestion) {
          print('Selected suggestion: $suggestion');
          setState(() {
            _searchController.text = suggestion['NAME']!;
          });
        },
        builder: (context, controller, focusNode) {
          _searchController = controller;
          return TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Driver Name',
            ),
          );
        },
      ),
    );
  }



  Future<List<Map<String, String>>> _fetchSuggestedCompanies(String pattern) async {
    print("Getting the Driver details...: $pattern");
    if (pattern.isEmpty) {
      return [];
    }
    List<Map<String, String>> suggestedCompanies = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('USERDETAILS').where('ROLE', isEqualTo: 'TRANSPORTER')
          .where('TRANSPORTER TYPE', isEqualTo: 'DRIVER').where('isWorking',isEqualTo: false).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {

        String? location = await googleMaps.getAddressFromCoordinates(doc['LOCATION']);

        // Remove the substring before the first comma
        if (location != null) {
          int commaIndex = location.indexOf(',');
          if (commaIndex != -1) {
            location = location.substring(commaIndex + 1).trim();
          }
        }

        Map<String, String> suggestion = {
          'NAME': doc['NAME'],
          'NUMBER': doc['NUMBER'],
          'LOCATION': location ?? '',
          'UID': doc['UID'],
        };

        print('Suggestion: $suggestion');

        if (suggestion['NAME']!.toLowerCase().startsWith(pattern.toLowerCase())) {
          suggestedCompanies.add(suggestion);
        }
      }
      print('DriverDetails: $suggestedCompanies');
      return suggestedCompanies;
    } catch (error) {
      print('Error fetching Driver Details: $error');
      return [];
    }
  }


  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller
    super.dispose();
  }
}
