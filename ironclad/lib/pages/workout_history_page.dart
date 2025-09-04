// UPDATED: workout_history_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'add_workout_page.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<_WorkoutWithIndex> _workouts = [];
  bool _modified = false;
  bool _showCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWorkoutLogs();
  }

  Future<void> _loadWorkoutLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('workoutLogs') ?? [];

    final parsed = jsonList.asMap().entries.map((entry) {
      final originalIndex = entry.key;
      final data = json.decode(entry.value) as Map<String, dynamic>;
      return _WorkoutWithIndex(index: originalIndex, data: data);
    }).toList();

    parsed.sort((a, b) {
      final dateA = DateTime.tryParse(a.data['date'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.data['date'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _workouts = parsed;
    });
  }

  Future<void> _deleteWorkout(int originalIndex) async {
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

      if (originalIndex < jsonList.length) {
        jsonList.removeAt(originalIndex);
        await prefs.setStringList('workoutLogs', jsonList);
        _modified = true;
        await _loadWorkoutLogs();
      }
    }
  }

  Future<void> _goToAddWorkoutPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWorkoutPage()),
    );
    if (result == true) {
      _modified = true;
      await _loadWorkoutLogs();
    }
  }

  Future<void> _goToEditWorkoutPage(int originalIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('workoutLogs') ?? [];

    if (originalIndex < jsonList.length) {
      final workoutData = json.decode(jsonList[originalIndex]) as Map<String, dynamic>;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddWorkoutPage(
            existingWorkout: workoutData,
            workoutIndex: originalIndex,
          ),
        ),
      );

      if (result == true) {
        _modified = true;
        await _loadWorkoutLogs();
      }
    }
  }

  List<_WorkoutWithIndex> _getWorkoutsForDay(DateTime day) {
    return _workouts.where((w) {
      final date = DateTime.tryParse(w.data['date'] ?? '');
      return date != null && date.year == day.year && date.month == day.month && date.day == day.day;
    }).toList();
  }

  Set<DateTime> _getWorkoutDays() {
    return _workouts.map((w) {
      final d = DateTime.tryParse(w.data['date'] ?? '') ?? DateTime(2000);
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final workoutDays = _getWorkoutDays();
    final selectedWorkouts = _getWorkoutsForDay(_selectedDay);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _modified);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout History'),
          actions: [
            IconButton(
              icon: Icon(_showCalendarView ? Icons.list : Icons.calendar_month),
              tooltip: 'Toggle View',
              onPressed: () {
                setState(() => _showCalendarView = !_showCalendarView);
              },
            ),
          ],
        ),
        body: _workouts.isEmpty
            ? const Center(child: Text('No workouts logged yet.'))
            : _showCalendarView
                ? Column(
                    children: [
                      TableCalendar(
                        focusedDay: _focusedDay,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 1, 1),
                        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                        onDaySelected: (selected, focused) {
                          if (!selected.isAfter(DateTime.now())) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                          }
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final hasWorkout = workoutDays.contains(DateTime(date.year, date.month, date.day));
                            return hasWorkout
                                ? const Positioned(
                                    bottom: 1,
                                    child: Icon(Icons.fitness_center, size: 12, color: Colors.green),
                                  )
                                : null;
                          },
                        ),
                      ),
                      Expanded(
                        child: selectedWorkouts.isEmpty
                            ? const Center(child: Text('No workouts for this day.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: selectedWorkouts.length,
                                itemBuilder: (context, index) {
                                  final workout = selectedWorkouts[index].data;
                                  final originalIndex = selectedWorkouts[index].index;
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
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                tooltip: 'Edit Workout',
                                                onPressed: () => _goToEditWorkoutPage(originalIndex),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                tooltip: 'Delete Workout',
                                                onPressed: () => _deleteWorkout(originalIndex),
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
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontSize: 15, fontWeight: FontWeight.w600)),
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
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index].data;
                      final originalIndex = _workouts[index].index;
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
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Workout',
                                    onPressed: () => _goToEditWorkoutPage(originalIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Workout',
                                    onPressed: () => _deleteWorkout(originalIndex),
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
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}

class _WorkoutWithIndex {
  final int index;
  final Map<String, dynamic> data;
  _WorkoutWithIndex({required this.index, required this.data});
}
