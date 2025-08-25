import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:ironclad/widgets/exercise_entry_widget.dart';
import 'package:ironclad/utils/template_manager.dart';
import 'package:ironclad/models/workout_template.dart';

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
  List<WorkoutTemplate> _templates = [];
  String _selectedTemplateName = 'Custom Workout';

  bool get _canLogWorkout {
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

  bool get _canSaveTemplate {
    return _selectedTemplateName == 'Custom Workout' && _exercises.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _addExercise(); // Preload first block
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final loaded = await TemplateManager.loadTemplates();
    setState(() {
      _templates = loaded;
    });
  }

  void _applyTemplate(WorkoutTemplate template) {
    setState(() {
      // Clean up old ones
      for (final e in _exercises) {
        e.dispose();
      }
      _exercises.clear();

      // Add from template
      for (final ex in template.exercises) {
        final entry = ExerciseEntry(onChanged: _onFieldChanged);
        entry.selectedExercise = ex['name'];
        for (final set in ex['sets']) {
          final newSet = ExerciseSet();
          newSet.weightController.text = set['weight'] ?? '';
          newSet.repsController.text = set['reps'] ?? '';
          newSet.weightController.addListener(entry.handleChange);
          newSet.repsController.addListener(entry.handleChange);
          entry.sets.add(newSet);
        }
        _exercises.add(entry);
      }

      _selectedTemplateName = template.name;
    });
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

  Future<void> _logWorkout() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

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

  Future<void> _saveAsTemplate() async {
    final templateNameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: templateNameController,
          decoration: const InputDecoration(labelText: 'Template Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true && templateNameController.text.trim().isNotEmpty) {
      final newTemplate = WorkoutTemplate(
        name: templateNameController.text.trim(),
        exercises: _exercises.map((e) => e.toJson()).toList(),
      );
      await TemplateManager.saveTemplate(newTemplate);
      await _loadTemplates();

      setState(() {
        _selectedTemplateName = newTemplate.name;
      });
    }
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 24;

    return Scaffold(
      appBar: AppBar(title: const Text('Current Workout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 🔽 Template dropdown
              Row(
                children: [
                  const Text('Workout Template:'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedTemplateName,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value == 'Custom Workout') {
                          setState(() {
                            _selectedTemplateName = value!;
                          });
                          return;
                        }

                        final template = _templates.firstWhere(
                            (t) => t.name == value,
                            orElse: () => WorkoutTemplate(name: '', exercises: []));
                        _applyTemplate(template);
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'Custom Workout',
                          child: Text('Custom Workout'),
                        ),
                        ..._templates.map((t) => DropdownMenuItem(
                              value: t.name,
                              child: Text(t.name),
                            )),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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

              if (_exercises.isEmpty)
                ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),

              if (_exercises.isNotEmpty)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: _canLogWorkout
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                        ),
                        if (_canLogWorkout)
                          ElevatedButton.icon(
                            onPressed: _logWorkout,
                            icon: const Icon(Icons.save),
                            label: const Text('Log Workout'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (_canSaveTemplate)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          onPressed: _saveAsTemplate,
                          icon: const Icon(Icons.bookmark_add),
                          label: const Text('Save as Template'),
                        ),
                      ),
                  ],
                ),

              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
