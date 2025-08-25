import 'dart:convert';

class WorkoutTemplate {
  final String name;
  final List<Map<String, dynamic>> exercises;

  WorkoutTemplate({required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
        'name': name,
        'exercises': exercises,
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      name: json['name'],
      exercises: List<Map<String, dynamic>>.from(
        (json['exercises'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
    );
  }

  // ✅ These fix the error in TemplateManager:
  static String encodeList(List<WorkoutTemplate> templates) {
    return json.encode(templates.map((t) => t.toJson()).toList());
  }

  static List<WorkoutTemplate> decodeList(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => WorkoutTemplate.fromJson(e)).toList();
  }
}
