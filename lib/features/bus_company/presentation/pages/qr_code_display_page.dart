import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class QRCodeDisplayPage extends StatefulWidget {
  final String tripName;
  final String busId;
  final String time;
  final String fromLocation;
  final String toLocation;
  final String seats;
  final String company;

  const QRCodeDisplayPage({
    super.key,
    required this.tripName,
    required this.busId,
    required this.time,
    required this.fromLocation,
    required this.toLocation,
    required this.seats,
    required this.company,
  });

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage> {
  late String uniqueCode;
  late String qrData;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _generateUniqueCode();
  }

  void _generateUniqueCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999);
    uniqueCode = 'TRP-$timestamp-$random';
    qrData = 'ID: $uniqueCode | Trip: ${widget.tripName} | Bus: ${widget.busId}';
  }

  Future<void> _shareQRCode() async {
    try {
      final Uint8List? image = await screenshotController.capture();
      if (image != null) {
        await Share.shareXFiles(
          [XFile.fromData(image, name: 'qr_code.png', mimeType: 'image/png')],
          text: 'Check-in QR Code for ${widget.tripName}',
        );
      }
    } catch (e) {
      _showStatus('Sharing not supported on this browser', Colors.orange);
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      final Uint8List? image = await screenshotController.capture();
      if (image != null) {
        final doc = pw.Document();
        doc.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(pw.MemoryImage(image)))));
        await Printing.sharePdf(bytes: await doc.save(), filename: 'qr_code.pdf');
        _showStatus('QR Code ready for download!', Colors.green);
      }
    } catch (e) {
      _showStatus('Download failed', Colors.red);
    }
  }

  Future<void> _printQRCode() async {
    try {
      final Uint8List? image = await screenshotController.capture();
      if (image != null) {
        final doc = pw.Document();
        doc.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(pw.MemoryImage(image)))));
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
      }
    } catch (e) {
      _showStatus('Printing failed', Colors.red);
    }
  }

  void _showStatus(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(color: Color(0xFFFF6D00)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('QR Code Generation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Screenshot(
                    controller: screenshotController,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
                      ),
                      child: Column(
                        children: [
                          Text(widget.tripName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(widget.company, style: const TextStyle(color: Colors.blueGrey, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${widget.busId} • Departure: ${widget.time}', style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
                          const SizedBox(height: 30),

                          // QR Code
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                              foregroundColor: const Color(0xFFFF6D00),
                              backgroundColor: const Color(0xFFFFF3E0),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text('Code ID: $uniqueCode', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const SizedBox(height: 30),

                          // Dynamic Trip Details Grid
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildDetailItem('From', widget.fromLocation),
                                    _buildDetailItem('To', widget.toLocation),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildDetailItem('Seats', widget.seats),
                                    _buildDetailItem('Departure', widget.time),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildActionButton(Icons.file_download_outlined, 'Download QR Code', const Color(0xFFFFF3E0), const Color(0xFFFF6D00), _downloadQRCode),
                  const SizedBox(height: 15),
                  _buildActionButton(Icons.share_outlined, 'Share QR Code', const Color(0xFFE3F2FD), const Color(0xFF1976D2), _shareQRCode),
                  const SizedBox(height: 15),
                  _buildActionButton(Icons.print_outlined, 'Print QR Code', const Color(0xFFF3E5F5), const Color(0xFF9C27B0), _printQRCode),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color bgColor, Color textColor, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor, size: 22),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}
