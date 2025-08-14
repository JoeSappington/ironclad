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
  DateTime _selectedDateTime = DateTime.now();

  bool get _canSaveWorkout {
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
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveWorkout() async {
    final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime);

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
    final displayDate =
        DateFormat('MMM d, yyyy – h:mm a').format(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🗓️ Show selected date & time
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Workout Date: $displayDate',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _pickDateTime,
                  child: const Text('Change'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_exercises.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ),

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
                  if (_canSaveWorkout)
                    ElevatedButton.icon(
                      onPressed: _saveWorkout,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),
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
