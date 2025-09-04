// edit_template_page.dart
import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../utils/template_manager.dart';

class EditTemplatePage extends StatefulWidget {
  final WorkoutTemplate template;

  const EditTemplatePage({super.key, required this.template});

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  late TextEditingController _nameController;
  late List<Map<String, dynamic>> _exercises;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _exercises = List<Map<String, dynamic>>.from(widget.template.exercises);
  }

  void _addExercise() {
    setState(() {
      _exercises.add({'name': _exerciseOptions[0], 'sets': 1});
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final updatedTemplate = WorkoutTemplate(
      name: newName,
      exercises: _exercises,
    );

    await TemplateManager.updateTemplate(widget.template.name, updatedTemplate);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Template Name'),
          ),
          const SizedBox(height: 20),
          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: exercise['name'],
                            onChanged: (val) => setState(() => exercise['name'] = val),
                            items: _exerciseOptions
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            decoration: const InputDecoration(labelText: 'Exercise'),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeExercise(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Sets:'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: (exercise['sets'] as int).toDouble(),
                            onChanged: (val) => setState(() => exercise['sets'] = val.round()),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '${exercise['sets']} sets',
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          )
        ],
      ),
    );
  }
}
