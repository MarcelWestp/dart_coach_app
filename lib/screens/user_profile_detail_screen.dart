import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar_widget.dart';

/// Ein universeller Detail-Screen zur Ansicht von Nutzerprofilen (Spieler & Trainer).
/// Beachtet die Privatsphäre-Einstellungen sowie die optionale Erfolgsanzeige.
class UserProfileDetailScreen extends StatelessWidget {
  final String userId;        // ID des anzuzeigenden Profils
  final String currentUserId; // ID des aktuell angemeldeten Nutzers
  final String? fallbackName;

  const UserProfileDetailScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.fallbackName,
  });

  /// Berechnet das Treue-Abzeichen analog zum ProfileScreen
  Map<String, dynamic> _calculateLoyaltyBadge(DateTime createdAt) {
    final now = DateTime.now();
    final differenceInDays = now.difference(createdAt).inDays;
    final months = (differenceInDays / 30).floor();
    final years = (differenceInDays / 365).floor();

    String badgeLabel = 'Neu dabei';
    IconData badgeIcon = Icons.military_tech_outlined;
    Color badgeColor = Colors.grey;

    if (years >= 1) {
      badgeLabel = '$years ${years == 1 ? "Jahr" : "Jahre"} Mitglied';
      badgeIcon = Icons.stars;
      badgeColor = Colors.amber.shade700;
    } else if (months >= 9) {
      badgeLabel = '9 Monate dabei';
      badgeIcon = Icons.workspace_premium;
      badgeColor = Colors.purple;
    } else if (months >= 6) {
      badgeLabel = '6 Monate dabei';
      badgeIcon = Icons.workspace_premium;
      badgeColor = Colors.blue;
    } else if (months >= 3) {
      badgeLabel = '3 Monate dabei';
      badgeIcon = Icons.verified;
      badgeColor = Colors.teal;
    } else if (months >= 1) {
      badgeLabel = '1 Monat dabei';
      badgeIcon = Icons.verified_user;
      badgeColor = Colors.green;
    }

    return {'label': badgeLabel, 'icon': badgeIcon, 'color': badgeColor};
  }

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fallbackName != null ? 'Profil: $fallbackName' : 'Nutzerprofil',
        ),
      ),
      body: StreamBuilder<AppUser?>(
        stream: userService.getUserDataStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(
              child: Text(
                'Profil konnte nicht geladen werden.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // -----------------------------------------------------------------
          // ZUGRIFFSPRÜFUNG MIT currentUserId
          // -----------------------------------------------------------------
          final bool isOwnProfile = currentUserId == user.uid;
          final bool isAssignedTrainer = currentUserId == user.trainerId;
          final bool canAccess =
              isOwnProfile || isAssignedTrainer || !user.isPrivate;

          if (!canAccess) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Privates Profil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${user.name} hat das Profil als privat markiert. Nur der zugewiesene Trainer hat Zugriff auf diese Informationen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          // Prüfen, ob Trainingserfolge angezeigt werden dürfen
          final bool canSeeStats =
              isOwnProfile || isAssignedTrainer || user.showStats;

          final badge = _calculateLoyaltyBadge(user.createdAt);
          final dateFormatted =
              '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KOPFBEREICH: AVATAR, NAME, ROLLE & BADGE
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        UserAvatarWidget(user: user, radius: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  // Rolle (Spieler / Trainer)
                                  Chip(
                                    label: Text(
                                      user.isTrainer
                                          ? '🎯 Trainer'
                                          : '🎯 Spieler',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: user.isTrainer
                                        ? Colors.blue.shade700
                                        : Colors.deepOrange,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  // Treue-Badge
                                  Tooltip(
                                    message: 'Registriert am $dateFormatted',
                                    child: Chip(
                                      avatar: Icon(
                                        badge['icon'] as IconData,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      label: Text(
                                        badge['label'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: badge['color'] as Color,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. KARTENSEKTION: VEREIN & TEAM
                _buildSectionHeader(
                  'Verein & Zugehörigkeit',
                  Icons.groups_outlined,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.business,
                          title: 'Verein',
                          value: user.club != null && user.club!.isNotEmpty
                              ? user.club!
                              : 'Keinem Verein zugeordnet',
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          icon: Icons.shield_outlined,
                          title: 'Team',
                          value: user.team != null && user.team!.isNotEmpty
                              ? user.team!
                              : 'Kein Team angegeben',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. NEU: KARTENSEKTION TRAININGSERFOLGE (OPTIONAL)
                if (canSeeStats) ...[
                  _buildSectionHeader(
                    'Trainingserfolge',
                    Icons.workspace_premium_outlined,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Map<String, int>>(
                    stream: userService.getUserExerciseStats(user.uid),
                    builder: (context, statsSnapshot) {
                      if (statsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        );
                      }

                      final stats = statsSnapshot.data ??
                          {'total': 0, 'month': 0, 'week': 0};

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                'Diese Woche',
                                '${stats['week']}',
                                Colors.deepOrange,
                              ),
                              _buildStatColumn(
                                'Diesen Monat',
                                '${stats['month']}',
                                Colors.blue,
                              ),
                              _buildStatColumn(
                                'Gesamt',
                                '${stats['total']}',
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. KARTENSEKTION: DARTS-EQUIPMENT
                _buildSectionHeader(
                  'Mein Darts-Equipment',
                  Icons.sports_kabaddi,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.gps_fixed,
                          title: 'Darts Setup',
                          value: user.dartsSetup != null &&
                                  user.dartsSetup!.isNotEmpty
                              ? user.dartsSetup!
                              : 'Nicht hinterlegt',
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          icon: Icons.adjust,
                          title: 'Dartboard',
                          value: user.board != null && user.board!.isNotEmpty
                              ? user.board!
                              : 'Nicht hinterlegt',
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          icon: Icons.videocam_outlined,
                          title: 'Scolia / Autodarts',
                          value: user.autodartsUsername != null &&
                                  user.autodartsUsername!.isNotEmpty
                              ? user.autodartsUsername!
                              : 'Kein Account verknüpft',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Hilfswidget für Bereichs-Überschriften
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Hilfswidget für Statistik-Spalten
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Hilfswidget für eine Info-Zeile
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final bool isUnset =
        value == 'Nicht hinterlegt' ||
        value == 'Keine Angabe' ||
        value == 'Keinem Verein zugeordnet' ||
        value == 'Kein Team angegeben' ||
        value == 'Kein Account verknüpft';

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isUnset ? Colors.grey : Colors.black87,
              fontStyle: isUnset ? FontStyle.italic : FontStyle.normal,
              fontWeight: isUnset ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}