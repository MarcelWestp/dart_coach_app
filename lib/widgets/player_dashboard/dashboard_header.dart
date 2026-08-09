import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../screens/player_stats_overview_screen.dart';
import '../user_avatar_widget.dart';

/// Ein eigenständiges Header-Widget für das Spieler-Dashboard.
/// Beinhaltet Profilinformationen, den Link zur Statistik und die Kalenderwochen-Steuerung.
class DashboardHeader extends StatelessWidget {
  final AppUser user;
  final int currentWeekNumber;
  final int currentYear;
  final ValueChanged<int> onWeekChange;

  const DashboardHeader({
    super.key,
    required this.user,
    required this.currentWeekNumber,
    required this.currentYear,
    required this.onWeekChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PROFIL-HEADER MIT STATISTIK-BUTTON
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                UserAvatarWidget(user: user, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Willkommen, ${user.name}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.club != null && user.club!.isNotEmpty
                            ? '${user.club} ${user.team != null ? "(${user.team})" : ""}'
                            : 'Spieler Dashboard',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bar_chart,
                    color: Colors.deepOrange,
                    size: 28,
                  ),
                  tooltip: 'Meine Statistiken',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerStatsOverviewScreen(
                          playerId: user.uid,
                          playerName: user.name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // WOCHEN-NAVIGATION
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => onWeekChange(-1),
              ),
              Text(
                'Kalenderwoche $currentWeekNumber ($currentYear)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: () => onWeekChange(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}