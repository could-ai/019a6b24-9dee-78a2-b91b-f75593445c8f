import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 1)
class Message extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String contactId;
  
  @HiveField(2)
  final String content; // Encrypted content
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final bool isSent; // true = sent by me, false = received
  
  @HiveField(5)
  final bool isRead;
  
  @HiveField(6)
  final bool isVoice; // Cipher Voice feature
  
  @HiveField(7)
  final bool selfDestruct; // Vanish on read
  
  Message({
    required this.id,
    required this.contactId,
    required this.content,
    required this.timestamp,
    required this.isSent,
    required this.isRead,
    this.isVoice = false,
    this.selfDestruct = false,
  });
}
