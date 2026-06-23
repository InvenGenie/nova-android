class StudyPlan {
  final int id;
  final String date;
  final String? subject;
  final String? lesson;
  final String? mode;
  final bool completed;

  StudyPlan({
    required this.id,
    required this.date,
    this.subject,
    this.lesson,
    this.mode,
    this.completed = false,
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
    id: json['id'] ?? 0,
    date: json['date'] ?? '',
    subject: json['subject'],
    lesson: json['lesson'],
    mode: json['mode'],
    completed: json['completed'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'subject': subject,
    'lesson': lesson,
    'mode': mode,
    'completed': completed,
  };
}
