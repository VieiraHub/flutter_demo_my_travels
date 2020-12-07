import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class Mapa extends StatefulWidget {

  String idTravel;
  Mapa({ this.idTravel });

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  CameraPosition _cameraPosition =  CameraPosition(
      target: LatLng(-23.562436, -46.655005),
      zoom: 18 );

  Firestore _db = Firestore.instance;

  _onMapCreated(GoogleMapController controller ){
    _controller.complete(controller);
  }

  _addMarker(LatLng latLng) async {

    List<Placemark> addressList = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if (addressList != null && addressList.length > 0) {
      Placemark address = addressList[0];
      String street = address.thoroughfare;

      Marker marker = Marker(
          markerId: MarkerId("marker: ${latLng.latitude} - ${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow( title: street)
      );
      setState(() {
        _markers.add(marker);
        Map<String, dynamic> travel = Map();
        travel["title"] = street;
        travel["latitude"] = latLng.latitude;
        travel["longitude"] = latLng.longitude;

        _db.collection("travels").add(travel);
      });
    }
  }

  _moveCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition) );
  }

  //38.700428, -9.302090 / coliseu 41.890214, 12.492227
  _addListenerLocalization(){
    var geolocator = Geolocator();
    var locationOptions = LocationOptions(accuracy: LocationAccuracy.high);
    geolocator.getPositionStream( locationOptions ).listen((Position position) {
      setState(() {
        _cameraPosition =  CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 17);
        _moveCamera();
      });
    });
  }

  _recoverTravelForId(String idTravel) async {
    if (idTravel != null){

      DocumentSnapshot documentSnapshot = await _db.collection("travels")
          .document(idTravel).get();

      var data = documentSnapshot.data;
      String title = data["title"];
      LatLng latLng = LatLng( data["latitude"], data["longitude"] );

      setState(() {
        Marker marker = Marker(
            markerId: MarkerId("marker: ${latLng.latitude} - ${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow( title: title)
        );
        _markers.add(marker);
        _cameraPosition = CameraPosition(target: latLng, zoom: 18);
        _moveCamera();
      });
    } else {
      _addListenerLocalization();
    }
  }

  @override
  void initState() {
    super.initState();
    _recoverTravelForId(widget.idTravel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map"),),
      body: Container(
        child: GoogleMap(
          markers: _markers,
            mapType: MapType.normal,
            initialCameraPosition: _cameraPosition,
            onMapCreated: _onMapCreated,
            onLongPress: _addMarker,
        ),
      ),
    );
  }
}
