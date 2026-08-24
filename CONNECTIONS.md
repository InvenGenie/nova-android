# Nova application connection contract

Updated: 25-08-2026

This repository is the cross-platform Nova client. The Flutter Android and
Web applications connect to the existing New-Nova backend; they do not copy
the web application's database or business logic.

## Base URL configuration

The client reads `API_BASE_URL` in this order:

1. Saved local preference (allows a developer override)
2. `--dart-define=API_BASE_URL=...`
3. Optional `.env` value
4. Production default: `https://novamymentor.cloud/nova-api`

Local laptop command:

```powershell
flutter run -d chrome --web-port=5173 `
  --dart-define=API_BASE_URL=http://localhost:5000/nova-api
```

Production build command:

```powershell
flutter build web --release `
  --dart-define=API_BASE_URL=https://novamymentor.cloud/nova-api
```

## Authentication connection

- `POST /login` with `{username, password}`
- `GET /portal_session` restores the signed-in child profile
- Android/native clients persist the session cookie locally
- Web clients use a credentialed browser HTTP client; the browser owns the
  cookie and the app does not manually send a `Cookie` header
- The API must return CORS headers for the deployed web origin with
  `Access-Control-Allow-Credentials: true`

## Student connections already wired

| Client capability | Backend route |
|---|---|
| Backend health | `GET /health` |
| Boards/classes/publications/subjects | `GET /get_boards`, `/get_classes`, `/get_publications`, `/get_subjects` |
| Lessons | `GET /get_filtered_lessons` |
| Stored lesson content | `POST /lesson/content` |
| Quiz generation | `POST /lesson/generate_quiz` |
| Practice stream | `POST /lesson/practice_stream` |
| Cached/AI explanation | `POST /lesson/android/explanation` |
| Study planner | `GET/POST /study-planner/get-plans`, `/study-planner/save-plan` |
| Study tracking | `POST /start_tracking`, `/save_time` |
| Weekly report | `GET /parent/weekly-report-data` |

All routes are relative to `API_BASE_URL`. The route payloads are kept in
`lib/services/api_service.dart` so the mobile/web clients remain independent
of the web UI implementation.

## Production readiness gate

Before changing only the app and treating the web UI as out of scope, verify:

- Production `/nova-api/health` returns healthy.
- Production CORS allows the final hosted Flutter Web origin.
- A dedicated authorized child test account can log in from Android and Web.
- `/portal_session` returns the same profile fields used by the web app.
- Lesson content, quiz, practice, explanation, planner, tracking, and report
  routes are each smoke-tested against production.
- No production password is stored in this repository or printed in logs.

Until this gate passes, local development uses the laptop backend and no
production account or password should be assumed.
