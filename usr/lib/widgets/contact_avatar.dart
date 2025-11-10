import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double size;
  
  const ContactAvatar({
    super.key,
    required this.contact,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = contact.avatarColor != null
        ? Color(int.parse('0xFF${contact.avatarColor}'))
        : const Color(0xFF6C63FF);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          contact.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}