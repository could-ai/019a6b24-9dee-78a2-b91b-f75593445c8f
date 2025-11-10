import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/encryption_service.dart';
import '../models/user_identity.dart';

class IdentityProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _encryptionService = EncryptionService();
  
  UserIdentity? _currentIdentity;
  bool _isInitialized = false;
  
  UserIdentity? get currentIdentity => _currentIdentity;
  bool get isInitialized => _isInitialized;
  bool get hasIdentity => _currentIdentity != null;
  
  /// Initialize and check if user has existing identity
  Future<void> initialize() async {
    try {
      final privateKeyPem = await _secureStorage.read(key: 'private_key');
      final publicKeyPem = await _secureStorage.read(key: 'public_key');
      final identityId = await _secureStorage.read(key: 'identity_id');
      final username = await _secureStorage.read(key: 'username');
      
      if (privateKeyPem != null && publicKeyPem != null && identityId != null) {
        _currentIdentity = UserIdentity(
          id: identityId,
          username: username ?? 'Anonymous',
          publicKeyPem: publicKeyPem,
          privateKeyPem: privateKeyPem,
        );
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing identity: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Generate new cryptographic identity (RSA-4096 key pair)
  Future<void> generateIdentity(String username) async {
    try {
      final keyPair = await _encryptionService.generateRSAKeyPair();
      final identityId = _encryptionService.generateIdentityId(keyPair.publicKey);
      
      _currentIdentity = UserIdentity(
        id: identityId,
        username: username.isEmpty ? 'Anonymous' : username,
        publicKeyPem: keyPair.publicKeyPem,
        privateKeyPem: keyPair.privateKeyPem,
      );
      
      // Store securely
      await _secureStorage.write(key: 'private_key', value: keyPair.privateKeyPem);
      await _secureStorage.write(key: 'public_key', value: keyPair.publicKeyPem);
      await _secureStorage.write(key: 'identity_id', value: identityId);
      await _secureStorage.write(key: 'username', value: _currentIdentity!.username);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating identity: $e');
      rethrow;
    }
  }
  
  /// Get QR code data for identity sharing
  String getIdentityQRData() {
    if (_currentIdentity == null) return '';
    return '${_currentIdentity!.id}|${_currentIdentity!.username}|${_currentIdentity!.publicKeyPem}';
  }
  
  /// Parse scanned QR code and return contact identity
  UserIdentity? parseQRData(String qrData) {
    try {
      final parts = qrData.split('|');
      if (parts.length != 3) return null;
      
      return UserIdentity(
        id: parts[0],
        username: parts[1],
        publicKeyPem: parts[2],
        privateKeyPem: '', // Contact doesn't have our private key
      );
    } catch (e) {
      debugPrint('Error parsing QR data: $e');
      return null;
    }
  }
  
  /// Clear identity (for testing or reset)
  Future<void> clearIdentity() async {
    await _secureStorage.deleteAll();
    _currentIdentity = null;
    notifyListeners();
  }
}
