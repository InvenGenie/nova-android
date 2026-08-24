import 'http_client_io.dart'
    if (dart.library.js_interop) 'http_client_web.dart' as platform;

import 'package:http/http.dart' as http;

http.Client createHttpClient() => platform.createHttpClient();

bool get isWeb => platform.isWeb;
