import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar_widget.dart';
import 'user_profile_detail_screen.dart';

/// Bildschirm zur Suche nach Spielern und Trainern mit Direktverlinkung zum Profil.
/// Fügt sich nahtlos in PlayerMainScreen/TrainerMainScreen ohne doppelte AppBar ein.
class UserSearchScreen extends StatefulWidget {
  final AppUser currentUser; // Der aktuell angemeldete Nutzer

  const UserSearchScreen({super.key, required this.currentUser});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'player', 'trainer'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kein Scaffold und keine AppBar mehr!
    // Stattdessen geben wir direkt die Column zurück.
    return Column(
      children: [
        // SUCHLEISTE & FILTER-CHIPS
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Name, Verein oder Team suchen...',
                  prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
              const SizedBox(height: 12),

              // FILTER: ALLE / SPIELER / TRAINER
              Row(
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: _selectedRoleFilter == 'all',
                    selectedColor: Colors.deepOrange.shade100,
                    onSelected: (_) => setState(() => _selectedRoleFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Spieler'),
                    selected: _selectedRoleFilter == 'player',
                    selectedColor: Colors.deepOrange.shade100,
                    onSelected: (_) => setState(() => _selectedRoleFilter = 'player'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Trainer'),
                    selected: _selectedRoleFilter == 'trainer',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) => setState(() => _selectedRoleFilter = 'trainer'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ERGEBNIS-LISTE
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _userService.searchUsers(
              query: _searchQuery,
              roleFilter: _selectedRoleFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                );
              }

              final users = snapshot.data ?? [];

              // Eigenen Nutzer aus der Suchliste filtern
              final filteredUsers =
                  users.where((u) => u.uid != widget.currentUser.uid).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text(
                    'Keine Nutzer gefunden.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final targetUser = filteredUsers[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: UserAvatarWidget(user: targetUser, radius: 22),
                      title: Row(
                        children: [
                          Text(
                            targetUser.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (targetUser.isPrivate) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        targetUser.club != null && targetUser.club!.isNotEmpty
                            ? '${targetUser.club} ${targetUser.team != null ? "(${targetUser.team})" : ""}'
                            : (targetUser.isTrainer ? 'Trainer' : 'Spieler'),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      trailing: Chip(
                        label: Text(
                          targetUser.isTrainer ? 'Trainer' : 'Spieler',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: targetUser.isTrainer
                            ? Colors.blue.shade700
                            : Colors.deepOrange,
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () {
                        // Navigation zum Profil-Detailansicht
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserProfileDetailScreen(
                              userId: targetUser.uid,
                              currentUserId: widget.currentUser.uid,
                              fallbackName: targetUser.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}