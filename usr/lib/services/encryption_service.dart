import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:pointycastle/export.dart' hide SecureRandom;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

class EncryptionService {
  /// Generate RSA-4096 key pair for user identity
  Future<RSAKeyPairData> generateRSAKeyPair() async {
    final secureRandom = _getSecureRandom();
    
    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // public exponent
      4096, // key size
      64, // certainty for prime generation
    );
    
    final keyGenerator = RSAKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    
    final pair = keyGenerator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;
    
    return RSAKeyPairData(
      publicKeyPem: _encodePublicKeyToPem(publicKey),
      privateKeyPem: _encodePrivateKeyToPem(privateKey),
      publicKey: publicKey,
      privateKey: privateKey,
    );
  }
  
  /// Generate unique identity ID from public key
  String generateIdentityId(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!.toString();
    final hash = sha256.convert(utf8.encode(modulus));
    return hash.toString().substring(0, 16).toUpperCase();
  }
  
  /// Double-layer encryption: AES-256 + RSA-4096
  Future<String> encryptMessage(String plaintext, String recipientPublicKeyPem) async {
    try {
      // Step 1: Generate random AES-256 key for this message
      final aesKey = _generateAESKey();
      
      // Step 2: Encrypt message with AES-256
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(
        encrypt_lib.Key(aesKey),
        mode: encrypt_lib.AESMode.cbc,
      ));
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);
      
      // Step 3: Encrypt AES key with recipient's RSA public key
      final publicKey = _decodePublicKeyFromPem(recipientPublicKeyPem);
      final encryptedAESKey = _rsaEncrypt(aesKey, publicKey);
      
      // Step 4: Combine encrypted AES key + IV + encrypted message
      final combined = {
        'key': base64.encode(encryptedAESKey),
        'iv': iv.base64,
        'msg': encryptedMessage.base64,
      };
      
      return base64.encode(utf8.encode(json.encode(combined)));
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }
  
  /// Decrypt message with double-layer decryption
  Future<String> decryptMessage(String encryptedData, String privateKeyPem) async {
    try {
      // Step 1: Decode the combined data
      final decodedData = json.decode(utf8.decode(base64.decode(encryptedData)));
      final encryptedAESKey = base64.decode(decodedData['key']);
      final iv = encrypt_lib.IV.fromBase64(decodedData['iv']);
      final encryptedMessage = encrypt_lib.Encrypted.fromBase64(decodedData['msg']);
      
      // Step 2: Decrypt AES key with private RSA key
      final privateKey = _decodePrivateKeyFromPem(privateKeyPem);
      final aesKey = _rsaDecrypt(encryptedAESKey, privateKey);
      
      // Step 3: Decrypt message with AES key
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(
        encrypt_lib.Key(aesKey),
        mode: encrypt_lib.AESMode.cbc,
      ));
      
      return encrypter.decrypt(encryptedMessage, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
  
  // Helper methods
  
  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
  
  Uint8List _generateAESKey() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
  }
  
  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return encryptor.process(data);
  }
  
  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return decryptor.process(data);
  }
  
  String _encodePublicKeyToPem(RSAPublicKey key) {
    final modulus = key.modulus!.toRadixString(16);
    final exponent = key.exponent!.toRadixString(16);
    return '$modulus:$exponent';
  }
  
  String _encodePrivateKeyToPem(RSAPrivateKey key) {
    final modulus = key.modulus!.toRadixString(16);
    final privateExponent = key.privateExponent!.toRadixString(16);
    final p = key.p!.toRadixString(16);
    final q = key.q!.toRadixString(16);
    return '$modulus:$privateExponent:$p:$q';
  }
  
  RSAPublicKey _decodePublicKeyFromPem(String pem) {
    final parts = pem.split(':');
    final modulus = BigInt.parse(parts[0], radix: 16);
    final exponent = BigInt.parse(parts[1], radix: 16);
    return RSAPublicKey(modulus, exponent);
  }
  
  RSAPrivateKey _decodePrivateKeyFromPem(String pem) {
    final parts = pem.split(':');
    final modulus = BigInt.parse(parts[0], radix: 16);
    final privateExponent = BigInt.parse(parts[1], radix: 16);
    final p = BigInt.parse(parts[2], radix: 16);
    final q = BigInt.parse(parts[3], radix: 16);
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }
}

class RSAKeyPairData {
  final String publicKeyPem;
  final String privateKeyPem;
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;
  
  RSAKeyPairData({
    required this.publicKeyPem,
    required this.privateKeyPem,
    required this.publicKey,
    required this.privateKey,
  });
}