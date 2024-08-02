import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

class PatientLocationViewer extends StatefulWidget {
  final String patientName;
  final double latitude;
  final double longitude;

  const PatientLocationViewer({
    required this.patientName,
    required this.latitude,
    required this.longitude,
  });

  @override
  _PatientLocationViewerState createState() => _PatientLocationViewerState();
}

class _PatientLocationViewerState extends State<PatientLocationViewer> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    CameraPosition initialLocation = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 14.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.patientName} Location',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialLocation,
            markers: {
              Marker(
                markerId: MarkerId(widget.patientName),
                position: LatLng(widget.latitude, widget.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: InfoWindow(
                  title: widget.patientName,
                ),
              ),
            },
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });
            },
          ),
          if (_controller == null)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const Center(
                child: Icon(
                  Icons.pin_drop,
                  size: 50.0,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
