import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';
import 'exercise_history_screen.dart';
import 'performance_test_detail_stats_screen.dart';

/// Zentrale Statistik-Übersichtsseite für einen einzelnen Spieler.
/// Kann sowohl vom Trainer als auch vom Spieler selbst aufgerufen werden.
/// Enthält im Tab "Übungs-Historie" ein Suchfeld zum Filtern nach Übungstiteln.
class PlayerStatsOverviewScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const PlayerStatsOverviewScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<PlayerStatsOverviewScreen> createState() =>
      _PlayerStatsOverviewScreenState();
}

class _PlayerStatsOverviewScreenState
    extends State<PlayerStatsOverviewScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Echtzeit-Listener: Bei jedem Tastendruck wird der Filter aktualisiert
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    // Speicher freigeben, wenn der Screen verlassen wird
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Statistiken: ${widget.playerName}'),
          bottom: const TabBar(
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: 'Übungs-Historie',
                icon: Icon(Icons.show_chart),
              ),
              Tab(
                text: 'Leistungstests',
                icon: Icon(Icons.assignment_turned_in),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: ÜBUNGS-HISTORIE & TRENDS (mit Textsuche)
            Column(
              children: [
                // 1. SUCHLEISTE
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Übungen durchsuchen...',
                      hintText: 'Titel oder Beschreibung',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.deepOrange,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.deepOrange,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // 2. GEFILTERTE ÜBUNGSLISTE
                Expanded(
                  child: StreamBuilder<List<Exercise>>(
                    stream: _exerciseService.getExercises(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepOrange,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Fehler beim Laden der Übungen: ${snapshot.error}',
                          ),
                        );
                      }

                      final allExercises = snapshot.data ?? [];

                      // FILTER-LOGIK: Prüft, ob Suchtext in Titel oder Beschreibung vorkommt
                      final filteredExercises = allExercises.where((exercise) {
                        final titleMatch = exercise.title
                            .toLowerCase()
                            .contains(_searchQuery);
                        final descMatch = exercise.description
                            .toLowerCase()
                            .contains(_searchQuery);
                        return titleMatch || descMatch;
                      }).toList();

                      // Wenn kein Ergebnis gefunden wurde
                      if (filteredExercises.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.fitness_center
                                    : Icons.search_off,
                                size: 56,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Noch keine Übungen im System vorhanden.'
                                    : 'Keine Übung für "$_searchQuery" gefunden.',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.deepOrange,
                                child: Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                exercise.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                exercise.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseHistoryScreen(
                                      exercise: exercise,
                                      playerId: widget.playerId,
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
            ),

            // TAB 2: LEISTUNGSTEST-DETAILSTATISTIKEN
            PerformanceTestDetailStatsScreen(
              playerId: widget.playerId,
              playerName: widget.playerName,
            ),
          ],
        ),
      ),
    );
  }
}