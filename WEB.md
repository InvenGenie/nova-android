# Nova Web Client

The Android app is a Flutter multi-platform client. Its student flows can
run in a browser without maintaining a second UI implementation.

## Local development

```powershell
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:5000/nova-api
```

The New-Nova backend must be running on `http://localhost:5000`.

## Build

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://novamymentor.cloud/nova-api
```

The output is in `build/web/`. Web requests use browser-managed credentials
so the New-Nova session cookie can work across the configured CORS origin.
