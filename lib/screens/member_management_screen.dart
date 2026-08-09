import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Bildschirm für Trainer/Admins zur Bestätigung und Verwaltung von Mitgliedern.
/// Passt sich nahtlos in den TrainerMainScreen ein (ohne doppelten Header).
class MemberManagementScreen extends StatelessWidget {
  final String currentTrainerId;

  const MemberManagementScreen({super.key, required this.currentTrainerId});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // TAB-LEISTE OBEN (Direkt unter der Haupt-AppBar des TrainerMainScreen)
          Container(
            color: Theme.of(context).canvasColor,
            child: const TabBar(
              indicatorColor: Colors.deepOrange,
              labelColor: Colors.deepOrange,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.pending_actions), text: 'Anfragen'),
                Tab(icon: Icon(Icons.people), text: 'Mitglieder'),
              ],
            ),
          ),

          // INHALT DER BEIDEN TABS
          Expanded(
            child: TabBarView(
              children: [
                // TAB 1: AUSSTEHENDE ANFRAGEN
                StreamBuilder<List<AppUser>>(
                  stream: userService.getPendingUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pendingUsers = snapshot.data ?? [];

                    if (pendingUsers.isEmpty) {
                      return const Center(
                        child: Text(
                          'Keine ausstehenden Registrierungen.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: pendingUsers.length,
                      itemBuilder: (context, index) {
                        final user = pendingUsers[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(
                                user.isTrainer ? Icons.sports : Icons.person,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'E-Mail: ${user.email}\nRolle: ${user.isTrainer ? "Trainer" : "Spieler"}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bestätigen
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green, size: 28),
                                  tooltip: 'Mitglied bestätigen',
                                  onPressed: () async {
                                    await userService.approveUser(user.uid);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${user.name} wurde bestätigt!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                // Ablehnen / Löschen
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red, size: 28),
                                  tooltip: 'Anfrage ablehnen',
                                  onPressed: () async {
                                    await userService.deleteUser(user.uid);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Anfrage von ${user.name} gelöscht.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // TAB 2: BESTÄTIGTE MITGLIEDER
                StreamBuilder<List<AppUser>>(
                  stream: userService.getApprovedUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data ?? [];

                    if (members.isEmpty) {
                      return const Center(
                        child: Text(
                          'Noch keine bestätigten Mitglieder vorhanden.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final bool isSelf = member.uid == currentTrainerId;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelf
                                  ? Colors.deepOrange
                                  : Colors.grey.shade300,
                              child: Icon(
                                member.isTrainer ? Icons.sports : Icons.person,
                                color: isSelf ? Colors.white : Colors.black87,
                              ),
                            ),
                            title: Text(
                              member.name + (isSelf ? ' (Du)' : ''),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${member.email} • ${member.isTrainer ? "Trainer" : "Spieler"}',
                            ),
                            trailing: isSelf
                                ? const Tooltip(
                                    message: 'Du kannst dich nicht selbst entfernen',
                                    child: Icon(Icons.lock, color: Colors.grey),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    tooltip: 'Mitglied entfernen',
                                    onPressed: () {
                                      _confirmDeleteUser(
                                          context, userService, member);
                                    },
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog-Abfrage vor dem Löschen eines Mitglieds
  void _confirmDeleteUser(
      BuildContext context, UserService userService, AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${user.name} wirklich entfernen?'),
          content: Text(
            'Möchtest du das Konto von ${user.name} (${user.email}) wirklich aus der Mitgliederverwaltung löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                await userService.deleteUser(user.uid);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.name} wurde entfernt.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entfernen'),
            ),
          ],
        );
      },
    );
  }
}