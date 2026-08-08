import 'package:flutter/material.dart';
import '../models/tag_model.dart';
import '../services/tag_service.dart';

/// Bildschirmoberfläche zur Verwaltung (CRUD) von Übungs-Tags durch den Trainer
class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  static const List<Color> _availableColors = [
    Colors.deepOrange,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.amber,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  void _showTagDialog(BuildContext context, TagService tagService, {ExerciseTag? existingTag}) {
    final nameController = TextEditingController(text: existingTag?.name ?? '');
    Color selectedColor = existingTag != null ? existingTag.color : _availableColors.first;
    final isEditing = existingTag != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Tag bearbeiten' : 'Neues Tag anlegen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tag-Name (z. B. Scoring, Checkout)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Farbe wählen:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availableColors.map((color) {
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final tag = ExerciseTag(
                      id: isEditing ? existingTag.id : '',
                      name: name,
                      colorValue: selectedColor.value,
                    );

                    if (isEditing) {
                      await tagService.updateTag(tag);
                    } else {
                      await tagService.createTag(tag);
                    }

                    if (context.mounted) Navigator.pop(context);
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
    final TagService tagService = TagService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags verwalten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neues Tag anlegen',
            onPressed: () => _showTagDialog(context, tagService),
          ),
        ],
      ),
      body: StreamBuilder<List<ExerciseTag>>(
        stream: tagService.getTags(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tags = snapshot.data ?? [];

          if (tags.isEmpty) {
            return const Center(
              child: Text(
                'Noch keine Tags vorhanden.\nKlicke oben auf "+", um das erste Tag anzulegen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: tag.color, radius: 14),
                  title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showTagDialog(context, tagService, existingTag: tag),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await tagService.deleteTag(tag.id);
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
    );
  }
}