import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _cookieKey = 'session_cookie';

  String _baseUrl = '';
  String? _token;
  String? _sessionCookie;
  String? get token => _token;

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? dotenv.env['API_BASE_URL'] ?? 'https://novamymentor.cloud/nova-api';
    _token = prefs.getString('auth_token');
    _sessionCookie = prefs.getString(_cookieKey);
    await _loadPersistedCache();
  }

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    _baseUrl = url;
    SharedPreferences.getInstance().then((p) => p.setString(_baseUrlKey, url));
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionCookie != null) 'Cookie': _sessionCookie!,
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

  Future<void> _saveCookie(String? cookie) async {
    _sessionCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    if (cookie != null) {
      await prefs.setString(_cookieKey, cookie);
    } else {
      await prefs.remove(_cookieKey);
    }
  }

  Future<void> clearSession() async {
    _sessionCookie = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
    await prefs.remove('auth_token');
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final cookie = response.headers['set-cookie'];
    if (cookie != null) {
      final parsed = cookie.split(';').first;
      await _saveCookie(parsed);
    }
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

  // ---- Local cache: keeps subjects/classes instant after first load ----
  static final Map<String, List<dynamic>> _memCache = {};
  static final Map<String, DateTime> _memCacheTs = {};
  static const String _prefPrefix = 'nova_cache_';

  String _subjectsKey({int? board, int? classId, int? pub}) =>
      'subjects_${board ?? 0}_${classId ?? 0}_${pub ?? 0}';

  List<dynamic>? getCachedClasses() => _memCache['classes'];
  List<dynamic>? getCachedSubjects({int? board, int? classId, int? pub}) =>
      _memCache[_subjectsKey(board: board, classId: classId, pub: pub)];

  Future<void> _storeCache(String key, List<dynamic> data) async {
    _memCache[key] = data;
    _memCacheTs[key] = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPrefix + key, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadPersistedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.startsWith(_prefPrefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        final data = jsonDecode(raw) as List<dynamic>;
        final memKey = key.substring(_prefPrefix.length);
        _memCache.putIfAbsent(memKey, () => data);
      }
    } catch (_) {}
  }

  Future<List<dynamic>> _cachedGet(String key, String path, String listKey) async {
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    final list = _extractList(jsonDecode(response.body), listKey);
    await _storeCache(key, list);
    return list;
  }

  Future<List<dynamic>> getSubjects({int? board, int? classId, int? pub}) async {
    final params = <String, String>{};
    if (board != null) params['board'] = board.toString();
    if (classId != null) params['class'] = classId.toString();
    if (pub != null) params['pub'] = pub.toString();

    final key = _subjectsKey(board: board, classId: classId, pub: pub);
    final uri = Uri.parse('$_baseUrl/get_subjects').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: _headers);
    final list = _extractList(jsonDecode(response.body), 'subjects');
    await _storeCache(key, list);
    return list;
  }

  Future<List<dynamic>> getBoards() async =>
      _cachedGet('boards', '/get_boards', 'boards');

  Future<List<dynamic>> getClasses() async =>
      _cachedGet('classes', '/get_classes', 'classes');

  Future<List<dynamic>> getPublications() async =>
      _cachedGet('publications', '/get_publications', 'publications');

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
    final now = DateTime.now();
    final response = await http.get(
      Uri.parse('$_baseUrl/study-planner/get-plans?username=$username&year=${now.year}&month=${now.month}'),
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

  // ---- Session payload expected by the New-Nova AI lesson endpoints ----
  Map<String, dynamic> _buildSession({
    String? subject,
    String? lesson,
    String? board,
    String? lessonClass,
    String? publication,
  }) =>
      {
        'selected_lesson': lesson,
        'selected_subject': subject,
        'syllabus': board ?? 'CBSE',
        'class': lessonClass,
        'publication': publication ?? 'NCERT',
      };

  String _stripMarkers(String text) => text
      .replaceAll(RegExp(r'__SOURCE__:[^\n]*\n?', caseSensitive: false), '')
      .replaceAll(RegExp(r'__METRICS__:[^\n]*\n?', caseSensitive: false), '')
      .replaceAll(RegExp(r'__SESSION__:[^\n]*\n?', caseSensitive: false), '')
      .trim();

  // ---- Lesson content (SCRUM-512, path 2: direct DB retrieval) ----
  // Fetches the stored textbook content straight from the `lesson_materials`
  // database table — fast, authoritative, shared with the web app. No AI.
  Future<String> getLessonContent({
    required String chapter,
    String? subject,
    String? board,
    String? lessonClass,
    String? publication,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/lesson/content'),
      headers: _headers,
      body: jsonEncode({
        'chapter': chapter,
        'subject': subject,
        'board': board ?? 'CBSE',
        'class': lessonClass,
        'publication': publication ?? 'NCERT',
        'session': _buildSession(
          subject: subject,
          lesson: chapter,
          board: board,
          lessonClass: lessonClass,
          publication: publication,
        ),
      }),
    );
    if (response.statusCode == 404) {
      return '';
    }
    final body = jsonDecode(response.body);
    final content = body['content'] ?? '';
    return _stripMarkers(content is String ? content : '');
  }

  // ---- Quiz generation (clean JSON) ----
  Future<Map<String, dynamic>> getQuiz({
    required String lessonName,
    String? subject,
    String? board,
    String? lessonClass,
    String? publication,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/lesson/generate_quiz'),
      headers: _headers,
      body: jsonEncode({
        'summary': null,
        'session': _buildSession(
          subject: subject,
          lesson: lessonName,
          board: board,
          lessonClass: lessonClass,
          publication: publication,
        ),
      }),
    );
    return jsonDecode(response.body);
  }

  // ---- Practice questions (streamed plain text) ----
  Future<String> getPracticeQuestions({
    required String lessonName,
    int numQuestions = 5,
    String? subject,
    String? board,
    String? lessonClass,
    String? publication,
  }) async {
    final request = http.Request('POST', Uri.parse('$_baseUrl/lesson/practice_stream'));
    request.headers.addAll(_headers);
    request.body = jsonEncode({
      'lesson_name': lessonName,
      'num_questions': numQuestions,
      'session': _buildSession(
        subject: subject,
        lesson: lessonName,
        board: board,
        lessonClass: lessonClass,
        publication: publication,
      ),
    });
    final streamed = await request.send();
    final body = await streamed.stream.transform(utf8.decoder).join();
    return _stripMarkers(body);
  }

  // ---- Explanation (Android-exclusive, cache-first) ----
  // Shows a stored explanation when one exists (server OR local cache); only
  // calls the AI when none is stored or when force=true (student pressed
  // "Re-explain"). Mirrors the agreed design: stored explanations first, AI last.
  Future<Map<String, dynamic>> getExplanation({
    required String username,
    required String kind,
    String? topic,
    String? subject,
    String? chapter,
    String? question,
    String? correctOption,
    String? class_,
    String? board,
    String? publication,
    bool force = false,
  }) async {
    final cacheKey = _explanationKey(
        username, kind, topic, subject, chapter, question, correctOption, class_, board, publication);
    if (!force) {
      final local = await _loadLocalExplanation(cacheKey);
      if (local != null && local.isNotEmpty) {
        return {'explanation': local, 'cached': true, 'source': 'local'};
      }
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/lesson/android/explanation'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'kind': kind,
        'topic': topic,
        'subject': subject,
        'chapter': chapter,
        'question': question,
        'correct_option': correctOption,
        'class_': class_,
        'board': board,
        'publication': publication,
        'force': force,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final explanation = (body['explanation'] ?? '').toString();
    if (explanation.isNotEmpty) {
      await _saveLocalExplanation(cacheKey, explanation);
    }
    return {'explanation': explanation, 'cached': body['cached'] ?? false, 'source': 'server'};
  }

  String _explanationKey(
    String username,
    String kind,
    String? topic,
    String? subject,
    String? chapter,
    String? question,
    String? correctOption,
    String? class_,
    String? board,
    String? publication,
  ) {
    final raw = '$username|$kind|${subject ?? ''}|${class_ ?? ''}|${board ?? ''}'
        '|${topic ?? ''}|${chapter ?? ''}|${question ?? ''}|${correctOption ?? ''}';
    var hash = 0;
    for (var i = 0; i < raw.length; i++) {
      hash = (hash * 31 + raw.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 'nova_expl_${hash.toRadixString(16)}';
  }

  Future<String?> _loadLocalExplanation(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalExplanation(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}
