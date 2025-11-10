import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/encryption_service.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  final _encryptionService = EncryptionService();
  
  Box<Contact>? _contactsBox;
  Box<Message>? _messagesBox;
  
  List<Contact> _contacts = [];
  Map<String, List<Message>> _messagesByContact = {};
  
  List<Contact> get contacts => _contacts;
  
  /// Initialize Hive boxes for contacts and messages
  Future<void> initialize() async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ContactAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MessageAdapter());
      }
      
      _contactsBox = await Hive.openBox<Contact>('contacts');
      _messagesBox = await Hive.openBox<Message>('messages');
      
      _loadContacts();
      _loadMessages();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ChatProvider: $e');
    }
  }
  
  void _loadContacts() {
    if (_contactsBox != null) {
      _contacts = _contactsBox!.values.toList();
    }
  }
  
  void _loadMessages() {
    if (_messagesBox != null) {
      _messagesByContact.clear();
      for (var message in _messagesBox!.values) {
        if (!_messagesByContact.containsKey(message.contactId)) {
          _messagesByContact[message.contactId] = [];
        }
        _messagesByContact[message.contactId]!.add(message);
      }
      
      // Sort messages by timestamp
      _messagesByContact.forEach((key, messages) {
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
    }
  }
  
  /// Add contact from QR scan
  Future<void> addContact(Contact contact) async {
    if (_contactsBox != null) {
      await _contactsBox!.put(contact.id, contact);
      _loadContacts();
      notifyListeners();
    }
  }
  
  /// Get messages for specific contact
  List<Message> getMessagesForContact(String contactId) {
    return _messagesByContact[contactId] ?? [];
  }
  
  /// Send encrypted message
  Future<void> sendMessage({
    required String contactId,
    required String content,
    required String myPrivateKey,
    required String contactPublicKey,
    bool isVoice = false,
    bool selfDestruct = false,
  }) async {
    try {
      // Double-layer encryption: AES-256 + RSA-4096
      final encryptedContent = await _encryptionService.encryptMessage(
        content,
        contactPublicKey,
      );
      
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactId: contactId,
        content: encryptedContent,
        timestamp: DateTime.now(),
        isSent: true,
        isRead: false,
        isVoice: isVoice,
        selfDestruct: selfDestruct,
      );
      
      if (_messagesBox != null) {
        await _messagesBox!.put(message.id, message);
        _loadMessages();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  /// Receive and decrypt message
  Future<void> receiveMessage({
    required String contactId,
    required String encryptedContent,
    required String myPrivateKey,
    bool isVoice = false,
    bool selfDestruct = false,
  }) async {
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactId: contactId,
        content: encryptedContent,
        timestamp: DateTime.now(),
        isSent: false,
        isRead: false,
        isVoice: isVoice,
        selfDestruct: selfDestruct,
      );
      
      if (_messagesBox != null) {
        await _messagesBox!.put(message.id, message);
        _loadMessages();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error receiving message: $e');
    }
  }
  
  /// Mark message as read and delete if self-destruct enabled
  Future<void> markAsRead(String messageId, String myPrivateKey) async {
    if (_messagesBox != null) {
      final message = _messagesBox!.get(messageId);
      if (message != null) {
        if (message.selfDestruct) {
          // Delete message immediately after reading
          await _messagesBox!.delete(messageId);
        } else {
          // Just mark as read
          final updatedMessage = Message(
            id: message.id,
            contactId: message.contactId,
            content: message.content,
            timestamp: message.timestamp,
            isSent: message.isSent,
            isRead: true,
            isVoice: message.isVoice,
            selfDestruct: message.selfDestruct,
          );
          await _messagesBox!.put(messageId, updatedMessage);
        }
        
        _loadMessages();
        notifyListeners();
      }
    }
  }
  
  /// Decrypt message content
  Future<String> decryptMessage(String encryptedContent, String privateKey) async {
    try {
      return await _encryptionService.decryptMessage(encryptedContent, privateKey);
    } catch (e) {
      debugPrint('Error decrypting message: $e');
      return '[Decryption failed]';
    }
  }
  
  /// Delete conversation
  Future<void> deleteConversation(String contactId) async {
    if (_messagesBox != null) {
      final messages = getMessagesForContact(contactId);
      for (var message in messages) {
        await _messagesBox!.delete(message.id);
      }
      _loadMessages();
      notifyListeners();
    }
  }
  
  /// Delete contact
  Future<void> deleteContact(String contactId) async {
    if (_contactsBox != null) {
      await _contactsBox!.delete(contactId);
      await deleteConversation(contactId);
      _loadContacts();
      notifyListeners();
    }
  }
}
