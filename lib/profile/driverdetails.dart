import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/profile/driverdetailsview.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class DriverDetails extends StatefulWidget {
  @override
  _DriverDetailsState createState() => _DriverDetailsState();
}

class _DriverDetailsState extends State<DriverDetails> {
  Utils utils = new Utils();
  FireStoreService fireStoreService=new FireStoreService();
  SharedPreferences sharedPreferences= new SharedPreferences();
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
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          var data = snapshot.data!.data();
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
                return Center(
                  child: CircularProgressIndicator(),
                );
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
                        return Center(
                          child: CircularProgressIndicator(),
                        );
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
                        return Center(
                          child: Text('No driver details available'),
                        );
                      }

                      String name = driverData['NAME'] ?? '';
                      String number = driverData['NUMBER'] ?? '';
                      print('Driver Name: $name, Number: $number');

                      // Display driver details in a card
                      return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: $name'),
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
      child: TypeAheadField<String>(
        suggestionsCallback: (pattern) async {
          // Return suggestions based on the pattern
          return _fetchSuggestedCompanies(pattern);
        },
        itemBuilder: (context, String suggestion) {
          // Extracting name, number, and location from the suggestion
          List<String> suggestionDetails = suggestion.split(','); // Assuming suggestion format is "Name, Number, Location"
          String name = suggestionDetails[0];
          String number = suggestionDetails[1];
          String location = suggestionDetails[2];
          String uid = suggestionDetails[3];

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
              onPressed: () {
                // Handle button press for this suggestion
                DocumentReference requestRef=FirebaseFirestore.instance.doc('USERDETAILS/$uid/REQUESTS/PENDING');
                DocumentReference userRef=FirebaseFirestore.instance.doc('USERDETAILS/${utils.getCurrentUserUID()}');
                Map<String,dynamic> data={companyName!:userRef};
                fireStoreService.uploadMapDataToFirestore(data, requestRef);
                print('Search button pressed for suggestion: $suggestion');
                utils.showToastMessage('Request sent to the driver', context);
              },
            ),
          );
        },
        onSelected: (String suggestion) {
          print('Selected suggestion: $suggestion');
          setState(() {
            _searchController.text = suggestion;
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


  Future<List<String>> _fetchSuggestedCompanies(String pattern) async {
    print("Getting the Driver details...: $pattern");
    if (pattern.isEmpty) {
      return [];
    }
    List<String> suggestedCompanies = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('USERDETAILS')
          .where('ROLE', isEqualTo: 'TRANSPORTER')
          .where('TRANSPORTER TYPE', isEqualTo: 'DRIVER')
          .get();

      querySnapshot.docs.forEach((doc) {
        // Extract the name, number, and location from each document
        String name = doc['NAME'];
        String number = doc['NUMBER'];
        String location = doc['LOCATION'];
        String uid=doc['UID'];

        // Format the suggestion string
        String suggestion = '$name, $number, $location,$uid';

        // Check if the suggestion matches the pattern
        if (suggestion.startsWith(pattern.toLowerCase())) {
          suggestedCompanies.add(suggestion);
        }
      });
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
