# Spacey – Setup & Run Guide

## 1. Supabase Setup

### A. Run SQL Migrations
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**
2. Paste and run the full contents of:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
   This creates all tables, RLS policies, enums, and triggers.

### B. Enable Email Auth
- Dashboard → **Authentication** → **Providers** → Enable **Email** provider.

### C. Deploy Edge Functions
Install the Supabase CLI first:
```bash
npm install -g supabase
supabase login
supabase link --project-ref qedotnlttzfxfzkoczwy
```

Deploy both edge functions:
```bash
supabase functions deploy ai_mission_plan
supabase functions deploy ai_nebula_structurer
```

> [!IMPORTANT]  
> The edge functions currently return **mock AI responses**. To connect a real LLM (OpenAI, Gemini, etc.):
> 1. Edit `supabase/functions/ai_mission_plan/index.ts`
> 2. Replace the `mockLLMResponse` block with a real `fetch()` call to an LLM API
> 3. Store your API key as a Supabase Edge Function secret: `supabase secrets set OPENAI_API_KEY=sk-...`

---

## 2. Flutter App Setup

### A. Credentials
Your credentials are already configured in `lib/core/constants.dart`:
```dart
supabaseUrl = 'https://qedotnlttzfxfzkoczwy.supabase.co';
supabaseAnonKey = 'sb_publishable_Zv4PT7lmNs1J-RkupdUbhQ_OQW4iiFT';
```

### B. Install dependencies
```bash
flutter pub get
```

### C. Run the app
```bash
flutter run
```

---

## 3. Acceptance Checklist

| Feature | Files |
|---|---|
| Auth (login/signup/reset/session) | `lib/features/auth/auth_screen.dart`, `lib/core/routing/app_router.dart` |
| Route guarding | `lib/core/routing/app_router.dart` (redirect hook) |
| Mission CRUD | `lib/features/missions/mission_model.dart`, `mission_repository.dart`, `missions_screen.dart`, `mission_form.dart`, `mission_detail_screen.dart` |
| AI Mission Planning | `lib/services/ai/ai_service.dart`, `supabase/functions/ai_mission_plan/index.ts` |
| Subtask management | `mission_detail_screen.dart`, `mission_repository.dart` |
| Supabase RLS | `supabase/migrations/001_initial_schema.sql` |
| Focus Timer (circular, animated) | `lib/features/focus/focus_timer.dart` |
| Starfield background | `_StarfieldPainter` in `focus_timer.dart` |
| Timer persistence across restart | SharedPreferences in `focus_timer.dart` |
| Focus session logging | `focus_sessions` Supabase insert in `_onComplete()` |
| Idea Nebula input + AI | `lib/features/nebula/nebula_screen.dart`, `nebula_repository.dart`, `ai_nebula_structurer/index.ts` |
| Nebula history | `nebulaEntriesProvider` in `nebula_repository.dart` |
| Galaxy Map (interactive canvas) | `lib/features/galaxy/galaxy_map_screen.dart` (`_GalaxyMapPainter`) |
| Galaxy Map zoomable/pannable | `InteractiveViewer` in `galaxy_map_screen.dart` |
| Tap to open detail | `GestureDetector.onTapDown` + `showModalBottomSheet` |
| DB Schema (all tables + RLS) | `supabase/migrations/001_initial_schema.sql` |
