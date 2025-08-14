import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddWorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? existingWorkout;
  final int? workoutIndex;

  const AddWorkoutPage({super.key, this.existingWorkout, this.workoutIndex});

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
      if (exercise.selectedExercise == null || exercise.selectedExercise!.isEmpty) continue;
      for (final set in exercise.sets) {
        if (set.weightController.text.trim().isNotEmpty &&
            set.repsController.text.trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    if (widget.existingWorkout != null) {
      final dateStr = widget.existingWorkout!['date'];
      _selectedDateTime = DateTime.tryParse(dateStr) ?? DateTime.now();

      final exercises = widget.existingWorkout!['exercises'] as List<dynamic>;
      for (final e in exercises) {
        final entry = ExerciseEntry(onChanged: _onFieldChanged);
        entry.selectedExercise = e['name'];
        for (final s in e['sets']) {
          final set = ExerciseSet();
          set.weightController.text = s['weight'] ?? '';
          set.repsController.text = s['reps'] ?? '';
          set.weightController.addListener(entry._handleChange);
          set.repsController.addListener(entry._handleChange);
          entry.sets.add(set);
        }
        _exercises.add(entry);
      }
    }
  }

  void _onFieldChanged() {
    setState(() {}); // Trigger re-evaluation
  }

  void _addExercise() {
    setState(() {
      final entry = ExerciseEntry(onChanged: _onFieldChanged);
      _exercises.add(entry);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
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

    if (widget.workoutIndex != null &&
        widget.workoutIndex! >= 0 &&
        widget.workoutIndex! < existing.length) {
      existing[widget.workoutIndex!] = json.encode(workout);
    } else {
      existing.insert(0, json.encode(workout));
    }

    await prefs.setStringList('workoutLogs', existing);

    Navigator.pop(context, true); // Return to previous page
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
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🗓️ Date/Time Selector
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
                            }).toList(),

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
                  mainAxisAlignment: _canSaveWorkout
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
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
                      ),
                  ],
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ExerciseEntry and ExerciseSet

class ExerciseEntry {
  String? selectedExercise;
  final List<ExerciseSet> sets = [];
  final VoidCallback? onChanged;

  ExerciseEntry({this.onChanged});

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
