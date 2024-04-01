import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/Firebase/firestore.dart';
import 'package:farmlink/utils/loadingdialog.dart';
import 'package:farmlink/utils/sharedpreferences.dart';
import 'package:farmlink/utils/utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class RequestDetails extends StatefulWidget {
  final Map<String, dynamic> requestData;
  RequestDetails({required this.requestData});
  @override
  _RequestDetailsState createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  Utils utils = new Utils();
  FireStoreService fireStoreService = new FireStoreService();
  SharedPreferences sharedPreferences = new SharedPreferences();
  LoadingDialog loadingDialog = new LoadingDialog();

  List<String> showDetails = ['COMPANY NAME', 'NAME', 'LOCATION', 'NUMBER'];
  String? name = '';

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  Future<void> getDetails() async {
    name = await sharedPreferences.getSecurePrefsValue('NAME');
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
                      Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        initialValue: '${widget.requestData[key]}',
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter $key',
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          hintStyle: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, size: 30, color: Colors.green),
                      onPressed: () {
                        loadingDialog.showDefaultLoading('Joining ${widget.requestData['COMPANY NAME']} company');
                        print('You Accepted the request');
                        DocumentReference companyRef = FirebaseFirestore.instance.doc('USERDETAILS/${widget.requestData['UID']}/DRIVER/DRIVERS');

                        DocumentReference userRef =
                        FirebaseFirestore.instance.doc('USERDETAILS/${utils.getCurrentUserUID()}');

                        Map<String, dynamic> userData = {'isWorking': true};
                        fireStoreService.uploadMapDataToFirestore(userData, userRef);

                        Map<String, dynamic> companyData = {name!: userRef};
                        fireStoreService.uploadMapDataToFirestore(companyData, companyRef);

                        DocumentReference declineRef =
                        FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/REQUESTS/PENDING');
                        List<String> deleteData = [widget.requestData['COMPANY NAME']];
                        fireStoreService.deleteFieldsFromDocument(declineRef, deleteData);

                        print('Accepted data: ${widget.requestData}');
                        Navigator.pop(context);
                        EasyLoading.dismiss();
                      },
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.close, size: 30, color: Colors.red),
                      onPressed: () {
                        loadingDialog.showDefaultLoading('Deleting the request');
                        DocumentReference declineRef =
                        FirebaseFirestore.instance.doc('/USERDETAILS/${utils.getCurrentUserUID()}/REQUESTS/PENDING');
                        List<String> deleteData = [widget.requestData['COMPANY NAME']];
                        fireStoreService.deleteFieldsFromDocument(declineRef, deleteData);
                        Navigator.pop(context);
                        EasyLoading.dismiss();
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
