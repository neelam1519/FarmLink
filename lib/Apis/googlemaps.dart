import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


class GoogleMaps {

  Future<Position?> getCurrentLocation() async {
    print('Getting current location');
    // Check if location permission is granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request location permission
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Permission not granted, return null
        print('Location permission not granted.');
        return null;
      }
    }try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<GeoPoint> convertAddressToGeoPoint(String address) async {
    try {
      String apiKey = 'AIzaSyA3ewNEKXzUC1IYVkhya9OqK5DPefBr5AI';
      String encodedAddress = Uri.encodeComponent(address);
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          var location = results[0]['geometry']['location'];
          double latitude = location['lat'];
          double longitude = location['lng'];
          return GeoPoint(latitude, longitude);
        } else {
          throw Exception('No results found for the provided address');
        }
      } else {
        throw Exception('Failed to convert address to GeoPoint');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


  Future<String?> getAddressFromCoordinates(GeoPoint geoPoint) async {
    try {
      // Retrieve the address using coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(geoPoint.latitude, geoPoint.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
        return address;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    // Calculate differences in latitude and longitude
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    // Haversine formula to calculate distance
    double a = pow(sin(deltaLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

}
