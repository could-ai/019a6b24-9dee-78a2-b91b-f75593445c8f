import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/identity_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact.dart';
import 'dart:math';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
  
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final identityProvider = Provider.of<IdentityProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Parse QR code data
      final contactIdentity = identityProvider.parseQRData(code);
      
      if (contactIdentity == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR code format')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }
      
      // Check if this is user's own QR code
      if (contactIdentity.id == identityProvider.currentIdentity?.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot add yourself as a contact')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }
      
      // Check if contact already exists
      final existingContact = chatProvider.contacts
          .where((c) => c.id == contactIdentity.id)
          .firstOrNull;
      
      if (existingContact != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${existingContact.username} is already in your contacts')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }
      
      // Generate random avatar color
      final random = Random();
      final colors = [
        'FF6B6B', '4ECDC4', '45B7D1', 'FFA07A',
        '98D8C8', 'F7DC6F', 'BB8FCE', '85C1E9',
      ];
      final avatarColor = colors[random.nextInt(colors.length)];
      
      // Create contact
      final contact = Contact(
        id: contactIdentity.id,
        username: contactIdentity.username,
        publicKeyPem: contactIdentity.publicKeyPem,
        addedAt: DateTime.now(),
        avatarColor: avatarColor,
      );
      
      // Add to contacts
      await chatProvider.addContact(contact);
      
      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Contact Added'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contact.username}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${contact.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can now send encrypted messages to this contact',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close QR scan screen
                },
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close QR scan screen
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: contact,
                  );
                },
                child: const Text('Start Chat'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contact: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          
          // Instructions
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF6C63FF),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan Contact QR Code',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position the QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Adding contact...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Draw dark overlay except center square
    final centerSize = size.width * 0.7;
    final left = (size.width - centerSize) / 2;
    final top = (size.height - centerSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, centerSize, centerSize);
    
    // Draw overlay with hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16))),
      ),
      paint,
    );
    
    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final bracketLength = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(left, top + bracketLength),
      Offset(left, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + bracketLength, top),
      bracketPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(left + centerSize - bracketLength, top),
      Offset(left + centerSize, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + centerSize, top),
      Offset(left + centerSize, top + bracketLength),
      bracketPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + centerSize - bracketLength),
      Offset(left, top + centerSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top + centerSize),
      Offset(left + bracketLength, top + centerSize),
      bracketPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(left + centerSize - bracketLength, top + centerSize),
      Offset(left + centerSize, top + centerSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + centerSize, top + centerSize - bracketLength),
      Offset(left + centerSize, top + centerSize),
      bracketPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}