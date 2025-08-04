import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_workout_page.dart'; // You'll need to create this file

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkoutLogs();
  }

  Future<void> _loadWorkoutLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('workoutLogs') ?? [];

    final parsed = jsonList
        .map((e) => json.decode(e) as Map<String, dynamic>)
        .toList();

    setState(() {
      _workouts = parsed;
    });
  }

  Future<void> _deleteWorkout(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('workoutLogs') ?? [];

      jsonList.removeAt(index);
      await prefs.setStringList('workoutLogs', jsonList);

      setState(() {
        _workouts.removeAt(index);
      });
    }
  }

  Future<void> _goToAddWorkoutPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWorkoutPage()),
    );
    if (result == true) {
      _loadWorkoutLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: _workouts.isEmpty
          ? const Center(child: Text('No workouts logged yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final workout = _workouts[index];
                final date = workout['date'] ?? 'Unknown Date';
                final exercises = workout['exercises'] as List<dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Workout',
                              onPressed: () => _deleteWorkout(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...exercises.map((e) {
                          final name = e['name'];
                          final sets = e['sets'] as List<dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ...sets.asMap().entries.map((entry) {
                                final i = entry.key + 1;
                                final set = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Text(
                                    'Set $i: ${set['weight']} lbs × ${set['reps']} reps',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddWorkoutPage,
        child: const Icon(Icons.add),
        tooltip: 'Add Workout',
      ),
    );
  }
}
