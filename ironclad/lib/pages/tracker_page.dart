import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final List<String> _exerciseOptions = [
    'Squat',
    'Hip Thrust',
    'Step Ups',
    'Deadlift',
    'Romanian Deadlift',
    'Bench Press',
    'Overhead Press',
    'Dumbbell Overhead Press',
    'Pull-Ups',
    'Pull-Downs',
    'Standing Row',
    'Dumbbell Row',
  ];

  final List<ExerciseEntry> _exercises = [];

  bool get _canLogWorkout {
    for (final exercise in _exercises) {
      for (final set in exercise.sets) {
        if (set.weightController.text.trim().isNotEmpty &&
            set.repsController.text.trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  void _addExercise() {
    setState(() {
      final newExercise = ExerciseEntry(onChanged: _onFieldChanged);
      _exercises.add(newExercise);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  void _onFieldChanged() {
    setState(() {}); // Recalculate _canLogWorkout
  }

  Future<void> _logWorkout() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final workout = {
      'date': formattedDate,
      'exercises': _exercises.map((e) => e.toJson()).toList(),
    };

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('workoutLogs') ?? [];
    existing.insert(0, json.encode(workout));
    await prefs.setStringList('workoutLogs', existing);

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 24;

    return Scaffold(
      appBar: AppBar(title: const Text('Current Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            if (_exercises.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ),

            const SizedBox(height: 8),

            ..._exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;

              return Column(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: exercise.selectedExercise,
                                  hint: const Text('Select Exercise'),
                                  onChanged: (value) {
                                    setState(() {
                                      exercise.selectedExercise = value;
                                    });
                                  },
                                  items: _exerciseOptions.map((e) {
                                    return DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    );
                                  }).toList(),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeExercise(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...exercise.sets.asMap().entries.map((setEntry) {
                            final i = setEntry.key;
                            final set = setEntry.value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Text('Set ${i + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: set.weightController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _onFieldChanged(),
                                      decoration: const InputDecoration(
                                        labelText: 'Weight',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: set.repsController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _onFieldChanged(),
                                      decoration: const InputDecoration(
                                        labelText: 'Reps',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        exercise.removeSet(i);
                                      });
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  exercise.addSet();
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Set'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),

            if (_exercises.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                  if (_canLogWorkout)
                    ElevatedButton.icon(
                      onPressed: _logWorkout,
                      icon: const Icon(Icons.save),
                      label: const Text('Log Workout'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),

            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

class ExerciseEntry {
  String? selectedExercise;
  final List<ExerciseSet> sets = [];
  final VoidCallback? onChanged;

  ExerciseEntry({this.onChanged}) {
    addSet();
  }

  void addSet() {
    final set = ExerciseSet();
    set.weightController.addListener(_handleChange);
    set.repsController.addListener(_handleChange);
    sets.add(set);
  }

  void removeSet(int index) {
    sets[index].dispose();
    sets.removeAt(index);
  }

  void _handleChange() {
    if (onChanged != null) onChanged!();
  }

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }

  Map<String, dynamic> toJson() => {
        'name': selectedExercise,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}

class ExerciseSet {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  Map<String, dynamic> toJson() => {
        'weight': weightController.text.trim(),
        'reps': repsController.text.trim(),
      };

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}
