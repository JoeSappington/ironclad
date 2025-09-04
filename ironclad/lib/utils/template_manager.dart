import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_template.dart';

class TemplateManager {
  static const _key = 'workoutTemplates';

  static Future<List<WorkoutTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    return WorkoutTemplate.decodeList(jsonString);
  }

  static Future<void> saveTemplate(WorkoutTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadTemplates();
    existing.removeWhere((t) => t.name == template.name);
    existing.add(template);
    await prefs.setString(_key, WorkoutTemplate.encodeList(existing));
  }

  static Future<void> deleteTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadTemplates();
    existing.removeWhere((t) => t.name == name);
    await prefs.setString(_key, WorkoutTemplate.encodeList(existing));
  }

  static Future<void> updateTemplate(String oldName, WorkoutTemplate updatedTemplate) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadTemplates();
    final index = existing.indexWhere((t) => t.name == oldName);
    if (index != -1) {
      existing[index] = updatedTemplate;
    } else {
      existing.add(updatedTemplate);
    }
    await prefs.setString(_key, WorkoutTemplate.encodeList(existing));
  }
}
