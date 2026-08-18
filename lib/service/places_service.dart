import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/toko_sepatu.dart';

class PlacesService {
  static const String _apiKey = "AIzaSyDm0ZQgpb7Z4ImhD2DKkuhlLWUYYUr7RZQ";

  static Future<List<TokoSepatu>> cariTokoReal({
    required double lat,
    required double lng,
    required String keyword,
  }) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=50000&keyword=sepatu $keyword&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TokoSepatu> listHasil = [];

        for (var item in data['results']) {
          listHasil.add(
            TokoSepatu(
              idToko: item['place_id'] ?? DateTime.now().toString(),
              namaToko: item['name'] ?? 'Toko Sepatu',
              alamat: item['vicinity'] ?? 'Alamat tidak tersedia',
              latitude: item['geometry']['location']['lat'],
              longitude: item['geometry']['location']['lng'],
              brand: keyword,
              rating: (item['rating'] != null)
                  ? (item['rating'] as num).toDouble()
                  : 0.0,
            ),
          );
        }
        return listHasil;
      } else {
        print("Error API Places: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error Koneksi API: $e");
      return [];
    }
  }
}