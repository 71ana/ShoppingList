import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  List<Marker> _storeMarkers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied.');
        return;
      }

      //sa evit folosirea gps api
      //sa folosim partea de kotlin

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Obține locațiile magazinelor după ce locația utilizatorului a fost obținută
      _fetchStoreLocations(_currentPosition!);
    } catch (e) {
      _showError('Failed to fetch location: $e');
    }
  }

  Future<void> _fetchStoreLocations(LatLng position) async {
    final String overpassUrl =
        'https://overpass-api.de/api/interpreter?data=[out:json];node["shop"](around:2000,${position.latitude},${position.longitude});out;';

    try {
      final response = await http.get(Uri.parse(overpassUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];

        List<Marker> markers = elements.map((element) {
          final lat = element['lat'];
          final lon = element['lon'];
          final name = element['tags']?['name'] ?? 'Unnamed Store';

          return Marker(
            point: LatLng(lat, lon),
            width: 80,
            height: 80,
            builder: (context) => GestureDetector(
              onTap: () => _showStoreDetails(name),
              child: const Icon(Icons.location_on, color: Colors.red, size: 30),
            ),
          );
        }).toList();

        setState(() {
          _storeMarkers = markers;
        });
      } else {
        _showError('Failed to fetch store locations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to fetch store locations: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showStoreDetails(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Nearby Stores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 5.0,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          center: _currentPosition,
          zoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: [
            Marker(
              point: _currentPosition!,
              width: 80,
              height: 80,
              builder: (context) =>
              const Icon(Icons.my_location, color: Colors.blue, size: 30),
            ),
            ..._storeMarkers,
          ]),
        ],
      ),
    );
  }
}
