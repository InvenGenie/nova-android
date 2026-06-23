import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';

  String _baseUrl = '';
  String? _token;
  String? get token => _token;

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? dotenv.env['API_BASE_URL'] ?? 'https://novamymentor.cloud/api';
    _token = prefs.getString('auth_token');
  }

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    _baseUrl = url;
    SharedPreferences.getInstance().then((p) => p.setString(_baseUrlKey, url));
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getSession() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/portal_session'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  List<dynamic> _extractList(dynamic body, [String? key]) {
    if (body is List) return body;
    if (body is Map) {
      if (key != null && body[key] is List) return body[key];
      return body.values.firstWhere((v) => v is List, orElse: () => <dynamic>[]);
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> getSubjects({int? board, int? classId, int? pub}) async {
    final params = <String, String>{};
    if (board != null) params['board'] = board.toString();
    if (classId != null) params['class'] = classId.toString();
    if (pub != null) params['pub'] = pub.toString();

    final uri = Uri.parse('$_baseUrl/get_subjects').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: _headers);
    return _extractList(jsonDecode(response.body), 'subjects');
  }

  Future<List<dynamic>> getBoards() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_boards'), headers: _headers);
    return _extractList(jsonDecode(response.body), 'boards');
  }

  Future<List<dynamic>> getClasses() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_classes'), headers: _headers);
    return _extractList(jsonDecode(response.body), 'classes');
  }

  Future<List<dynamic>> getPublications() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_publications'), headers: _headers);
    return _extractList(jsonDecode(response.body), 'publications');
  }

  Future<List<dynamic>> getLessons(int board, int classId, int pub, int subjectId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/get_filtered_lessons')
          .replace(queryParameters: {
        'board': board.toString(),
        'class': classId.toString(),
        'pub': pub.toString(),
        'subject_id': subjectId.toString(),
      }),
      headers: _headers,
    );
    return _extractList(jsonDecode(response.body), 'lessons');
  }

  Future<Map<String, dynamic>> getStudyPlan(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/study-planner/get-plans?username=$username'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> saveStudyPlan(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/study-planner/save-plan'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> startTracking(String username, String subject) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/start_tracking'),
      headers: _headers,
      body: jsonEncode({'username': username, 'subject': subject}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> saveTime(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/save_time'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getWeeklyReport(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/parent/weekly-report-data?username=$username'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}
