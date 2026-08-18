import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pencarian_sepatu/main.dart';

void main() {
  testWidgets('Pencarian Sepatu smoke test', (WidgetTester tester) async {
    // Membangun aplikasi kita dan memicu frame.
    // Pastikan tidak menggunakan 'const MyApp()' jika di main.dart tidak ada const constructor
    await tester.pumpWidget(MyApp());

    // Memverifikasi bahwa judul AppBar aplikasi kita muncul di layar
    expect(find.text('Cari Toko Sepatu Terdekat'), findsOneWidget);

    // Memverifikasi bahwa terdapat sebuah kolom input teks (TextField) untuk pencarian
    expect(find.byType(TextField), findsOneWidget);

    // Memastikan tidak ada teks angka '0' dari aplikasi bawaan sebelumnya
    expect(find.text('0'), findsNothing);
  });
}