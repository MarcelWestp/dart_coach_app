import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { player, trainer }

/// Modell für einen App-Benutzer inklusive Profilbild (avatarUrl)
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isTrainer;
  final bool approved;
  final String? trainerId;
  final String? avatarUrl; // NEU: URL oder Schlüssel für das Profilbild

  final String? club;
  final String? team;
  final String? dartsSetup;
  final String? board;
  final String? autodartsUsername;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isTrainer,
    this.approved = false,
    this.trainerId,
    this.avatarUrl,
    this.club,
    this.team,
    this.dartsSetup,
    this.board,
    this.autodartsUsername,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isTrainer': isTrainer,
      'approved': approved,
      if (trainerId != null) 'trainerId': trainerId,
      'avatarUrl': avatarUrl ?? '',
      'club': club ?? '',
      'team': team ?? '',
      'dartsSetup': dartsSetup ?? '',
      'board': board ?? '',
      'autodartsUsername': autodartsUsername ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    final String userRole =
        map['role'] ?? (map['isTrainer'] == true ? 'trainer' : 'player');
    final bool trainerFlag = userRole == 'trainer' || map['isTrainer'] == true;

    return AppUser(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: userRole,
      isTrainer: trainerFlag,
      approved: map['approved'] ?? true,
      trainerId: map['trainerId'],
      avatarUrl: map['avatarUrl'],
      club: map['club'],
      team: map['team'],
      dartsSetup: map['dartsSetup'],
      board: map['board'],
      autodartsUsername: map['autodartsUsername'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}