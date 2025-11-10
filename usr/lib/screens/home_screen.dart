import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/identity_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact.dart';
import '../widgets/contact_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Whispr',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          // Settings/Stealth Mode
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/stealth-mode');
            },
          ),
          // My Identity QR Code
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showMyIdentityQR(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.contacts.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            itemCount: chatProvider.contacts.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final contact = chatProvider.contacts[index];
              final messages = chatProvider.getMessagesForContact(contact.id);
              final lastMessage = messages.isNotEmpty ? messages.last : null;
              final unreadCount = messages.where((m) => !m.isRead && !m.isSent).length;
              
              return _buildContactTile(
                context,
                contact,
                lastMessage?.timestamp,
                unreadCount,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/qr-scan');
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Add Contact'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Contacts Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan a QR code to add your first contact\nand start secure messaging',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/qr-scan');
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactTile(
    BuildContext context,
    Contact contact,
    DateTime? lastMessageTime,
    int unreadCount,
  ) {
    return ListTile(
      leading: ContactAvatar(contact: contact),
      title: Text(
        contact.username,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessageTime != null
            ? DateFormat('MMM d, h:mm a').format(lastMessageTime)
            : 'No messages yet',
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
        ),
      ),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pushNamed(
          '/chat',
          arguments: contact,
        );
      },
    );
  }
  
  void _showMyIdentityQR(BuildContext context) {
    final identityProvider = Provider.of<IdentityProvider>(context, listen: false);
    final qrData = identityProvider.getIdentityQRData();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              identityProvider.currentIdentity?.username ?? 'Anonymous',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${identityProvider.currentIdentity?.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
