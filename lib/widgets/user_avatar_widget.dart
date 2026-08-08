import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Ein universelles Avatar-Widget, das ein Bild anzeigt oder automatisch Initialen generiert
class UserAvatarWidget extends StatelessWidget {
  final AppUser user;
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.radius = 24.0,
  });

  /// Generiert 1 bis 2 Buchstaben aus dem Namen (z. B. "Max Mustermann" -> "MM")
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: Colors.deepOrange.shade100,
      );
    }

    // Fallback: Initialen anzeigen
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepOrange,
      child: Text(
        _getInitials(user.name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}