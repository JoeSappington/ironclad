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
  bool _calendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

  List<_WorkoutWithIndex> _getWorkoutsForDay(DateTime day) {
    return _workouts.where((w) {
      final date = DateTime.tryParse(w.data['date'] ?? '');
      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  bool _hasWorkoutOnDay(DateTime day) {
    return _getWorkoutsForDay(day).isNotEmpty;
  }

  Future<void> _deleteWorkout(int sortedIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('workoutLogs') ?? [];

      final originalIndex = _workouts[sortedIndex].index;

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

  Future<void> _goToEditWorkoutPage(int sortedIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('workoutLogs') ?? [];

    final originalIndex = _workouts[sortedIndex].index;

    if (originalIndex < jsonList.length) {
      final workoutData = json.decode(jsonList[originalIndex]) as Map<String, dynamic>;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddWorkoutPage(existingWorkout: workoutData, workoutIndex: originalIndex),
        ),
      );

      if (result == true) {
        _modified = true;
        await _loadWorkoutLogs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarWorkouts = _getWorkoutsForDay(_selectedDay!);

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
              icon: Icon(_calendarView ? Icons.list : Icons.calendar_today),
              tooltip: _calendarView ? 'Show List View' : 'Show Calendar View',
              onPressed: () {
                setState(() {
                  _calendarView = !_calendarView;
                });
              },
            ),
          ],
        ),
        body: _workouts.isEmpty
            ? const Center(child: Text('No workouts logged yet.'))
            : _calendarView
                ? Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(day, _selectedDay),
                        onDaySelected: (selectedDay, focusedDay) {
                          if (selectedDay.isAfter(DateTime.now())) return;
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 2),
                          ),
                          outsideDaysVisible: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, _) {
                            if (_hasWorkoutOnDay(day)) {
                              return Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: calendarWorkouts.isEmpty
                            ? const Center(child: Text('No workouts for this day.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: calendarWorkouts.length,
                                itemBuilder: (context, index) {
                                  final workout = calendarWorkouts[index].data;
                                  final exercises = workout['exercises'] as List<dynamic>;
                                  return _buildWorkoutCard(workout, exercises, index);
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
                      final exercises = workout['exercises'] as List<dynamic>;
                      return _buildWorkoutCard(workout, exercises, index);
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

  Widget _buildWorkoutCard(
      Map<String, dynamic> workout, List<dynamic> exercises, int index) {
    final date = workout['date'] ?? 'Unknown Date';

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
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Workout',
                  onPressed: () => _goToEditWorkoutPage(index),
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
  }
}

class _WorkoutWithIndex {
  final int index;
  final Map<String, dynamic> data;

  _WorkoutWithIndex({required this.index, required this.data});
}
