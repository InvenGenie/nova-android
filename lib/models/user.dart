class User {
  final int id;
  final String username;
  final String name;
  final String? email;
  final String role;
  final String? userClass;
  final String? syllabus;
  final String? school;
  final String? profilePic;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    required this.role,
    this.userClass,
    this.syllabus,
    this.school,
    this.profilePic,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'student',
      userClass: json['class'] ?? json['user_class'],
      syllabus: json['syllabus'] ?? 'CBSE',
      school: json['school'],
      profilePic: json['picture'] ?? json['profile_pic'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'username': username,
    'name': name,
    'email': email,
    'role': role,
    'class': userClass,
    'syllabus': syllabus,
    'school': school,
    'picture': profilePic,
    'token': token,
  };
}
