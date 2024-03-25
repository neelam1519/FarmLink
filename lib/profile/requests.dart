import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:farmlink/profile/requestDetails.dart';

class Requests extends StatefulWidget {
  @override
  _RequestsState createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  Utils utils = new Utils();
  String? uid; // Make uid nullable

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  Future<void> getDetails() async {
    print('Getting Details...');
    uid = await utils.getCurrentUserUID(); // Await the result
    print('UID detail: $uid');
    setState(() {}); // Trigger a rebuild after getting the uid
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Requests'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Requests'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('USERDETAILS').doc(uid).collection('REQUESTS').doc('PENDING').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            print('Snapshot: ${snapshot.toString()}');
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
          print('Data: $data');
          if (data == null || !(data is Map<String, dynamic>)) {
            return Center(
              child: Text('No reference available'),
            );
          }

          // Extract the references from the data
          List<DocumentReference> references = [];
          data.forEach((key, value) {
            if (value is DocumentReference) {
              references.add(value);
            }
          });

          return Column(
            children: [
              // Loop through the references and show data for each reference
              for (var reference in references)
                FutureBuilder<DocumentSnapshot>(
                  future: reference.get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Center(
                        child: Text('Document not found'),
                      );
                    }

                    // Get the document data and cast to the correct type
                    Map<String, dynamic>? requestData = snapshot.data!.data() as Map<String, dynamic>?; // Make requestData nullable
                    if (requestData == null) {
                      return Center(
                        child: Text('No request data available'),
                      );
                    }

                    // Split the reference path to get the UID
                    String referencePath = snapshot.data!.reference.path;
                    List<String> pathSegments = referencePath.split('/');
                    String uid = pathSegments.last;

                    // Add UID to the request data
                    requestData['UID'] = uid;

                    // Ensure that the required fields exist before accessing them
                    String companyName = requestData['COMPANY NAME'] ?? '';
                    String number = requestData['NUMBER'] ?? '';
                    String location = requestData['LOCATION'] ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(companyName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Number: $number'),
                            Text('Location: $location'),
                          ],
                        ),
                        onTap: () {
                          // Handle onTap event
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RequestDetails(requestData: requestData),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
