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
      exercises: List<Map<String, dynamic>>.from(json['exercises']),
    );
  }

  static String encodeList(List<WorkoutTemplate> templates) {
    return json.encode(templates.map((e) => e.toJson()).toList());
  }

  static List<WorkoutTemplate> decodeList(String jsonString) {
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => WorkoutTemplate.fromJson(e)).toList();
  }
}
