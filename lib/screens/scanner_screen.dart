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
              colors: [Color(0xFFD8BFD8), Color(0xFFA3D8F4),],
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
              controller.dispose();
              Navigator.of(context).pop();
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
            controller.stop();
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
