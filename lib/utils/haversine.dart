import 'dart:math';

class HaversineFormula {
  static const double R = 6371.0;

  static double hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    double rLat1 = _toRadians(lat1);
    double rLat2 = _toRadians(lat2);
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rLat1) * cos(rLat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}