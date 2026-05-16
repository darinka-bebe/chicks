# Chicks — Test Cases

## Document Purpose

Manual and automated test scenarios for the Chicks Flutter application. Use this document for QA checklists, regression testing, and future `flutter_test` / integration test implementation.

**Legend:**  
- **Priority:** P0 (critical), P1 (high), P2 (medium)  
- **Type:** Manual (M), Unit (U), Widget (W), Integration (I)

---

## 1. Authentication Tests

### TC-AUTH-001: Cold start — unauthenticated user

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | Fresh install or cleared app data; not logged in |

**Steps:**
1. Launch app.
2. Wait for splash animation and delay (~2 s).

**Expected:**
- Navigate to `/login`.
- Login screen shows welcome text and Google Sign-In button.

---

### TC-AUTH-002: Sign in success

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | On login screen |

**Steps:**
1. Tap "Sign in with Google".
2. Wait for completion.

**Expected:**
- No crash.
- Navigate to `/home/main`.
- Home shows greeting with user name.
- `AppBloc` state is `authenticated`.

---

### TC-AUTH-003: Session persistence

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | User signed in |

**Steps:**
1. Kill app process.
2. Relaunch app.

**Expected:**
- Splash → `/home/main` (skip login).
- User data restored from `SharedPreferences`.

---

### TC-AUTH-004: Sign out

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | User signed in on profile tab |

**Steps:**
1. Open Profile tab.
2. Tap sign out.
3. Confirm in dialog.

**Expected:**
- Navigate to `/login`.
- Home not accessible without signing in again.

---

### TC-AUTH-005: Sign out — cancel dialog

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M |

**Steps:**
1. Tap sign out.
2. Tap "Stay" / cancel.

**Expected:**
- Remain on profile; still authenticated.

---

### TC-AUTH-006: Registration navigation

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. From login, open registration.

**Expected:**
- Route `/registration` displays without crash.

---

## 2. Chat Tests

### TC-CHAT-001: Open chat from home

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | Logged in; valid `OPENAI_API_KEY` in `.env` |

**Steps:**
1. On home, tap "Чат со стилистом" card.

**Expected:**
- `ChatScreen` opens full screen (no bottom nav).
- Empty state hint visible.
- Back button present.

---

### TC-CHAT-002: Send message — success

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M / I |
| Preconditions | Chat open; network available |

**Steps:**
1. Type: "Что надеть на свидание?"
2. Tap send.

**Expected:**
- User bubble appears on the right.
- Typing indicator on the left while loading.
- Assistant reply on the left in Russian.
- Send re-enabled after response.

---

### TC-CHAT-003: Session history

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M |

**Steps:**
1. Send message A; wait for reply.
2. Send message B referencing context.

**Expected:**
- Both exchanges visible in list.
- Second reply considers prior context (stylist coherence).

---

### TC-CHAT-004: Empty message

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M / U |

**Steps:**
1. Tap send with empty or whitespace-only input.

**Expected:**
- No message sent; no API call; no crash.

---

### TC-CHAT-005: Loading state blocks duplicate send

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M |

**Steps:**
1. Send a message (slow network).
2. Tap send repeatedly during loading.

**Expected:**
- Only one in-flight request.
- Input/send disabled while `isLoading == true`.

---

### TC-CHAT-006: Leave chat — history cleared

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Send messages in chat.
2. Tap back to home.
3. Re-enter chat.

**Expected:**
- New session; previous messages not shown (Cubit recreated).

---

## 3. Navigation Tests

### TC-NAV-001: Splash routing

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |

| State | Expected route after splash |
|-------|----------------------------|
| Logged in | `/home/main` |
| Logged out | `/login` |

---

### TC-NAV-002: Bottom navigation

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |

**Steps:**
1. Tap Profile tab → `/home/profile`.
2. Tap Home tab → `/home/main`.

**Expected:**
- Correct screen each time; shell persists.

---

### TC-NAV-003: Chat push and pop

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |

**Steps:**
1. From home, open chat.
2. Tap system back or app bar back.

**Expected:**
- Return to home; bottom nav visible.

---

### TC-NAV-004: Invalid route

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Manually navigate to unknown path (debug).

**Expected:**
- Error page: "Страница не найдена: …"

---

