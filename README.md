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
### Opsi 1: Script Deploy Otomatis (Paling Mudah)
1. Jalankan script: `deploy.bat` (Windows)
2. Script akan otomatis:
   - Build web app
   - Copy ke folder docs
   - Commit & push hanya folder docs
3. Enable GitHub Pages di repo Settings > Pages > Source: master /docs
4. Akses di https://username.github.io/repo-name

### Opsi 2: Build Manual Lokal
1. Build web: `flutter build web --release`
2. Copy hasil build: `xcopy build\web docs /E /I /H /Y` (Windows) atau `cp -r build/web docs` (Linux/Mac)
3. Commit dan push: `git add docs && git commit -m "Deploy to GitHub Pages" && git push`
4. Enable GitHub Pages di repo Settings > Pages > Source: master /docs
5. Akses di https://username.github.io/repo-name

### Opsi 2: Via GitHub Actions (Otomatis)
1. Push code ke GitHub
2. Actions akan build otomatis dan copy ke docs
3. Enable GitHub Pages di repo Settings
4. Akses langsung tanpa manual commit

**Rekomendasi**: Gunakan Opsi 1 untuk kontrol penuh, atau Opsi 2 untuk otomatis.