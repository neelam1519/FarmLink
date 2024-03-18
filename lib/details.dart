import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/Home.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginDetails extends StatefulWidget {
  @override
  _LoginDetailsState createState() => _LoginDetailsState();
}

class _LoginDetailsState extends State<LoginDetails> {
  final _formKey = GlobalKey<FormState>(); // Add this line
  FireStoreService firestoreService=new FireStoreService();
  Utils utils=new Utils();
  LoadingDialog loadingDialog=new LoadingDialog();
  SharedPreferences sharedPreferences=new SharedPreferences();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController(); // Added for company name
  final TextEditingController _ownerNameController = TextEditingController(); // Added for owner name
  final TextEditingController _ownerNumberController = TextEditingController(); // Added for owner number

  bool _isTransporter = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Connect the Form widget with the GlobalKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Username',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your username',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  } else if (value.length < 3) {
                    return 'username must be at least 3 characters long.';
                  }
                  return null; // Return null if the input is valid
                },
              ),
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Are you a transporter?',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isTransporter,
                    onChanged: (bool value) {
                      setState(() {
                        _isTransporter = value;
                      });
                    },
                  ),
                ],
              ),
              Visibility( // Added for conditional rendering
                visible: _isTransporter, // Render the fields only if the transporter switch is on
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Company Name', // Added for company name
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your company name',
                      ),
                      validator: (value) {
                        if (_isTransporter && (value == null || value.isEmpty)) {
                          return 'Please enter your company name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Owner Name', // Added for owner name
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter owner name',
                      ),
                      validator: (value) {
                        if (_isTransporter && (value == null || value.isEmpty)) {
                          return 'Please enter the owner name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Owner Number', // Added for owner number
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _ownerNumberController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter owner number',
                      ),
                      validator: (value) {
                        if (_isTransporter && (value == null || value.isEmpty)) {
                          return 'Please enter the owner number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: (){
                    if (_formKey.currentState!.validate()) {
                      loadingDialog.showDefaultLoading('Uploading the data....');
                      // If the form is valid, proceed with your submit logic
                      print("Form is valid. Submitting data...");
                      print('IS TRANSPOTER: ${_isTransporter}');
                      Map<String,dynamic> uploadData={};
                      if(_isTransporter){
                        uploadData={'USERNAME': _nameController.text,'isTRANSPORTER': _isTransporter,'COMPANY NAME': _companyNameController.text,'NAME':_ownerNameController.text,'MOBILE NUMBER':_ownerNumberController.text};
                      }else{
                        uploadData={'USERNAME': _nameController.text,'isTRANSPORTER': _isTransporter};
                      }

                      DocumentReference documentref=FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}');
                      firestoreService.uploadMapDataToFirestore(uploadData, documentref);

                      sharedPreferences.storeMapValuesInSecureStorage(uploadData);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => Home(isTransporter: _isTransporter), // Pass the boolean value
                        ),
                      );
                      EasyLoading.dismiss();
                    }
                  }, // Trigger form validation
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose(); // Added for company name
    _ownerNameController.dispose(); // Added for owner name
    _ownerNumberController.dispose(); // Added for owner number
    super.dispose();
  }

}
