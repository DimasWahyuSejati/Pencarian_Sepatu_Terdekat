class TokoSepatu {
  String idToko;
  String namaToko;
  String alamat;
  double latitude;
  double longitude;
  String brand;
  double rating;
  double jarak;
  double estimasiWaktuMenit;

  TokoSepatu({
    required this.idToko,
    required this.namaToko,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.brand,
    required this.rating,
    this.jarak = 0.0,
    this.estimasiWaktuMenit = 0.0,
  });
}