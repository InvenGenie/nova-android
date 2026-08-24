import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createHttpClient() => BrowserClient()..withCredentials = true;

bool get isWeb => true;
