import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/identity_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../widgets/contact_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _selfDestruct = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage(Contact contact, String myPrivateKey, String content) async {
    if (content.trim().isEmpty) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    await chatProvider.sendMessage(
      contactId: contact.id,
      content: content,
      myPrivateKey: myPrivateKey,
      contactPublicKey: contact.publicKeyPem,
      selfDestruct: _selfDestruct,
    );
    
    _messageController.clear();
    setState(() => _selfDestruct = false);
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
  
  @override
  Widget build(BuildContext context) {
    final contact = ModalRoute.of(context)!.settings.arguments as Contact;
    final identityProvider = Provider.of<IdentityProvider>(context, listen: false);
    final myPrivateKey = identityProvider.currentIdentity?.privateKeyPem ?? '';
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            ContactAvatar(contact: contact, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ID: ${contact.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context, contact),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getMessagesForContact(contact.id);
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send your first encrypted message',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(
                      message,
                      myPrivateKey,
                      chatProvider,
                    );
                  },
                );
              },
            ),
          ),
          
          // Self-destruct toggle
          if (_selfDestruct)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_off,
                    size: 16,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Self-destruct mode: Message will vanish on read',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _selfDestruct ? Icons.visibility_off : Icons.visibility_off_outlined,
                    color: _selfDestruct ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    setState(() => _selfDestruct = !_selfDestruct);
                  },
                  tooltip: 'Self-destruct message',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type encrypted message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(
                      contact,
                      myPrivateKey,
                      _messageController.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF6C63FF),
                  ),
                  onPressed: () => _sendMessage(
                    contact,
                    myPrivateKey,
                    _messageController.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(
    Message message,
    String myPrivateKey,
    ChatProvider chatProvider,
  ) {
    final isSent = message.isSent;
    
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSent
              ? const Color(0xFF6C63FF)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.selfDestruct)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Self-destruct',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            FutureBuilder<String>(
              future: chatProvider.decryptMessage(message.content, myPrivateKey),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                
                return Text(
                  snapshot.data ?? '[Decryption failed]',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                if (isSent)
                  const SizedBox(width: 4),
                if (isSent)
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF00D9FF)
                        : Colors.white.withOpacity(0.6),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: Text(
          'This will permanently delete all messages with ${contact.username}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              await chatProvider.deleteConversation(contact.id);
              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close chat screen
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}