import 'package:flutter/material.dart';

class ExerciseSet {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }

  Map<String, String> toJson() {
    return {
      'weight': weightController.text,
      'reps': repsController.text,
    };
  }
}

class ExerciseEntry {
  String? selectedExercise;
  List<ExerciseSet> sets = [];
  final VoidCallback onChanged;

  ExerciseEntry({required this.onChanged}) {
    addSet();
  }

  void addSet() {
    final set = ExerciseSet();
    set.weightController.addListener(handleChange);
    set.repsController.addListener(handleChange);
    sets.add(set);
    onChanged();
  }

  void removeSet(int index) {
    if (index >= 0 && index < sets.length) {
      sets[index].dispose();
      sets.removeAt(index);
      onChanged();
    }
  }

  void handleChange() {
    onChanged();
  }

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': selectedExercise ?? '',
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}

class ExerciseEntryWidget extends StatelessWidget {
  final ExerciseEntry entry;
  final int index;
  final List<String> exerciseOptions;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;

  const ExerciseEntryWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.exerciseOptions,
    required this.onRemove,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.selectedExercise,
                    onChanged: (value) {
                      entry.selectedExercise = value;
                      entry.onChanged();
                    },
                    items: exerciseOptions.map((exercise) {
                      return DropdownMenuItem(
                        value: exercise,
                        child: Text(exercise),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Exercise',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entry.sets.asMap().entries.map((setEntry) {
              final i = setEntry.key;
              final set = setEntry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: set.weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (lbs)',
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        entry.removeSet(i);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
