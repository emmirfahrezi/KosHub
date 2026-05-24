# KosHub

KosHub adalah aplikasi Flutter untuk pencarian kos, chat, booking, dashboard pemilik, dan dashboard admin.

## Backend

Project ini memakai Supabase untuk:

- Auth email/password
- Database Postgres
- Realtime stream
- Row Level Security
- RPC booking kamar

Schema backend ada di `supabase/schema.sql`. Jalankan SQL tersebut di Supabase SQL Editor untuk menyiapkan tabel, policy, trigger, dan function yang dipakai aplikasi.

## Menjalankan

```bash
flutter pub get
flutter run
```

Konfigurasi Supabase ada di `lib/main.dart` melalui `_supabaseUrl` dan `_supabaseAnonKey`.