### TC-NAV-005: Card tap during home animation

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M |

**Steps:**
1. Immediately after home loads, tap chat card during entrance animation.

**Expected:**
- Chat opens (cards must remain tappable; no `FadeTransition` hit-test block).

---

## 4. UI Tests

### TC-UI-001: Brand colors on home

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Expected:**
- Background `#FFF0F5`, accent `#FF4FA0` on titles/icons.

---

### TC-UI-002: Chat bubble alignment

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | W / M |

**Expected:**
- User: right, pink bubble, white text.
- AI: left, white bubble, dark text.

---

### TC-UI-003: Keyboard and input bar

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M |

**Steps:**
1. Focus text field; open keyboard.

**Expected:**
- Input bar visible above keyboard.
- Multiline field expands up to 4 lines.

---

### TC-UI-004: Long message scroll

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Exchange 10+ messages.

**Expected:**
- List scrolls; auto-scroll to latest on new message.

---

### TC-UI-005: Localization

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Set device locale to EN / RU.

**Expected:**
- Localized strings where ARB keys used (tabs, login, splash).
- Chat UI strings may remain Russian (hardcoded MVP).

---

## 5. API Error Handling Tests

### TC-API-001: Missing API key

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |
| Preconditions | `.env` without `OPENAI_API_KEY` or empty value |

**Steps:**
1. Send chat message.

**Expected:**
- SnackBar with key missing message (Russian).
- No crash; loading ends.

---

### TC-API-002: Invalid API key

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |
| Preconditions | Invalid key in `.env`; hot restart after change |

**Steps:**
1. Send chat message.

**Expected:**
- Error snackbar with OpenAI error text or status.
- User message remains in list.

---

### TC-API-003: No network

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |
| Preconditions | Airplane mode |

**Steps:**
1. Send chat message.

**Expected:**
- Generic network error message.
- App remains stable.

---

### TC-API-004: Empty OpenAI response

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | U |
| Preconditions | Mock HTTP 200 with empty choices |

**Expected:**
- `OpenAiChatException`: unable to get response text.

---

### TC-API-005: HTTP 429 / 500

| Field | Value |
|-------|-------|
| Priority | P1 |
| Type | M / U |

**Expected:**
- Parsed error message shown to user when JSON includes `error.message`.

---

## 6. Edge Cases

### TC-EDGE-001: Rapid hot reload during chat

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Expected:**
- No duplicate listeners; prefer hot restart for Cubit/route changes.

---

### TC-EDGE-002: Very long user message

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Paste 2000+ character message.

**Expected:**
- UI handles scroll/wrap; API may truncate or error per OpenAI limits.

---

### TC-EDGE-003: Special characters and emoji

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Send: `Привет! 👗 "платье" & <test>`

**Expected:**
- Displayed correctly in bubble; API accepts UTF-8.

---

### TC-EDGE-004: dotenv empty file

| Field | Value |
|-------|-------|
| Priority | P0 |
| Type | M |
| Preconditions | `.env` file size 0 bytes |

**Expected:**
- App may throw `EmptyEnvFileError` at startup (flutter_dotenv 6.x).
- Fix: ensure at least one `KEY=value` line.

---

### TC-EDGE-005: Orientation lock

| Field | Value |
|-------|-------|
| Priority | P2 |
| Type | M |

**Steps:**
1. Rotate device.

**Expected:**
- Portrait only (per `SystemChrome.setPreferredOrientations`).

---

## 7. Suggested Automated Tests (Future)

| Area | File suggestion | Cases |
|------|-----------------|-------|
| `OpenAiChatService` | `test/core/openai_chat_service_test.dart` | Mock HTTP; parse success/error |
| `ChatCubit` | `test/features/chat/chat_cubit_test.dart` | sendMessage states |
| `AuthRepository` | `test/data/auth_repository_test.dart` | prefs read/write |
| Widget | `test/features/chat/chat_screen_test.dart` | empty state, loading indicator |
| Integration | `integration_test/app_test.dart` | splash → login → chat |

---

## Related Documents

- [SYSTEM_REQUIREMENTS.md](./SYSTEM_REQUIREMENTS.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [FULL_PROJECT_DOCUMENTATION.md](./FULL_PROJECT_DOCUMENTATION.md)
