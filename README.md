# Debt Tracker

Aplikasi Flutter untuk mencatat hutang pribadi dengan fitur:
- Tambah hutang dengan nama, jumlah, tanggal, deskripsi
- Tambah pembayaran untuk setiap hutang dengan foto bukti
- Hitung sisa hutang otomatis
- Data disimpan di Firebase (Cloud Firestore), foto bukti dikirim ke grup Telegram

## Fitur
- Daftar hutang dengan perhitungan total, dibayar, sisa
- Detail pembayaran untuk setiap hutang
- Upload foto bukti pembayaran ke Telegram group (via bot)
- UI responsif untuk mobile dan web

## Setup
1. Clone repo ini
2. Jalankan `flutter pub get`
3. Setup Firebase:
   - Buat project di https://console.firebase.google.com
   - Aktifkan **Cloud Firestore**
   - Buat rules sesuai kebutuhan akses app kamu
4. Konfigurasi web Firebase sudah ada di `lib/firebase_options.dart`
5. Setup Telegram Bot:
   - Tambahkan bot ke grup
   - Siapkan `TELEGRAM_BOT_TOKEN`
   - Siapkan `TELEGRAM_CHAT_ID` (format ideal: `-100...`)
6. Opsional atur PIN hapus saat run/build:
   - `--dart-define TELEGRAM_BOT_TOKEN=xxx`
   - `--dart-define TELEGRAM_CHAT_ID=-100xxxxxxxxxx`
   - `--dart-define DELETE_PIN=1234`

## Menjalankan
- Mobile:
  `flutter run --dart-define TELEGRAM_BOT_TOKEN=xxx --dart-define TELEGRAM_CHAT_ID=-100xxxxxxxxxx`
- Web:
  `flutter run -d web --dart-define TELEGRAM_BOT_TOKEN=xxx --dart-define TELEGRAM_CHAT_ID=-100xxxxxxxxxx`

## Deploy ke GitHub Pages
### Otomatis via GitHub Actions (Direkomendasikan)
1. Push code ke GitHub repo (branch `main`)
2. Tambah GitHub repository secrets:
   - `TELEGRAM_BOT_TOKEN`
   - `TELEGRAM_CHAT_ID`
   - `DELETE_PIN` (opsional)
3. GitHub Actions akan build dan publish otomatis ke GitHub Pages
4. Enable GitHub Pages di repo Settings > Pages (Source: GitHub Actions)
5. Akses di `https://username.github.io/repo-name`

### Manual Build Lokal
1. Build web:
   `flutter build web --release --base-href "/debt_tracker/" --dart-define TELEGRAM_BOT_TOKEN=xxx --dart-define TELEGRAM_CHAT_ID=-100xxxxxxxxxx`
2. Copy hasil build: `xcopy build\web docs /E /I /H /Y` (Windows)
3. Commit dan push: `git add docs && git commit -m "Deploy" && git push`
4. Enable GitHub Pages di repo Settings

**Rekomendasi**: Gunakan GitHub Actions agar deploy konsisten tanpa commit manual folder `docs`.
