import 'package:flutter/material.dart';
import 'package:ironclad/pages/tracker_page.dart';
import 'package:ironclad/pages/workout_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ironclad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ironclad Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int workoutStreak = 0;

  @override
  void initState() {
    super.initState();
    _calculateWorkoutStreak();
  }

  Future<void> _calculateWorkoutStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('workoutLogs') ?? [];

    final dates = logs.map((entry) {
      final map = json.decode(entry) as Map<String, dynamic>;
      final dateStr = map['date'] ?? '';
      return DateTime.tryParse(dateStr)?.toLocal();
    }).whereType<DateTime>().toList();

    dates.sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final streakDate = today.subtract(Duration(days: streak));
      if (_isSameDay(date, streakDate)) {
        streak++;
      } else if (date.isBefore(streakDate)) {
        break;
      }
    }

    setState(() {
      workoutStreak = streak;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _goToTrackerPage() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackerPage()),
    );
    if (updated == true) {
      _calculateWorkoutStreak();
    }
  }

  Future<void> _goToWorkoutHistoryPage() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutHistoryPage()),
    );
    if (updated == true) {
      _calculateWorkoutStreak();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔥 Streak Tracker
            Card(
              color: Colors.deepPurple.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    Text(
                      '🔥 Workout Streak: $workoutStreak day${workoutStreak == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🏋️ Begin Workout Button
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _goToTrackerPage,
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Begin Workout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _goToWorkoutHistoryPage,
                    icon: const Icon(Icons.history),
                    label: const Text('View Workout History'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
