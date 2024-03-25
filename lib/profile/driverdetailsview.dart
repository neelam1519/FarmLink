import 'package:flutter/material.dart';

class DriverDetailsView extends StatefulWidget {
  final Map<String, dynamic> driverDetails;

  DriverDetailsView({required this.driverDetails});

  @override
  _DriverDetailsViewState createState() => _DriverDetailsViewState();
}

class _DriverDetailsViewState extends State<DriverDetailsView> {
  late List<Widget> _textFields;

  @override
  void initState() {
    super.initState();
    _textFields = _buildTextFields();
  }

  List<Widget> _buildTextFields() {
    List<Widget> fields = [];
    widget.driverDetails.forEach((key, value) {
      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(labelText: key),
            controller: TextEditingController(text: value.toString()),
          ),
        ),
      );
    });
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _textFields,
          ),
        ),
      ),
    );
  }
}
