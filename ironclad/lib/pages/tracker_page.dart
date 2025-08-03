import 'package:flutter/material.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final List<String> _exercises = [
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

  String? _selectedExercise;

  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];

  void _addSet() {
    setState(() {
      _weightControllers.add(TextEditingController());
      _repsControllers.add(TextEditingController());
    });
  }

  void _removeSet(int index) {
    setState(() {
      _weightControllers[index].dispose();
      _repsControllers[index].dispose();
      _weightControllers.removeAt(index);
      _repsControllers.removeAt(index);
    });
  }

  void _logWorkout() {
    if (_selectedExercise == null || _weightControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an exercise and add at least one set')),
      );
      return;
    }

    // No console printing here

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout logged!')),
    );

    setState(() {
      _selectedExercise = null;
      _clearAllSets();
    });
  }

  void _clearAllSets() {
    for (var c in _weightControllers) {
      c.dispose();
    }
    for (var c in _repsControllers) {
      c.dispose();
    }
    _weightControllers.clear();
    _repsControllers.clear();
  }

  @override
  void dispose() {
    _clearAllSets();
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

            DropdownButtonFormField<String>(
              value: _selectedExercise,
              hint: const Text('Select Exercise'),
              onChanged: (value) {
                setState(() {
                  _selectedExercise = value;
                  // Sets remain when switching exercises
                });
              },
              items: _exercises.map((exercise) {
                return DropdownMenuItem(
                  value: exercise,
                  child: Text(exercise),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _selectedExercise == null ? null : _addSet,
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),

            const SizedBox(height: 20),

            ...List.generate(_weightControllers.length, (index) {
              return Dismissible(
                key: ValueKey(_weightControllers[index]),
                direction: DismissDirection.none,
                background: const SizedBox(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightControllers[index],
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
                          controller: _repsControllers[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeSet(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Set',
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _logWorkout,
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
