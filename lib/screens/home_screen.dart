import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/toko_sepatu.dart';
import '../utils/haversine.dart';
import '../service/places_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? userLat;
  double? userLon;
  final double kecepatanRataRataKmh = 30.0;

  bool isLoadingLocation = true;
  bool isSearching = false;

  TextEditingController searchController = TextEditingController();
  List<TokoSepatu> hasilPencarian = [];

  // Google Maps Controller & Markers
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { isLoadingLocation = false; });
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { isLoadingLocation = false; });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() { isLoadingLocation = false; });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLat = position.latitude;
      userLon = position.longitude;
      isLoadingLocation = false;

      // Tambahkan marker untuk lokasi pengguna saat ini
      _markers.add(
        Marker(
          markerId: MarkerId('user_lokasi'),
          position: LatLng(userLat!, userLon!),
          infoWindow: InfoWindow(title: 'Lokasi Anda Saat Ini'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<void> cariToko(String query) async {
    if (userLat == null || userLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap tunggu hingga lokasi Anda ditemukan.')),
      );
      return;
    }

    if (query.trim().isEmpty) {
      return;
    }
    setState(() {
      isSearching = true;
      hasilPencarian.clear();
    });
    List<TokoSepatu> tokoReal = await PlacesService.cariTokoReal(
      lat: userLat!,
      lng: userLon!,
      keyword: query,
    );

    Set<Marker> markerBaru = {};
    markerBaru.add(
        Marker(
          markerId: MarkerId('user_lokasi'),
          position: LatLng(userLat!, userLon!),
          infoWindow: InfoWindow(title: 'Lokasi Anda Saat Ini'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        )
    );
    for (var toko in tokoReal) {
      toko.jarak = HaversineFormula.hitungJarak(userLat!, userLon!, toko.latitude, toko.longitude);
      toko.estimasiWaktuMenit = (toko.jarak / kecepatanRataRataKmh) * 60;
      markerBaru.add(
        Marker(
          markerId: MarkerId(toko.idToko),
          position: LatLng(toko.latitude, toko.longitude),
          infoWindow: InfoWindow(
            title: toko.namaToko,
            snippet: '${toko.jarak.toStringAsFixed(2)} km | ⭐ ${toko.rating}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    tokoReal.sort((a, b) {
      int perbandinganJarak = a.jarak.compareTo(b.jarak);
      if (perbandinganJarak != 0) return perbandinganJarak;
      return b.rating.compareTo(a.rating);
    });
    setState(() {
      hasilPencarian = tokoReal;
      _markers = markerBaru;
      isSearching = false;
    });

    if (tokoReal.isNotEmpty) {
      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(tokoReal.first.latitude, tokoReal.first.longitude),
          zoom: 13.0,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toko tidak ditemukan. Coba kata kunci lain.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Toko Sepatu Terdekat'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cari Merek (Contoh: Nike / Adidas)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.blueAccent),
                  onPressed: () => cariToko(searchController.text),
                ),
              ),
              onSubmitted: cariToko,
            ),
          ),

          Expanded(
            flex: 3,
            child: isLoadingLocation || userLat == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Mendapatkan Lokasi GPS...'),
                ],
              ),
            )
                : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(userLat!, userLon!),
                zoom: 15.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),


          Expanded(
            flex: 2,
            child: isSearching
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Mencari toko asli di sekitar Anda...")
                ],
              ),
            )
                : hasilPencarian.isEmpty
                ? Center(child: Text('Belum ada hasil pencarian.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: hasilPencarian.length,
              padding: EdgeInsets.only(top: 8),
              itemBuilder: (context, index) {
                final toko = hasilPencarian[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.store, color: Colors.blueAccent, size: 40),
                    title: Text(toko.namaToko, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${toko.alamat}\nJarak: ${toko.jarak.toStringAsFixed(2)} km\nEst. Waktu: ${toko.estimasiWaktuMenit.toStringAsFixed(0)} menit'
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 24),
                        Text('${toko.rating}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}