import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../widgets/user_avatar_widget.dart';
import '../main.dart'; // Import für themeModeNotifier

/// Profil-Bildschirm zur Verwaltung von Stammdaten, Equipment, Appearance & Sicherheit.
/// Fügt sich ohne doppeltes Scaffold/AppBar nahtlos in die Hauptnavigation ein.
class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _clubController;
  late TextEditingController _teamController;
  late TextEditingController _dartsController;
  late TextEditingController _boardController;
  late TextEditingController _autodartsController;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _isChangingPassword = false;
  late String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.user.avatarUrl;
    _nameController = TextEditingController(text: widget.user.name);
    _clubController = TextEditingController(text: widget.user.club ?? '');
    _teamController = TextEditingController(text: widget.user.team ?? '');
    _dartsController = TextEditingController(text: widget.user.dartsSetup ?? '');
    _boardController = TextEditingController(text: widget.user.board ?? '');
    _autodartsController =
        TextEditingController(text: widget.user.autodartsUsername ?? '');
  }

  /// Berechnet das Treue-Abzeichen basierend auf dem Erstellungsdatum
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

    return {
      'label': badgeLabel,
      'icon': badgeIcon,
      'color': badgeColor,
    };
  }

  /// Dialog zum Ändern der Bild-URL
  void _showAvatarEditDialog() {
    final urlController = TextEditingController(text: _currentAvatarUrl ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profilbild ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gib die Web-Adresse (URL) deines Profilbilds ein:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Bild-URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _currentAvatarUrl = '');
                Navigator.pop(context);
              },
              child: const Text('Bild entfernen', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentAvatarUrl = urlController.text.trim();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    );
  }

  /// Speichert die Profiländerungen
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedUser = AppUser(
      uid: widget.user.uid,
      name: _nameController.text.trim(),
      email: widget.user.email,
      role: widget.user.role,
      isTrainer: widget.user.isTrainer,
      approved: widget.user.approved,
      trainerId: widget.user.trainerId,
      avatarUrl: _currentAvatarUrl,
      club: _clubController.text.trim(),
      team: _teamController.text.trim(),
      dartsSetup: _dartsController.text.trim(),
      board: _boardController.text.trim(),
      autodartsUsername: _autodartsController.text.trim(),
      createdAt: widget.user.createdAt,
    );

    try {
      await _userService.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil erfolgreich gespeichert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Ändert das Passwort über Firebase
  void _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      await _authService.updatePassword(_newPasswordController.text.trim());
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwort erfolgreich geändert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Ändern des Passworts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  /// Erstellt den Kachel-Eintrag für die ThemeMode-Auswahl
  Widget _buildThemeDropdownTile(ThemeMode currentMode) {
    final ThemeService themeService = ThemeService();

    return ListTile(
      leading: Icon(
        currentMode == ThemeMode.dark
            ? Icons.dark_mode
            : (currentMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.settings_brightness),
        color: Colors.deepOrange,
      ),
      title: const Text('Design-Modus'),
      trailing: DropdownButton<ThemeMode>(
        value: currentMode,
        underline: const SizedBox(),
        onChanged: (newMode) async {
          if (newMode != null) {
            // 1. Live im UI umschalten
            themeModeNotifier.value = newMode;
            // 2. Lokal auf dem Gerät dauerhaft speichern
            await themeService.saveThemeMode(newMode);
          }
        },
        items: const [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('System-Standard'),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text('Helles Design'),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text('Dunkles Design (Darkmode)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _calculateLoyaltyBadge(widget.user.createdAt);
    final dateFormatted =
        '${widget.user.createdAt.day}.${widget.user.createdAt.month}.${widget.user.createdAt.year}';

    final previewUser = AppUser(
      uid: widget.user.uid,
      name: _nameController.text.isNotEmpty ? _nameController.text : widget.user.name,
      email: widget.user.email,
      role: widget.user.role,
      isTrainer: widget.user.isTrainer,
      avatarUrl: _currentAvatarUrl,
      createdAt: widget.user.createdAt,
    );

    // KEIN Scaffold und KEINE innere AppBar mehr!
    // Stattdessen wird der Scroll-Inhalt direkt an den MainScreen übergeben.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KOPFBEREICH & AVATAR
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      UserAvatarWidget(
                        user: previewUser,
                        radius: 36,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showAvatarEditDialog,
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.deepOrange,
                            child: Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.user.email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: 'Registriert am $dateFormatted',
                          waitDuration: const Duration(milliseconds: 200),
                          child: Chip(
                            avatar: Icon(
                              badge['icon'] as IconData,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              badge['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: badge['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ERSCHEINUNGSBILD
          const Text(
            'Erscheinungsbild',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, currentMode, child) {
                  return _buildThemeDropdownTile(currentMode);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // STAMMDATEN & EQUIPMENT
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stammdaten & Verein',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vollständiger Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Bitte Name eingeben' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _clubController,
                        decoration: const InputDecoration(
                          labelText: 'Verein',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _teamController,
                        decoration: const InputDecoration(
                          labelText: 'Team (z. B. Team A)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mein Darts-Equipment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dartsController,
                  decoration: const InputDecoration(
                    labelText: 'Darts (z. B. Target Swiss Point 23g)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.gps_fixed),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _boardController,
                  decoration: const InputDecoration(
                    labelText: 'Dartboard (z. B. Winmau Blade 6)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.adjust),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _autodartsController,
                  decoration: const InputDecoration(
                    labelText: 'Scolia/Autodarts Username (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.videocam_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Profil speichern'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // PASSWORT ÄNDERN
          const Text(
            'Sicherheit & Passwort',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Neues Passwort',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) => val != null && val.length < 6
                      ? 'Mindestens 6 Zeichen erforderlich'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Neues Passwort wiederholen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (val) {
                    if (val != _newPasswordController.text) {
                      return 'Passwörter stimmen nicht überein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _isChangingPassword
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.security),
                        label: const Text('Passwort ändern'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}