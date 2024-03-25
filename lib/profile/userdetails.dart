import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/bottomnaviagation/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../Firebase/firestore.dart';
import '../utils/loadingdialog.dart';
import '../utils/sharedpreferences.dart';
import '../utils/utils.dart';

class UserDetails extends StatefulWidget {
  @override
  _UserDetailsState createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
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
  String _selectedTransporterType = 'DRIVER'; // Default value
  String _selectedRole = 'FARMER'; // Default role
  bool _isEditMode = false; // Track whether user is in edit mode
  String? companyNameError;

  @override
  void initState() {
    super.initState();
    getDetails().then((value) => setState(() {}));
  }

  Future<void> getDetails() async {
    _selectedRole = (await sharedPreferences.getSecurePrefsValue('ROLE'))!;
    _selectedTransporterType = (await sharedPreferences.getSecurePrefsValue('TRANSPORTER TYPE'))!;
    _usernameController.text = (await sharedPreferences.getSecurePrefsValue('USERNAME'))!;
    _nameController.text = (await sharedPreferences.getSecurePrefsValue('NAME'))!;
    _numberController.text = (await sharedPreferences.getSecurePrefsValue('NUMBER'))!;
    _locationController.text = (await sharedPreferences.getSecurePrefsValue('LOCATION'))!;
    _companyNameController.text = (await sharedPreferences.getSecurePrefsValue('COMPANY NAME'))!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit), // Edit icon
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode; // Toggle edit mode
              });
            },
          ),
        ],
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
                enabled: _isEditMode, // Enable/disable based on edit mode
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
                enabled: _isEditMode, // Enable/disable based on edit mode
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your name',
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _numberController,
                enabled: _isEditMode, // Enable/disable based on edit mode
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your number',
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                enabled: _isEditMode, // Enable/disable based on edit mode
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
              SizedBox(height: 10),
              Text(
                'Select your role:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedRole,
                onChanged: _isEditMode // Enable/disable based on edit mode
                    ? (newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                }
                    : null,
                items: ['FARMER', 'TRANSPORTER', 'DEALER']
                    .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                    .toList(),
              ),
              if (_selectedRole == 'TRANSPORTER') // Conditionally show the second dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Select transporter type:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedTransporterType,
                      onChanged: _isEditMode // Enable/disable based on edit mode
                          ? (newValue) {
                        setState(() {
                          _selectedTransporterType = newValue!;
                        });
                      }
                          : null,
                      items: ['DRIVER', 'OWNER', 'BOTH'] // Options for the second dropdown
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      ).toList(),
                    ),
                    SizedBox(height: 10),
                    if(_selectedTransporterType=='OWNER' || _selectedTransporterType=='BOTH')
                      TextFormField(
                        controller: _companyNameController,
                        enabled: _isEditMode,
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
                  onPressed: _isEditMode
                      ? () async {
                    if (_formKey.currentState!.validate()) {
                      loadingDialog.showDefaultLoading('Uploading the data...');
                      print("Form is valid. Submitting data...");
                      Map<String, dynamic> uploadData = {
                        'USERNAME': _usernameController.text,
                        'ROLE': _selectedRole,
                        'NAME': _nameController.text,
                        'NUMBER': _numberController.text,
                        'LOCATION': _locationController.text,
                      };
                      if (_selectedRole == 'TRANSPORTER') {
                        uploadData['TRANSPORTER TYPE'] = _selectedTransporterType;
                      }
                      DocumentReference documentRef = FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}');
                      try {
                        await firestoreService.uploadMapDataToFirestore(uploadData, documentRef);
                        print('Updating Details: ${uploadData.toString()}');
                        await sharedPreferences.storeMapValuesInSecureStorage(uploadData);

                        Navigator.pop(context);
                        EasyLoading.dismiss();
                      } catch (e) {
                        print('Error uploading data: $e');
                        // Handle error
                        EasyLoading.dismiss();
                      }
                    }
                  } : null,
                  child: Text('Update'),
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
