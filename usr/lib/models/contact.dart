import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 0)
class Contact extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String publicKeyPem;
  
  @HiveField(3)
  final DateTime addedAt;
  
  @HiveField(4)
  final String? avatarColor;
  
  Contact({
    required this.id,
    required this.username,
    required this.publicKeyPem,
    required this.addedAt,
    this.avatarColor,
  });
  
  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username[0].toUpperCase();
  }
}
