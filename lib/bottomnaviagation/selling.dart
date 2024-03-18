import 'package:flutter/material.dart';

class FarmSell extends StatefulWidget {
  @override
  _FarmSellState createState() => _FarmSellState();
}

class _FarmSellState extends State<FarmSell> {
  // Text editing controllers for weight and pickup location fields
  final TextEditingController weightController = TextEditingController();
  final TextEditingController pickupLocationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm Sell'), // Title of the page
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight of the Product', // Heading for weight field
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextFormField(
              controller: weightController,
              keyboardType: TextInputType.number, // Allowing only numeric input
              decoration: InputDecoration(
                hintText: 'Enter weight',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the weight';
                }
                return null;
              },
            ),
            SizedBox(height: 20.0), // Adding some space between fields
            Text(
              'Pickup Location', // Heading for pickup location field
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextFormField(
              controller: pickupLocationController,
              decoration: InputDecoration(
                hintText: 'Enter pickup location',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the pickup location';
                }
                return null;
              },
            ),
            SizedBox(height: 20.0), // Adding some space between fields
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle button press here
                  // You can access the entered values using weightController.text and pickupLocationController.text
                  // Implement your logic to find the transporter
                },
                child: Text('Book the Transporter'), // Button text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
