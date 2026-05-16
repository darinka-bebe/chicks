# Chicks — System Requirements

## Document Purpose

This document specifies **functional** and **non-functional** requirements, supported platforms, technology stack, external dependencies, and quality attributes for the Chicks Flutter application.

---

## Functional Requirements

### FR-1: Application Launch

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1.1 | App displays splash screen with branding animation | Must |
| FR-1.2 | App loads environment variables from `.env` at startup | Must |
| FR-1.3 | After splash delay, route user to home if logged in, else login | Must |
| FR-1.4 | App locks to portrait orientation | Should |

### FR-2: Authentication

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-2.1 | User can sign in via Google Sign-In button (local mock MVP) | Must |
| FR-2.2 | Session persists across app restarts (`SharedPreferences`) | Must |
| FR-2.3 | User can sign out from profile with confirmation dialog | Must |
| FR-2.4 | Global auth state available to all screens via `AppBloc` | Must |
| FR-2.5 | Registration screen accessible from login | Should |

### FR-3: Home

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-3.1 | Display user greeting and avatar | Must |
| FR-3.2 | Show feature cards: Wardrobe, Stylist Chat, Style | Must |
| FR-3.3 | Stylist Chat card navigates to chat screen | Must |
| FR-3.4 | Bottom navigation between Home and Profile | Must |

### FR-4: AI Stylist Chat

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-4.1 | User can send text messages | Must |
| FR-4.2 | App calls OpenAI Chat Completions API (`gpt-4o-mini`) | Must |
| FR-4.3 | Assistant replies in Russian with stylist persona | Must |
| FR-4.4 | Conversation history maintained for current session | Must |
| FR-4.5 | Loading indicator while awaiting response | Must |
| FR-4.6 | User messages right-aligned; AI messages left-aligned | Must |
| FR-4.7 | Display errors (missing key, API failure, network) to user | Must |
| FR-4.8 | Disable send while request in progress | Must |

### FR-5: Profile

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-5.1 | Display user name and avatar | Must |
| FR-5.2 | Sign-out returns user to login | Must |

### FR-6: Localization

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-6.1 | Support English and Russian via ARB files | Should |
| FR-6.2 | Generated `AppLocalizations` integrated in `MaterialApp` | Should |

---

## Non-Functional Requirements

### NFR-1: Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1.1 | Cold start to splash interactive | < 3 s on mid-range device |
| NFR-1.2 | Chat UI feedback on send | Immediate (optimistic user bubble) |
| NFR-1.3 | OpenAI response | Dependent on network; show loading state |

### NFR-2: Reliability

| ID | Requirement |
|----|-------------|
| NFR-2.1 | App must not crash on empty chat input |
| NFR-2.2 | App must not crash on empty `.env` API key (show error) |
| NFR-2.3 | HTTP errors parsed and surfaced to user |

### NFR-3: Usability

| ID | Requirement |
|----|-------------|
| NFR-3.1 | Pink brand theme on home and chat |
| NFR-3.2 | Touch targets ≥ 48 dp for primary actions |
| NFR-3.3 | Scrollable message list for long conversations |

### NFR-4: Maintainability

| ID | Requirement |
|----|-------------|
| NFR-4.1 | Feature-based folder structure |
| NFR-4.2 | API logic isolated in `OpenAiChatService` |
| NFR-4.3 | Route paths centralized in `RouteNames` |

### NFR-5: Security

| ID | Requirement |
|----|-------------|
| NFR-5.1 | API keys stored in `.env`, not committed to Git |
| NFR-5.2 | `.env` listed in `pubspec.yaml` assets for runtime load only on device |
| NFR-5.3 | HTTPS for all OpenAI requests |
| NFR-5.4 | No API key logging in production builds |

> **Note:** Embedding API keys in mobile app assets is acceptable for MVP but not ideal for production. Consider a backend proxy for production releases.

### NFR-6: Compatibility

| ID | Requirement |
|----|-------------|
| NFR-6.1 | Dart SDK `>=3.0.0 <4.0.0` |
| NFR-6.2 | Flutter `>=3.10.0` |

---

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | Primary | API 21+ (per project Gradle config) |
| **iOS** | Project present | Requires Xcode setup, not primary test target |
| **Web** | Experimental | Flutter web capable; not validated for MVP |
| **Desktop** | Not targeted | Windows/macOS/Linux not in scope |

---

## Technologies Used

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State management | flutter_bloc, bloc |
| Routing | go_router |
| HTTP client | http |
| Secrets | flutter_dotenv |
| Local storage | shared_preferences |
| i18n | flutter gen-l10n (ARB) |
| UI | Material 3, custom brand colors |
| Logging | logger |

---

## API Dependencies

### OpenAI API

| Property | Value |
|----------|-------|
| Service | Chat Completions |
| Base URL | `https://api.openai.com/v1/chat/completions` |
| Model | `gpt-4o-mini` |
| Authentication | Bearer token (`OPENAI_API_KEY`) |
| Rate limits | Per OpenAI account tier |
| Availability | Requires internet |

### External Services (Planned)

| Service | Purpose | Status |
|---------|---------|--------|
| Firebase Auth | Google Sign-In | Not in pubspec |
| Cloud Firestore | User profiles, wardrobe | Not in pubspec |
| Google Sign-In SDK | OAuth | UI only (mock auth) |

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes (for chat) | OpenAI API secret key |

File: project root `.env` (copy from `.env.example`).  
Bundled as Flutter asset — must not be empty for chat to work.

---

## Performance Requirements (Summary)

- UI animations at 60 fps where possible on target devices
- No blocking main isolate during HTTP calls (async/await)
- Chat list uses `ListView.builder` for efficient scrolling

---

## Security Requirements (Summary)

1. Gitignore `.env` and secret files
2. Provide `.env.example` without real keys
3. Rotate keys if exposed in logs or repositories
4. Future: move OpenAI calls to backend; use Firebase App Check

---

## Related Documents

- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [BUSINESS_REQUIREMENTS.md](./BUSINESS_REQUIREMENTS.md)
- [TEST_CASES.md](./TEST_CASES.md)
- [FULL_PROJECT_DOCUMENTATION.md](./FULL_PROJECT_DOCUMENTATION.md)
