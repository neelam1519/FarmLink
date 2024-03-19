import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/Home.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart'; // Import flutter_typeahead package

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
  final TextEditingController _companyNameController = TextEditingController(); // Add companyNameController

  String _selectedRole = 'Farmer'; // Default role
  List<String> _selectedTransporterTypes = [];
  String _selectedCompany = '';

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
              Text(
                'Username',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your username',
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                style: TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  } else if (value.length < 3) {
                    return 'Username must be at least 3 characters long.';
                  }
                  return null;
                },
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
                items: ['Farmer', 'Transporter', 'Dealer']
                    .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                    .toList(),
              ),
              if (_selectedRole == 'Transporter')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Select transporter type(s):',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text('Driver'),
                      value: _selectedTransporterTypes.contains('Driver'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _selectedTransporterTypes.add('Driver');
                          } else {
                            _selectedTransporterTypes.remove('Driver');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text('Owner'),
                      value: _selectedTransporterTypes.contains('Owner'),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _selectedTransporterTypes.add('Owner');
                          } else {
                            _selectedTransporterTypes.remove('Owner');
                          }
                        });
                      },
                    ),
                    if (_selectedTransporterTypes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            'Company Name:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TypeAheadField<String>(
                            suggestionsCallback: (pattern) async {
                              return await _fetchSuggestedCompanies(pattern);
                            },
                            itemBuilder: (context, String suggestion) {

                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSelected: (String suggestion) {
                              print('onSelected1 :$suggestion');
                              setState(() {
                                _selectedCompany = suggestion;
                                print('selectedCompany :$_selectedCompany');
                                _companyNameController.text = suggestion;
                              });
                            },
                            builder: (context, TextEditingController controller, FocusNode focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                autofocus: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Company Name',
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Name:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your name',
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Number:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _numberController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your number',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      loadingDialog.showDefaultLoading('Uploading the data....');
                      print("Form is valid. Submitting data...");
                      Map<String, dynamic> uploadData = {
                        'USERNAME': _usernameController.text,
                        'ROLE': _selectedRole,
                      };
                      if (_selectedRole == 'Transporter' && _selectedTransporterTypes.isNotEmpty) {
                        uploadData['TRANSPORTER_TYPE'] = _selectedTransporterTypes.join(', ');
                        uploadData.addAll({
                          'COMPANY_NAME': _selectedCompany,
                          'NAME': _nameController.text,
                          'NUMBER': _numberController.text,
                        });
                      }
                      DocumentReference documentref = FirebaseFirestore.instance.doc(
                          '/USERDETAILS/${utils.getCurrentUserUID()}');
                      firestoreService.uploadMapDataToFirestore(uploadData, documentref);

                      sharedPreferences.storeMapValuesInSecureStorage(uploadData);
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

  Future<List<String>> _fetchSuggestedCompanies(String pattern) async {
    print("Getting the company names...: $pattern");
    if (pattern.isEmpty) {
      return [];
    }

    List<String> suggestedCompanies = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('USERDETAILS')
          .where('COMPANY_NAME', isGreaterThanOrEqualTo: pattern)
          .where('COMPANY_NAME', isLessThan: pattern + 'z') // Assumes 'z' is the maximum character
          .get();

      querySnapshot.docs.forEach((doc) {
        // Extract the company name from each document and add it to the list
        suggestedCompanies.add(doc['COMPANY_NAME']);
      });
      print('suggestedCompanies: $suggestedCompanies');
      return suggestedCompanies;
    } catch (error) {
      print('Error fetching suggested companies: $error');
      return [];
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}
