import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/Home.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginDetails extends StatefulWidget {
  @override
  _LoginDetailsState createState() => _LoginDetailsState();
}

class _LoginDetailsState extends State<LoginDetails> {
  final _formKey = GlobalKey<FormState>();
  FireStoreService firestoreService = new FireStoreService();
  Utils utils = new Utils();
  LoadingDialog loadingDialog = new LoadingDialog();
  SharedPreferences sharedPreferences = new SharedPreferences();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  String _selectedTransporterType = 'DRIVER';
  String _selectedRole = 'FARMER';
  String? companyNameError;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your username',
                ),
                style: TextStyle(fontSize: 14),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  } else if (value.length < 3) {
                    return 'Username must be at least 3 characters long.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your name',
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your number',
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Location',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on),
                    onPressed: () {
                      print('Location icon pressed');
                    },
                  ),
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'Select your role:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedRole,
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                items: ['FARMER', 'TRANSPORTER', 'DEALER']
                    .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                ).toList(),
              ),
              if (_selectedRole == 'TRANSPORTER') // Conditionally show the second dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Select transporter type:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedTransporterType,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTransporterType = newValue!;
                        });
                      },
                      items: ['DRIVER', 'OWNER', 'BOTH'] // Options for the second dropdown
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      ).toList(),
                    ),
                    if(_selectedTransporterType=='OWNER' || _selectedTransporterType=='BOTH')
                      TextFormField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter your company name',
                          errorText: companyNameError,
                        ),
                        style: TextStyle(fontSize: 14),
                        onChanged: (value) async {
                          // Check if the company name is already used
                          bool companyNameExists = await checkCompanyName(value);
                          setState(() {
                            companyNameError = companyNameExists ? 'Company name already exists' : null;
                          });
                        },
                      ),
                  ],
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String? email = await utils.getCurrentUserEmail();
                    email ??= ''; // If email is null, set it to an empty string

                    if (_formKey.currentState!.validate()) {
                      loadingDialog.showDefaultLoading('Uploading the data....');
                      print("Form is valid. Submitting data...");
                      Map<String, dynamic> uploadData = {
                        'USERNAME': _usernameController.text,
                        'ROLE': _selectedRole,
                        'NAME': _nameController.text,
                        'NUMBER': _numberController.text,
                        'LOCATION': _locationController.text,
                        'UID': utils.getCurrentUserUID(),
                        'EMAIL': email,
                      };
                      if (_selectedRole == 'TRANSPORTER') {
                        uploadData['TRANSPORTER TYPE'] = _selectedTransporterType;
                        if (_selectedTransporterType == 'OWNER' || _selectedTransporterType == 'BOTH') {
                          uploadData['COMPANY NAME'] = _companyNameController.text;
                        }
                      }
                      DocumentReference documentref = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}');
                      firestoreService.uploadMapDataToFirestore(uploadData, documentref);

                      sharedPreferences.storeMapValuesInSecureStorage(uploadData);
                      print("Updated Data: ${uploadData.toString()}");
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => Home(isTransporter: false),
                        ),
                      );
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
    );
  }

  Future<bool> checkCompanyName(String companyName) async {
    print('Checking company name...');
    CollectionReference collectionReference = FirebaseFirestore.instance.collection('USERDETAILS');
    List<String> documents = await firestoreService.getDocumentNames(collectionReference);

    for (String documentId in documents) {
      try {
        // Get the document snapshot
        DocumentSnapshot snapshot = await collectionReference.doc(documentId).get();

        // Check if the document exists
        if (snapshot.exists) {
          // Get the data map from the snapshot
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          // Check if the data map contains the field 'COMPANY NAME'
          if (data.containsKey('COMPANY NAME')) {
            // Get the value of the 'COMPANY NAME' field
            String companyNameValue = data['COMPANY NAME'];

            // Check if the companyNameValue matches the input companyName
            if (companyNameValue == companyName) {
              print('Company name found in document: $documentId');
              return true; // Company name found
            }
          }
        }
      } catch (e) {
        // Handle any errors that occur
        print('Error checking company name in document $documentId: $e');
      }
    }
    return false; // Company name not found
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
