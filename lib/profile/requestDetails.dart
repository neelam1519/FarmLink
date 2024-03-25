import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';

class RequestDetails extends StatefulWidget {
  final Map<String, dynamic> requestData;
  RequestDetails({required this.requestData});
  @override
  _RequestDetailsState createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  Utils utils = new Utils();
  FireStoreService fireStoreService = new FireStoreService();
  SharedPreferences sharedPreferences=new SharedPreferences();

  List<String> showDetails = ['COMPANY NAME', 'NAME', 'LOCATION', 'NUMBER'];
  String? name='';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDetails();
  }

  Future<void> getDetails() async{
    name=await sharedPreferences.getSecurePrefsValue('NAME');
  }
  @override
  Widget build(BuildContext context) {
    print('DATA: ${widget.requestData.toString()}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...showDetails.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Decreased font size
                        ),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        initialValue: '${widget.requestData[key]}',
                        readOnly: true, // Set to true to prevent editing
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter $key',
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Adjust text field padding
                          hintStyle: TextStyle(
                            fontSize: 14, // Decreased font size
                          ),
                        ),
                        style: TextStyle(fontSize: 14), // Decreased font size
                      ),
                    ],
                  ),
                );
              }).toList(),
              // Add icons for accepting or declining
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, size: 30, color: Colors.green), // Accept icon
                      onPressed: () {
                        // Add your accept logic here
                        print('You Accepted the request');
                        DocumentReference companyRef=FirebaseFirestore.instance.doc('USERDETAILS/${widget.requestData['UID']}/DRIVER/$name');

                        DocumentReference userRef= FirebaseFirestore.instance.doc('USERDETAILS/${utils.getCurrentUserUID()}');

                        Map<String,dynamic> userData={'isWorking':true};
                        fireStoreService.uploadMapDataToFirestore(userData, userRef);

                        Map<String,dynamic> companyData={name!:userRef};
                        fireStoreService.uploadMapDataToFirestore(companyData, companyRef);

                        print('Accepted data: ${widget.requestData}');
                      },
                    ),
                    SizedBox(width: 20), // Add SizedBox for spacing
                    IconButton(
                      icon: Icon(Icons.close, size: 30, color: Colors.red), // Decline icon
                      onPressed: () {
                        // Add your decline logic here
                        DocumentReference declineRef = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/REQUESTS/PENDING');
                        // Field to delete is based on COMPANY NAME
                        List<String> deleteData=[widget.requestData['COMPANY NAME']];
                        fireStoreService.deleteFieldsFromDocument(declineRef, deleteData);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
