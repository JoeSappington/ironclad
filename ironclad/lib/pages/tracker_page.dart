import 'package:flutter/material.dart';

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

  void _logWorkout() {
    final incomplete = _exercises.any((exercise) =>
        exercise.selectedExercise == null || exercise.sets.isEmpty);

    if (incomplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Make sure each exercise has a name and at least one set')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout logged!')),
    );

    setState(() {
      for (final exercise in _exercises) {
        exercise.dispose();
      }
      _exercises.clear();
    });
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
        title: const Text('Tracker Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'You can do it!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Add Exercise'),
            ),

            const SizedBox(height: 20),

            ..._exercises.asMap().entries.map((entry) {
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
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            exercise.addSet();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Set'),
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
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _exercises.isEmpty ? null : _logWorkout,
              child: const Text('Log Workout'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return Triumphantly to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper classes to track per-exercise state
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
