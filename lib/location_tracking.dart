// ignore_for_file: prefer_const_constructors, prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemap/google_map_api.dart';
import 'package:location/location.dart';

class LocationTracking extends StatefulWidget {
  const LocationTracking({Key? key}) : super(key: key);

  @override
  _LocationTrackingState createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  LatLng sourceLocation = LatLng(12, 22.99);
  LatLng destinationLatlng = LatLng(32.78, 22.99);
  Completer<GoogleMapController> _controller = Completer();
  bool isloading = false;
  Set<Marker> _marker = Set<Marker>();
  Set<Polyline> _polyline = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  late StreamSubscription<LocationData> subscription;
  late LocationData currentLocation;
  late LocationData destinationLocation;
  late Location location;
  @override
  void initState() {
    super.initState();
    location = Location();
    polylinePoints = PolylinePoints();
    subscription = location.onLocationChanged.listen((LocationData cLoc) {
      currentLocation = cLoc;
      setInitialLocation();
     updatePinsOnMao();
    });
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
    destinationLocation = LocationData.fromMap({
      "latitude": destinationLatlng.latitude,
      "longitude": destinationLatlng.longitude
    });
  }

  void showLocationPins() {
    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);
    var destinationPosition = LatLng(destinationLocation.latitude ?? 0.0,
        destinationLocation.longitude ?? 0.0);
    _marker.add(Marker(
      markerId: MarkerId("sourcePosition"),
      position: sourcePosition,
    ));
    _marker.add(Marker(
      markerId: MarkerId("destinationPosition"),
      position: destinationPosition,
    ));
    setPolylinedMap();
  }

  void setPolylinedMap() async {
    var result = await polylinePoints.getRouteBetweenCoordinates(
        GoogleMapApi().url,
        PointLatLng(
            currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
        PointLatLng(destinationLocation.latitude ?? 0.0,
            destinationLocation.longitude ?? 0.0));
    if (result.points.isNotEmpty) {
      result.points.forEach((pointLatLng) {
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    setState(() {
      _polyline.add(Polyline(
          polylineId: PolylineId("polyline"),
          width: 4,
          points: polylineCoordinates,
          color: Colors.red));
    });
  }
  void updatePinsOnMao()async{
    CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
      zoom: 20,
      tilt: 80,
      bearing: 30
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(initialCameraPosition));
    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);
        setState(() {
        _marker.removeWhere((marker) => marker.markerId.value == 'sourcePosition');
        _marker.add(Marker(
          markerId: MarkerId("sourcePosition"),
          position: sourcePosition,
        
        ));
          
        });
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
      zoom: 20,
      tilt: 80,
      bearing: 30
    );
    return SafeArea(
      child: Scaffold(
        body: GoogleMap(
          markers: _marker,
          polylines: _polyline,
          mapType: MapType.normal,
          initialCameraPosition:initialCameraPosition,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            showLocationPins();
          },
        ),
      ),
    );
  }
}
