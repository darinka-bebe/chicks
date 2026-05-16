# Chicks — Business Requirements

## Document Purpose

This document describes the **business context**, **target users**, and **product scope** for the Chicks mobile application. It defines *why* the product exists and *what* value it delivers, independent of technical implementation.

---

## Project Goals

1. **Democratize personal styling** — Give users affordable, on-demand fashion advice without hiring a human stylist.
2. **Reduce decision fatigue** — Help users choose outfits, combinations, and wardrobe updates quickly.
3. **Build habit and engagement** — Encourage return visits through conversational AI and future wardrobe features.
4. **Establish a fashion-tech brand** — Position Chicks as a friendly, modern stylist companion (not a generic chatbot).

---

## Product Vision

> Chicks is your personal AI fashion stylist — always in your pocket, speaking your language, and helping you feel confident in what you wear.

---

## Target Audience

### Primary

| Segment | Characteristics | Needs |
|---------|-----------------|-------|
| **Fashion-conscious women (18–35)** | Active on social media, follow trends | Outfit ideas, color matching, seasonal updates |
| **Busy professionals** | Limited time to shop or plan outfits | Quick, structured advice; capsule wardrobe tips |
| **Style beginners** | Unsure what suits them | Safe guidance, simple rules, encouragement |

### Secondary

- Men interested in casual/smart-casual styling (future expansion)
- Users preparing for events (dates, interviews, parties)

### Geographic / Language

- **Initial market:** Russian-speaking users (UI and AI responses in Russian)
- **Future:** English and additional locales via `l10n`

---

## User Problems

| Problem | How Chicks Addresses It |
|---------|-------------------------|
| "I don't know what to wear today" | AI chat for instant outfit suggestions |
| "These pieces don't go together" | Combination advice (colors, textures, silhouettes) |
| "I buy clothes I never wear" | Capsule wardrobe and purchase guidance |
| "Stylists are expensive" | 24/7 AI assistant at low marginal cost |
| "Trends change too fast" | Trend-aware but practical recommendations |
| "I need confidence, not judgment" | Friendly, supportive stylist tone |

---

## Main Features

### Implemented (MVP)

| Feature | Description | Business Value |
|---------|-------------|----------------|
| **Splash & onboarding** | Branded entry, session check | Professional first impression |
| **Sign-in (local/Google UI)** | User identity for personalization | Retention, profile foundation |
| **Home hub** | Greeting, feature cards | Discovery of core capabilities |
| **AI Stylist Chat** | GPT-4o-mini fashion assistant | Core differentiator |
| **Profile & sign-out** | Account management | Trust, control |

### Planned / Partial

| Feature | Status | Notes |
|---------|--------|-------|
| **Digital wardrobe** | UI card only | Upload items, get recommendations |
| **Style profile** | UI card only | Color type, body shape, preferences |
| **Registration screen** | Route exists | Full registration flow TBD |
| **Firebase auth & cloud sync** | Scaffold only | `CollectionNames`, local auth today |
| **Profile photo** | `image_picker` in deps | Integration TBD |

---

## Business Value

| Stakeholder | Value |
|-------------|-------|
| **Users** | Faster styling decisions, increased confidence, personalized tips |
| **Business** | Engagement, future monetization (premium AI, affiliate, stylist marketplace) |
| **Brand** | Distinct pink identity, memorable "stylist friend" positioning |

### Potential Revenue (Post-MVP)

- Freemium AI message limits
- Premium stylist personas or deeper analysis
- Affiliate links to fashion retailers
- Partnerships with brands

---

## MVP Scope

### In Scope

- [x] Flutter app (Android primary; iOS project present)
- [x] Local authentication persistence
- [x] Home screen with stylist chat entry point
- [x] AI chat with OpenAI (session-based history)
- [x] Russian AI persona (friendly stylist)
- [x] Environment-based API key configuration
- [x] Basic profile and sign-out

### Out of Scope (MVP)

- [ ] Real Google Sign-In / Firebase Auth production setup
- [ ] Wardrobe photo upload and catalog
- [ ] Push notifications
- [ ] Offline AI responses
- [ ] Payment / subscriptions
- [ ] Admin dashboard
- [ ] Analytics pipeline

### Success Criteria (MVP)

1. User can sign in and reach home within 30 seconds.
2. User can open chat and receive a relevant stylist reply in Russian.
3. App handles missing API key and network errors gracefully.
4. No critical crashes on main user flows (splash → login → home → chat).

---

## Competitive Positioning

| Alternative | Chicks Advantage |
|-------------|------------------|
| Generic ChatGPT | Fashion-tuned system prompt, in-app UX, brand |
| Pinterest / Instagram | Actionable dialogue, not just inspiration |
| Human stylists | Instant, affordable, always available |

---

## Related Documents

- [SYSTEM_REQUIREMENTS.md](./SYSTEM_REQUIREMENTS.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [FULL_PROJECT_DOCUMENTATION.md](./FULL_PROJECT_DOCUMENTATION.md)
