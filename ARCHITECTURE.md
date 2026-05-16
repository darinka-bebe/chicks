# Chicks — Architecture

## Overview

**Chicks** is a Flutter mobile application that acts as a personal AI fashion stylist. The codebase follows a **feature-first** layout with a thin **core** layer for cross-cutting concerns (routing, theme, services) and a **data** layer for models and repositories.

The architecture prioritizes:

- Clear separation between UI, state, and external services
- Declarative navigation via **GoRouter**
- Global authentication state via **flutter_bloc**
- Feature-local state for the AI chat via **Cubit**

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                          │
│  Screens (features/*/ui) + Widgets + ui_kit                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     State Management                         │
│  AppBloc (global auth)  │  ChatCubit (per chat session)     │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     Data / Services                          │
│  AuthRepository  │  OpenAiChatService  │  UserModel          │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   Platform & External APIs                     │
│  SharedPreferences  │  OpenAI API  │  flutter_dotenv (.env)   │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
chicks/
├── lib/
│   ├── main.dart                 # Entry: dotenv, auth init, runApp
│   ├── app.dart                  # MaterialApp.router + AppBloc
│   │
│   ├── core/                     # Shared infrastructure
│   │   ├── constants/            # App-wide constants, asset paths
│   │   ├── router/               # GoRouter config, route names
│   │   ├── services/             # OpenAI API, collection names (Firebase prep)
│   │   ├── theme/                # AppTheme, AppColors, AppBrandColors
│   │   └── utils/                # Logger
│   │
│   ├── data/
│   │   ├── models/               # UserModel, ChatMessage
│   │   └── repositories/         # AuthRepository
│   │
│   ├── features/                 # Feature modules
│   │   ├── app/bloc/             # AppBloc, AuthState, AppEvent
│   │   ├── splash/ui/
│   │   ├── login/ui/
│   │   ├── home/ui/              # HomeShell, MainTab
│   │   ├── profile/ui/
│   │   └── chat/                 # ChatScreen, ChatCubit, widgets
│   │
│   ├── widgets/                  # Shared widgets (avatar, Google button)
│   ├── ui_kit/                   # Design system components
│   └── l10n/                     # ARB files + generated localizations
│
├── assets/svg/
├── .env                          # Secrets (gitignored)
├── .env.example                  # Template for developers
└── pubspec.yaml
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **features/** | Screens, feature-specific BLoC/Cubit, feature widgets |
| **data/** | Domain models, repository implementations |
| **core/** | Routing, themes, API wrappers, utilities |
| **widgets/** | Reusable UI not tied to one feature |
| **ui_kit/** | Standardized buttons, loaders |

---

## State Management

### Global: `AppBloc` + `AuthState`

- **Scope:** Entire app (`BlocProvider` in `app.dart`)
- **Purpose:** Reflect authentication status and current `UserModel`
- **Source of truth:** `AuthRepository.authStateChanges` stream
- **Events:** `AppAuthStateChanged`, `AppSignOutRequested`

```text
AuthRepository.signIn/signOut
        → stream emits UserModel
        → AppBloc emits AuthState.authenticated | unauthenticated
        → UI (BlocListener) navigates to /home/main or /login
```

### Feature: `ChatCubit` + `ChatState`

- **Scope:** `ChatScreen` only (`BlocProvider` created in screen)
- **Purpose:** Message list, loading flag, error messages for OpenAI calls
- **Lifecycle:** Destroyed when user leaves chat (session history not persisted)

| Field | Type | Description |
|-------|------|-------------|
| `messages` | `List<ChatMessage>` | In-session conversation |
| `isLoading` | `bool` | Waiting for OpenAI response |
| `error` | `String?` | Last API/user-facing error |

---

## Routing

**Package:** `go_router` ^13.x  
**Config:** `lib/core/router/app_router.dart`

### Navigator Keys

- `rootNavigatorKey` — full-screen routes (splash, login, chat)
- `shellNavigatorKey` — tabbed home area with bottom navigation

### Route Map

| Path | Name | Screen | Navigator |
|------|------|--------|-----------|
| `/` | `splash` | SplashScreen | Root |
| `/login` | `login` | LoginScreen | Root |
| `/registration` | `registration` | RegistrationScreen | Root |
| `/home/main` | `main` | MainTab | Shell |
| `/home/profile` | `profile` | ProfileTab | Shell |
| `/chat` | `chat` | ChatScreen | Root (over shell) |

### Navigation Patterns

- **Auth flow:** `context.go(RouteNames.main | login)` — replaces stack
- **Chat from home:** `context.pushNamed(RouteNames.chatName)` — pushes over shell
- **Back from chat:** `context.pop()`

The `GoRouter` instance is a **singleton** (`AppRouter.router`) to avoid resetting navigation on widget rebuilds.

---

## API Integration

### OpenAI Chat Completions

| Item | Value |
|------|-------|
| Service | `OpenAiChatService` |
| Endpoint | `POST https://api.openai.com/v1/chat/completions` |
| Model | `gpt-4o-mini` |
| Auth | `Authorization: Bearer {OPENAI_API_KEY}` |
| Config | `flutter_dotenv` → `.env` asset |

**Request flow:**

1. `ChatCubit.sendMessage()` appends user `ChatMessage`
2. `OpenAiChatService.completeConversation(history)` builds messages array:
   - System prompt (fashion stylist persona, Russian)
   - Full conversation history (user/assistant roles)
3. HTTP POST via `package:http`
4. Parse `choices[0].message.content` or throw `OpenAiChatException`

### Authentication (Current MVP)

| Item | Value |
|------|-------|
| Implementation | `AuthRepository` (local) |
| Storage | `shared_preferences` |
| Google Sign-In | Mock / local persistence (no Firebase SDK in pubspec) |

---

## Data Flow

### App Startup

```text
main()
  → dotenv.load(".env")
  → AuthRepository.initialize()  // restore session from prefs
  → runApp(App)
       → AppBloc listens to auth stream
       → GoRouter initial: /
```

### Splash → Home or Login

```text
SplashScreen (delay + animation)
  → AuthRepository.isLoggedIn?
       yes → context.go(/home/main)
       no  → context.go(/login)
```

### Chat Message

```text
User taps Send
  → ChatCubit: emit(messages + user msg, isLoading: true)
  → OpenAiChatService.completeConversation(messages)
  → ChatCubit: emit(messages + assistant reply, isLoading: false)
  → ListView scrolls to bottom (post-frame callback)
```

---

## Dependencies

| Package | Role |
|---------|------|
| `flutter_bloc` / `bloc` | `AppBloc`, `ChatCubit` |
| `equatable` | Value equality for states/models |
| `go_router` | Declarative routing |
| `flutter_dotenv` | Load `OPENAI_API_KEY` from `.env` |
| `http` | OpenAI REST calls |
| `shared_preferences` | Local auth session |
| `intl` + `flutter_localizations` | i18n (EN/RU) |
| `flutter_svg` | SVG assets (e.g. Google logo) |
| `image_picker` | Profile photo (planned) |
| `logger` | Debug logging |
| `provider` | Available; primary state is BLoC |

---

## Design Notes

- **Brand colors** (`AppBrandColors`) are used on home/chat; `AppTheme` still uses Material 3 purple for legacy screens.
- **Legacy screens** (`home_screen.dart`, `wardrobe_screen.dart`, `profile_screen.dart`) exist but are **not registered** in the router.
- **Firebase:** `CollectionNames` and README references exist; Firebase packages are **not** in `pubspec.yaml`. Auth is local until Firebase is integrated.

---

## Related Documents

- [BUSINESS_REQUIREMENTS.md](./BUSINESS_REQUIREMENTS.md)
- [SYSTEM_REQUIREMENTS.md](./SYSTEM_REQUIREMENTS.md)
- [TEST_CASES.md](./TEST_CASES.md)
- [FULL_PROJECT_DOCUMENTATION.md](./FULL_PROJECT_DOCUMENTATION.md)
