# Debt Tracker

Aplikasi Flutter untuk mencatat hutang pribadi dengan fitur:
- Tambah hutang dengan nama, jumlah, tanggal, deskripsi
- Tambah pembayaran untuk setiap hutang dengan foto bukti
- Hitung sisa hutang otomatis
- Data disimpan di Supabase (database + storage)

## Fitur
- Daftar hutang dengan perhitungan total, dibayar, sisa
- Detail pembayaran untuk setiap hutang
- Upload foto bukti pembayaran
- UI responsif untuk mobile dan web

## Setup
1. Clone repo ini
2. Jalankan `flutter pub get`
3. Setup Supabase:
   - Buat project di https://supabase.com
   - Jalankan SQL di Supabase SQL Editor:
     ```sql
     CREATE TABLE debts (
         id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
         nama_hutang TEXT NOT NULL,
         jumlah_hutang NUMERIC NOT NULL,
         tanggal_hutang DATE NOT NULL,
         deskripsi TEXT
     );
     CREATE TABLE payments (
         id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
         debt_id UUID REFERENCES debts(id) ON DELETE CASCADE,
         jumlah_bayar NUMERIC NOT NULL,
         tanggal_bayar DATE NOT NULL,
         foto_url TEXT
     );
     ```
   - Buat bucket `debt_photos` (public)
4. Update URL dan anon key di `lib/main.dart`

## Menjalankan
- Mobile: `flutter run`
- Web: `flutter run -d web`

## Deploy ke GitHub Pages
### Otomatis via GitHub Actions (Direkomendasikan)
1. Push code ke GitHub repo (branch master)
2. GitHub Actions akan otomatis build web app dan copy ke folder `/docs`
3. Commit & push folder docs secara manual:
   ```
   git add docs
   git commit -m "Deploy to GitHub Pages"
   git push
   ```
4. Enable GitHub Pages di repo Settings > Pages > Source: master /docs
5. Akses di https://username.github.io/repo-name

### Manual Build Lokal
1. Build web: `flutter build web --release --base-href "/debt_tracker/"`
2. Copy hasil build: `xcopy build\web docs /E /I /H /Y` (Windows)
3. Commit dan push: `git add docs && git commit -m "Deploy" && git push`
4. Enable GitHub Pages di repo Settings

**Rekomendasi**: Gunakan GitHub Actions untuk konsisten, tapi commit docs manual.