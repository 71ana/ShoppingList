import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatelessWidget {
  final Function(String) onScan;

  const ScannerScreen({required this.onScan, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MobileScannerController controller = MobileScannerController();

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
          'Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 5.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.dispose(); // Dispose of the camera
              Navigator.of(context).pop(); // Navigate back
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first.rawValue ?? 'No code';
          if (barcode != 'No code') {
            onScan(barcode);
            controller.stop(); // Stop the scanner to release resources
            Navigator.of(context).pop(); // Navigate back
          }
        },
      ),
    );
  }
}
