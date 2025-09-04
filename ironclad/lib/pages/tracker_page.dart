// tracker_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:ironclad/widgets/exercise_entry_widget.dart';
import 'package:ironclad/models/workout_template.dart';
import 'package:ironclad/utils/template_manager.dart';
import 'package:ironclad/pages/edit_template_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _addExercise();
  }

  Future<void> _loadTemplates() async {
    final templates = await TemplateManager.loadTemplates();
    setState(() {
      _templates = templates;
    });
  }

  void _onFieldChanged() {
    setState(() {});
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

  void _clearWorkout() {
    setState(() {
      for (final e in _exercises) {
        e.dispose();
      }
      _exercises.clear();
      _addExercise();
      _selectedTemplateName = 'Custom Workout';
    });
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Workout?'),
        content: const Text('This will clear your current workout. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirm == true) {
      _clearWorkout();
    }
  }

  Future<void> _saveAsTemplate() async {
    final templateNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: templateNameController,
          decoration: const InputDecoration(labelText: 'Template Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final name = templateNameController.text.trim();
              if (name.isEmpty) return;
              final newTemplate = WorkoutTemplate(
                name: name,
                exercises: _exercises.map((e) => {
                  'name': e.selectedExercise ?? '',
                  'sets': e.sets.length,
                }).toList(),
              );
              await TemplateManager.saveTemplate(newTemplate);
              Navigator.pop(context);
              await _loadTemplates();
              setState(() => _selectedTemplateName = name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(WorkoutTemplate template) {
    setState(() {
      for (final e in _exercises) {
        e.dispose();
      }
      _exercises.clear();

      for (final ex in template.exercises) {
        final entry = ExerciseEntry(onChanged: _onFieldChanged);
        entry.selectedExercise = ex['name'];
        entry.sets.clear();
        final int setCount = ex['sets'] ?? 1;
        for (int i = 0; i < setCount; i++) {
          final set = ExerciseSet();
          set.weightController.addListener(entry.handleChange);
          set.repsController.addListener(entry.handleChange);
          entry.sets.add(set);
        }
        _exercises.add(entry);
      }

      _selectedTemplateName = template.name;
    });
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

  void _editTemplate(String templateName) async {
    final template = _templates.firstWhere((t) => t.name == templateName);
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTemplatePage(template: template)),
    );
    if (updated == true) {
      _loadTemplates();
    }
  }

  void _deleteTemplate(String templateName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "$templateName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await TemplateManager.deleteTemplate(templateName);
      _loadTemplates();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTemplateName,
                      onChanged: (value) {
                        if (value == null || value == 'Custom Workout') {
                          _clearWorkout();
                        } else {
                          final selected = _templates.firstWhere((t) => t.name == value);
                          _applyTemplate(selected);
                        }
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'Custom Workout',
                          child: Text('Custom Workout'),
                        ),
                        ..._templates.map(
                          (t) => DropdownMenuItem(
                            value: t.name,
                            child: Text(t.name),
                          ),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Workout Template',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value.startsWith('edit:')) {
                        _editTemplate(value.substring(5));
                      } else if (value.startsWith('delete:')) {
                        _deleteTemplate(value.substring(7));
                      }
                    },
                    itemBuilder: (context) => _templates
                        .map((t) => PopupMenuItem<String>(
                              value: 'edit:${t.name}',
                              child: Text('Edit: ${t.name}'),
                            ))
                        .followedBy(
                          _templates.map((t) => PopupMenuItem<String>(
                                value: 'delete:${t.name}',
                                child: Text('Delete: ${t.name}'),
                              )),
                        )
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
              Row(
                mainAxisAlignment:
                    _canLogWorkout ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
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
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_exercises.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _confirmClear,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Workout'),
                    ),
                    if (_selectedTemplateName == 'Custom Workout')
                      TextButton.icon(
                        onPressed: _saveAsTemplate,
                        icon: const Icon(Icons.save_as),
                        label: const Text('Save as Template'),
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
