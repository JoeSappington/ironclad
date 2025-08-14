import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/exercise_entry_widget.dart';

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
          set.weightController.addListener(entry.handleChange);
          set.repsController.addListener(entry.handleChange);
          entry.sets.add(set);
        }
        _exercises.add(entry);
      }
    }
  }

  void _onFieldChanged() {
    setState(() {});
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
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime);

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
    final displayDate = DateFormat('MMM d, yyyy – h:mm a').format(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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

                return ExerciseEntryWidget(
                  entry: exercise,
                  index: index,
                  exerciseOptions: _exerciseOptions,
                  onRemove: () => _removeExercise(index),
                  onAddSet: () {
                    setState(() {
                      exercise.addSet();
                    });
                  },
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
