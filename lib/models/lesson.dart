class Lesson {
  final int lessonId;
  final String lessonName;
  final String? content;
  final int? subjectId;
  final String? subjectName;

  Lesson({
    required this.lessonId,
    required this.lessonName,
    this.content,
    this.subjectId,
    this.subjectName,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    lessonId: json['lesson_id'] ?? json['id'] ?? 0,
    lessonName: json['lesson_name'] ?? json['name'] ?? json['title'] ?? '',
    content: json['content'] ?? json['lesson_content'],
    subjectId: json['subject_id'],
    subjectName: json['subject_name'],
  );

  Map<String, dynamic> toJson() => {
    'lesson_id': lessonId,
    'lesson_name': lessonName,
    'content': content,
    'subject_id': subjectId,
    'subject_name': subjectName,
  };
}
