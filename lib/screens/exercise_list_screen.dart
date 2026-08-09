import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/tag_model.dart';
import '../services/exercise_service.dart';
import '../services/tag_service.dart';
import 'tag_management_screen.dart';

/// Verwaltung der Übungen inklusive Tag-Zuweisung und Button zur Tag-Verwaltung
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final TagService _tagService = TagService();

  void _showExerciseDialog({Exercise? exercise}) {
    final titleController = TextEditingController(text: exercise?.title ?? '');
    final descController = TextEditingController(text: exercise?.description ?? '');
    MetricType selectedMetric = exercise?.metricType ?? MetricType.score;
    List<String> selectedTagIds = List.from(exercise?.tagIds ?? []);

    final isEditing = exercise != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Übung bearbeiten' : 'Neue Übung anlegen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titel der Übung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung / Anleitung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MetricType>(
                      value: selectedMetric,
                      decoration: const InputDecoration(
                        labelText: 'Erfassungs-Typ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: MetricType.score,
                          child: Text('Punkte / Score'),
                        ),
                        DropdownMenuItem(
                          value: MetricType.hitsAndAttempts,
                          child: Text('Treffer / Versuche'),
                        ),
                        DropdownMenuItem(
                          value: MetricType.timeInSeconds,
                          child: Text('Zeit in Sekunden'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedMetric = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Tags zuweisen:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // STREAM DER VERFÜGBAREN TAGS
                    StreamBuilder<List<ExerciseTag>>(
                      stream: _tagService.getTags(),
                      builder: (context, snapshot) {
                        final availableTags = snapshot.data ?? [];
                        if (availableTags.isEmpty) {
                          return const Text(
                            'Keine Tags vorhanden.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          );
                        }

                        return Wrap(
                          spacing: 6,
                          children: availableTags.map((tag) {
                            final isSelected = selectedTagIds.contains(tag.id);
                            return FilterChip(
                              label: Text(tag.name),
                              selected: isSelected,
                              selectedColor: tag.color.withOpacity(0.3),
                              checkmarkColor: tag.color,
                              avatar: CircleAvatar(
                                backgroundColor: tag.color,
                                radius: 6,
                              ),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedTagIds.add(tag.id);
                                  } else {
                                    selectedTagIds.remove(tag.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;

                    final newExercise = Exercise(
                      id: isEditing ? exercise.id : '',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      metricType: selectedMetric,
                      tagIds: selectedTagIds,
                    );

                    if (isEditing) {
                      await _exerciseService.updateExercise(newExercise);
                    } else {
                      await _exerciseService.createExercise(newExercise);
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Speichern' : 'Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übungen verwalten'),
        actions: [
          // BUTTON ZUR TAG-VERWALTUNG
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: 'Tags verwalten',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TagManagementScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neue Übung anlegen',
            onPressed: () => _showExerciseDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<ExerciseTag>>(
        stream: _tagService.getTags(),
        builder: (context, tagSnapshot) {
          final tags = tagSnapshot.data ?? [];

          return StreamBuilder<List<Exercise>>(
            stream: _exerciseService.getExercises(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final exercises = snapshot.data ?? [];

              if (exercises.isEmpty) {
                return const Center(
                  child: Text('Noch keine Übungen angelegt.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  final assignedTags =
                      tags.where((t) => ex.tagIds.contains(t.id)).toList();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.description),
                          const SizedBox(height: 4),
                          if (assignedTags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: assignedTags.map((t) {
                                return Chip(
                                  label: Text(t.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: t.color,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showExerciseDialog(exercise: ex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _exerciseService.deleteExercise(ex.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}