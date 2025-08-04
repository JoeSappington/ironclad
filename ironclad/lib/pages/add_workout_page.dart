import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage({super.key});

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  DateTime selectedDate = DateTime.now();
  final List<String> exerciseOptions = [
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

  final List<ManualExerciseEntry> exercises = [];

  void _addExercise() {
    setState(() {
      exercises.add(ManualExerciseEntry());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      exercises[index].dispose();
      exercises.removeAt(index);
    });
  }

  void _saveWorkout() async {
    if (exercises.any((e) => e.selectedExercise == null || e.sets.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each exercise must have a name and at least one set')),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final workout = {
      'date': formattedDate,
      'exercises': exercises.map((e) => {
            'name': e.selectedExercise,
            'sets': e.sets.map((s) => {
                  'weight': s.weightController.text,
                  'reps': s.repsController.text,
                }).toList(),
          }).toList(),
    };

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('workoutLogs') ?? [];

    existing.insert(0, json.encode(workout));
    await prefs.setStringList('workoutLogs', existing.take(50).toList());

    Navigator.pop(context, true);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    for (final e in exercises) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Date:'),
                const SizedBox(width: 12),
                Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectDate,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
            const SizedBox(height: 20),
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 12),
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
                              items: exerciseOptions.map((e) {
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
                            tooltip: 'Remove Exercise',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...exercise.sets.asMap().entries.map((setEntry) {
                        final setIndex = setEntry.key;
                        final set = setEntry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set ${setIndex + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: set.weightController,
                                  keyboardType: TextInputType.number,
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
                                    exercise.removeSet(setIndex);
                                  });
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remove Set',
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            exercise.addSet();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Set'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: exercises.isEmpty ? null : _saveWorkout,
              child: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper classes
class ManualExerciseEntry {
  String? selectedExercise;
  final List<ExerciseSet> sets = [];

  void addSet() {
    sets.add(ExerciseSet());
  }

  void removeSet(int index) {
    sets[index].dispose();
    sets.removeAt(index);
  }

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class ExerciseSet {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}
