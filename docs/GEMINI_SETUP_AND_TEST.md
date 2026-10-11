# PennyPal Gemini Setup and Test

## Implementation

- Firebase AI Logic Flutter SDK: `firebase_ai`
- Firebase App Check Flutter SDK: `firebase_app_check`
- Provider: Gemini Developer API through Firebase AI Logic
- Model: `gemini-3.8-flash`
- Integration point: `lib/services/gemini_service.dart`
- Assistant entry point: `PennyPalService.assistant()`
- UI: `lib/screens/assistant/assistant_screen.dart`

## Security

No Gemini API key is embedded in PennyPal source code. Firebase AI Logic is used so the Gemini Developer API key remains server-side, with Firebase App Check used to protect client requests.

## Local Android testing

Firebase AI Logic setup now enforces App Check for AI requests. For emulator development, `lib/main.dart` activates `AndroidProvider.debug`. On the first run, copy the debug token printed by the Android App Check provider and register it in Firebase Console under **Security > App Check > Apps > Manage debug tokens**.

## Smoke test

1. `flutter clean`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter run -d emulator-5554`
5. Sign in to PennyPal.
6. Open **PennyPal Assistant**.
7. Ask: `How can I reduce my food spending this month?`
8. Confirm the response is generated live and is presented simply as **PennyPal Assistant**.
9. Ask a follow-up such as `What if my monthly food budget is ₦50,000?` and confirm the assistant can continue the conversation.
10. Turn off internet temporarily and confirm the assistant remains usable without exposing provider/model implementation details.

## SRS alignment

The SRS requires an AI chatbot for budgeting/spending questions, response latency within a few seconds, a loading state, and graceful fallback when the AI service fails. The student-facing UI intentionally presents this as PennyPal Assistant rather than exposing the provider/model name.
