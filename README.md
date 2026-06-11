# MemoPing

MemoPing ist eine private iOS-App zum schnellen Erfassen von Notizen, Erinnerungen, Spracheingaben und Bildern. Die App ist fuer iOS 17+ ausgelegt und nutzt ausschliesslich lokale Apple-Frameworks.

## Datenschutz

- Kein Login
- Keine Cloud-Anbindung
- Kein Backend
- Keine Firebase- oder KI-API
- SwiftData speichert die Metadaten lokal in der App-Sandbox
- Bilder werden als Dateien lokal in `Application Support/MemoPingImages` gespeichert
- Spracherkennung wird mit `requiresOnDeviceRecognition = true` auf lokale Erkennung begrenzt

## Projekt starten

1. Oeffne `MemoPing.xcodeproj` in Xcode.
2. Waehle das Target `MemoPing`.
3. Setze bei Bedarf unter "Signing & Capabilities" dein Apple-Team.
4. Starte die App auf einem iPhone oder Simulator mit iOS 17 oder neuer.

## Benoetigte Info.plist-Berechtigungen

Die Permission Strings sind bereits in `MemoPing/App/Info.plist` eingetragen:

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Simulator-Hinweise

- Kameraaufnahme ist im iOS Simulator normalerweise nicht verfuegbar.
- Lokale On-Device-Spracherkennung kann je nach Simulator, Sprache und macOS/Xcode-Konfiguration nicht verfuegbar sein.
- Bildauswahl, OCR, SwiftData und lokale Benachrichtigungen lassen sich im Simulator grundsaetzlich testen.

## Struktur

```text
MemoPing/
  App/
  Models/
  Views/
  ViewModels/
  Services/
  Components/
```

Die App nutzt SwiftUI, SwiftData, UserNotifications, Speech, Vision, PhotosUI und einen `UIImagePickerController`-Wrapper fuer Kameraaufnahmen.
