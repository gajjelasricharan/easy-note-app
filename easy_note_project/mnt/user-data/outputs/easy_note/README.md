# 📝 Easy Note — AI-Powered Sticky Wall Notes

A production-grade, cross-platform mobile app for Android & iOS built with Flutter + Firebase + Node.js.

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎤 Voice Notes | WhatsApp-style one-tap audio recording, waveform visualization, playback with speed control |
| 🤖 AI Capabilities | Transcription (Whisper), summarization, smart tagging, checklist conversion, content detection |
| 📝 Rich Text | Flutter Quill editor with bold, italic, underline, lists, checklists, headings |
| 🖼️ Media | Images (compressed), videos, PDFs — all stored securely in Firebase Storage |
| 👥 Collaboration | Role-based sharing (owner/editor/viewer), invite links, real-time sync |
| 🌙 Dark Mode | Full dark/light theme toggle with warm neutral palette |
| 📌 Organization | Pin, archive, color-code, tag, and search notes |
| 🔒 Security | Firebase Auth, Firestore rules, Storage rules, JWT verification |
| 📴 Offline | Firestore offline caching, local audio temp storage |

---

## 🏗️ Architecture

```
easy_note/
├── flutter_app/          # Flutter cross-platform frontend
│   └── lib/
│       ├── main.dart
│       ├── models/       # Data models (NoteModel, UserModel)
│       ├── services/     # Firebase, Audio, Storage, AI services
│       ├── providers/    # Riverpod state management
│       ├── screens/      # Home, Editor, Auth, Archive, Settings
│       ├── widgets/      # NoteCard, AudioRecorder, AudioPlayer, etc.
│       └── utils/        # Theme, helpers
├── backend/              # Node.js + Express AI server
│   └── src/
│       ├── server.js
│       ├── routes/       # /ai, /health
│       ├── middleware/   # Auth (Firebase token verification)
│       └── utils/        # Logger
└── firebase/
    ├── firestore.rules   # Security rules
    ├── storage.rules
    └── firestore.indexes.json
```

---

## 🚀 Setup Guide

### 1. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable these services:
   - **Authentication** → Email/Password + Google
   - **Firestore Database**
   - **Storage**
3. Download `google-services.json` → place in `flutter_app/android/app/`
4. Download `GoogleService-Info.plist` → place in `flutter_app/ios/Runner/`
5. Run `flutterfire configure` to generate `lib/firebase_options.dart`
6. Deploy security rules:
   ```bash
   firebase deploy --only firestore:rules,storage,firestore:indexes
   ```

### 2. Flutter App Setup

```bash
cd flutter_app
flutter pub get

# Add fonts (download from Google Fonts)
# Fraunces: https://fonts.google.com/specimen/Fraunces
# DM Sans: https://fonts.google.com/specimen/DM+Sans
mkdir -p assets/fonts
# Place .ttf files in assets/fonts/

flutter run
```

#### Android Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

#### iOS Permissions (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Easy Note needs microphone access for voice recordings</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Easy Note needs photo library access to attach images</string>
<key>NSCameraUsageDescription</key>
<string>Easy Note needs camera access to take photos</string>
```

### 3. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Fill in your values in .env
```

#### Get Firebase Admin credentials:
1. Firebase Console → Project Settings → Service Accounts
2. Generate new private key → download JSON
3. Copy values to `.env`

#### Run locally:
```bash
npm run dev
```

#### Deploy to production (Railway/Render/Fly.io):
```bash
# Railway
railway login
railway init
railway up

# Or Render: connect GitHub repo, set env vars, deploy

# Or Fly.io
fly launch
fly secrets set OPENAI_API_KEY=sk-... FIREBASE_PROJECT_ID=...
fly deploy
```

### 4. Update Flutter AI Service URL

In `lib/services/ai_service.dart`:
```dart
static const String _baseUrl = 'https://YOUR-DEPLOYED-BACKEND.com/api';
```

---

## 📊 Firestore Data Structure

```
/users/{uid}
  uid, email, displayName, photoUrl, createdAt, lastSeen, sharedNoteIds

/notes/{noteId}
  ownerId, title, contentPlainText, contentDelta (Quill delta JSON)
  colorIndex, isPinned, isArchived
  tags: string[]
  audioAttachments: [{id, storageUrl, durationMs, transcript, createdAt}]
  mediaAttachments: [{id, storageUrl, type, fileName, fileSize, createdAt}]
  sharedWith: [{uid, email, displayName, permission}]
  sharedWithUids: string[]  ← for Firestore array-contains queries
  aiSummary, inviteToken
  createdAt, updatedAt
```

---

## 🔒 Security

- Firebase ID tokens verified on every AI request
- Firestore rules enforce owner-only mutations for sensitive fields
- Storage rules restrict uploads to 50MB max, valid mime types only
- Rate limiting: 200 req/15min global, 20 req/min for AI endpoints
- Helmet.js security headers
- CORS restricted to allowed origins
- API keys never exposed to client

---

## 🎨 Design System

**Palette:** Warm neutrals inspired by aged parchment and stone
- Background: `#F7F4EF` (cream)
- Cards: Warm parchment, sage mist, lavender dusk, blush rose, pale sky, golden sand
- Typography: Fraunces (display/headings) + DM Sans (body)
- Dark mode: Deep charcoal backgrounds with warm soft-tan text

---

## 📱 Production Deployment

### App Store (iOS)
1. `flutter build ipa --release`
2. Upload via Xcode or Transporter
3. Required: Privacy Policy URL, App Review notes about microphone/photo usage

### Google Play (Android)
1. `flutter build appbundle --release`
2. Sign with release keystore
3. Upload to Play Console

### Required before submission:
- [ ] Privacy Policy hosted at a URL
- [ ] App icon (1024×1024 PNG)
- [ ] Screenshots (multiple device sizes)
- [ ] Update `OPENAI_API_KEY` protection for production
- [ ] Enable Firebase App Check
- [ ] Set up Firebase Crashlytics

---

## 🤖 AI Capabilities (via backend)

| Endpoint | Model | Purpose |
|----------|-------|---------|
| `POST /ai/transcribe` | Whisper-1 | Audio → text |
| `POST /ai/summarize` | GPT-4o-mini | Note summary |
| `POST /ai/tags` | GPT-4o-mini | Smart tag generation |
| `POST /ai/checklist` | GPT-4o-mini | Convert to action items |
| `POST /ai/detect-type` | GPT-4o-mini | Classify note category |
