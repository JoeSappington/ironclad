import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void _addExercise() {
    setState(() {
      _exercises.add(ExerciseEntry());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  bool get _hasValidSet {
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

  void _logWorkout() async {
    final incomplete = _exercises.any((exercise) =>
        exercise.selectedExercise == null || exercise.sets.isEmpty);

    if (incomplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each exercise needs a name and at least one set')),
      );
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final exerciseSummaries = _exercises.map((e) {
      final sets = e.sets
          .map((s) => '${s.weightController.text}x${s.repsController.text}')
          .join(', ');
      return '${e.selectedExercise}: $sets';
    }).toList();

    final workoutSummary = '$today - ${exerciseSummaries.join(' | ')}';

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('recentWorkouts') ?? [];
    existing.insert(0, workoutSummary);
    await prefs.setStringList('recentWorkouts', existing.take(10).toList());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout logged!')),
    );

    setState(() {
      for (final exercise in _exercises) {
        exercise.dispose();
      }
      _exercises.clear();
    });

    Navigator.pop(context, true); // refresh main page
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Workout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_exercises.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Add Exercise'),
                ),
              ),

            const SizedBox(height: 20),

            ..._exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;

              return Column(
                children: [
                  Card(
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
                                      onChanged: (_) => setState(() {}),
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
                                      onChanged: (_) => setState(() {}),
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

                          const SizedBox(height: 12),
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
                  ),

                  // Show Add Exercise below the most recent one
                  if (index == _exercises.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Add Exercise'),
                      ),
                    ),
                ],
              );
            }),

            const SizedBox(height: 30),

            if (_hasValidSet)
              ElevatedButton(
                onPressed: _logWorkout,
                child: const Text('Log Workout'),
              ),
          ],
        ),
      ),
    );
  }
}

class ExerciseEntry {
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
