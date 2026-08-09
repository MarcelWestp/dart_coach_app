import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/weekly_plan_model.dart';
import '../../models/tag_model.dart';
import '../../services/plan_service.dart';
import '../../services/tag_service.dart';

/// Ein eigenständiger Dialog zum Bearbeiten der zugewiesenen Übungen und Vorgaben
/// für einen konkreten Wochentag im Trainingsplan.
class EditDayScheduleDialog extends StatefulWidget {
  final TrainingPlan currentPlan;
  final String dayName;
  final List<Exercise> availableExercises;
  final int weekNumber;
  final String targetPlayerId;
  final List<String> daysOfWeek;

  const EditDayScheduleDialog({
    super.key,
    required this.currentPlan,
    required this.dayName,
    required this.availableExercises,
    required this.weekNumber,
    required this.targetPlayerId,
    required this.daysOfWeek,
  });

  @override
  State<EditDayScheduleDialog> createState() => _EditDayScheduleDialogState();
}

class _EditDayScheduleDialogState extends State<EditDayScheduleDialog> {
  final PlanService _planService = PlanService();
  final TagService _tagService = TagService();

  late Map<String, ScheduledExercise> _selectedMap;
  String? _selectedFilterTagId;

  @override
  void initState() {
    super.initState();
    // Laden des bestehenden Tagesplans für den aktuellen Tag
    final daySchedule = widget.currentPlan.days.firstWhere(
      (d) => d.dayOfWeek == widget.dayName,
      orElse: () => DailySchedule(
        dayOfWeek: widget.dayName,
        scheduledExercises: [],
      ),
    );

    // Initialisieren der lokalen Map für schnelle Updates während der Auswahl
    _selectedMap = {
      for (var se in daySchedule.scheduledExercises) se.exerciseId: se,
    };
  }

  /// Speichert den aktualisierten Trainingsplan in Firestore
  Future<void> _saveSchedule() async {
    final updatedDays = widget.daysOfWeek.map((day) {
      if (day == widget.dayName) {
        return DailySchedule(
          dayOfWeek: day,
          scheduledExercises: _selectedMap.values.toList(),
        );
      }
      return widget.currentPlan.days.firstWhere(
        (d) => d.dayOfWeek == day,
        orElse: () => DailySchedule(
          dayOfWeek: day,
          scheduledExercises: [],
        ),
      );
    }).toList();

    final updatedPlan = TrainingPlan(
      id: widget.currentPlan.id,
      title: widget.currentPlan.title,
      playerId: widget.targetPlayerId,
      trainerId: widget.currentPlan.trainerId,
      year: widget.currentPlan.year,
      weekNumber: widget.weekNumber,
      days: updatedDays,
    );

    await _planService.saveTrainingPlan(updatedPlan);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExerciseTag>>(
      stream: _tagService.getTags(),
      builder: (context, tagSnapshot) {
        final tags = tagSnapshot.data ?? [];

        // Übungen basierend auf ausgewähltem Tag filtern
        final filteredExercises = _selectedFilterTagId == null
            ? widget.availableExercises
            : widget.availableExercises
                .where((e) => e.tagIds.contains(_selectedFilterTagId))
                .toList();

        return AlertDialog(
          title: Text(
            'Übungen für ${widget.dayName} (KW ${widget.weekNumber})',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TAG-FILTER HINWEISE / CHIPS ---
                  if (tags.isNotEmpty) ...[
                    const Text(
                      'Nach Tag filtern:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Alle'),
                            selected: _selectedFilterTagId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFilterTagId = null);
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          ...tags.map((tag) {
                            final isSelected = _selectedFilterTagId == tag.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(tag.name),
                                selected: isSelected,
                                selectedColor: tag.color.withOpacity(0.3),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilterTagId =
                                        selected ? tag.id : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],

                  // --- ÜBUNGSLISTE MIT STAMMDATEN-VORBEFÜLLUNG ---
                  ...filteredExercises.map((ex) {
                    final isSelected = _selectedMap.containsKey(ex.id);

                    final currentScheduled = _selectedMap[ex.id] ??
                        ScheduledExercise(
                          exerciseId: ex.id,
                          targetType: ex.defaultTargetType,
                          targetValue: ex.defaultTargetValue,
                        );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: isSelected ? 2 : 0,
                      color: isSelected ? Colors.deepOrange.shade50 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              title: Text(
                                ex.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                ex.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: isSelected,
                              activeColor: Colors.deepOrange,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    // Beim Auswählen werden direkt die Standardwerte übernommen
                                    _selectedMap[ex.id] = ScheduledExercise(
                                      exerciseId: ex.id,
                                      targetType: ex.defaultTargetType,
                                      targetValue: ex.defaultTargetValue,
                                    );
                                  } else {
                                    _selectedMap.remove(ex.id);
                                  }
                                });
                              },
                            ),

                            // --- OPTIONEN FÜR AUSGEWÄHLTE ÜBUNG ---
                            if (isSelected) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    // DROPDOWN VORGABE-TYP
                                    DropdownButton<TargetType>(
                                      value: currentScheduled.targetType,
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(
                                          value: TargetType.none,
                                          child: Text('Ohne Vorgabe'),
                                        ),
                                        DropdownMenuItem(
                                          value: TargetType.duration,
                                          child: Text('⏱️ Dauer'),
                                        ),
                                        DropdownMenuItem(
                                          value: TargetType.reps,
                                          child: Text('🔁 Durchläufe'),
                                        ),
                                      ],
                                      onChanged: (newType) {
                                        if (newType != null) {
                                          setState(() {
                                            _selectedMap[ex.id] =
                                                ScheduledExercise(
                                              exerciseId: ex.id,
                                              targetType: newType,
                                              targetValue:
                                                  currentScheduled.targetValue,
                                              note: currentScheduled.note,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    // EINGABEFELD VORGABE-WERT
                                    if (currentScheduled.targetType !=
                                        TargetType.none)
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: currentScheduled.targetValue,
                                          )..selection = TextSelection.collapsed(
                                              offset: currentScheduled
                                                  .targetValue.length,
                                            ),
                                          decoration: InputDecoration(
                                            hintText: currentScheduled
                                                        .targetType ==
                                                    TargetType.duration
                                                ? 'z. B. 15 Min'
                                                : 'z. B. 10 Serien',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            border: const OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            _selectedMap[ex.id] =
                                                ScheduledExercise(
                                              exerciseId: ex.id,
                                              targetType:
                                                  currentScheduled.targetType,
                                              targetValue: val,
                                              note: currentScheduled.note,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}