# Changelog 2025-10-01

### Theming & Arsitektur
- Menambahkan tema terpusat di `lib/core/theme.dart` dengan token warna/dimens dari proyek Android lama.
- Memperluas `AppColors` di `lib/core/constants.dart` untuk konsistensi warna.
- Menulis peta arsitektur di `README.md` (state, data layer, routing, theming, deep links).

### Navigasi & Boot
- Alur `SplashScreen` → `_AuthGate` di `main.dart`/`app.dart` sudah tersambung.
- Bottom navigation disederhanakan menjadi 3 tab: Home, Search, Profile.

### Autentikasi & Profil
- Implementasi UI/flow login & register (Firebase Auth).
- Profil dipoles, termasuk baris statistik realtime: Followers/Following/Reads.
- Edit Profile memperbarui avatar, `username`, `bio`, serta normalisasi `usernameLower`/`handleLower` untuk pencarian.

### Data Layer
- Service Firestore tersedia: Items, User, Favorites, Reading Status, Follow, Chat, Comments, Giphy.
- Reading List terhubung ke status di Firestore (plan/reading/completed/dropped/on_hold).

### Home
- Poster komik kini proporsional (AspectRatio 16:9) dan layout aman.
- Menambah loading skeleton dan haptics halus pada tombol favorite.
- Lencana profil (leading) menampilkan foto user; tap → Profile.

### Search
- Hasil pencarian judul dapat dibuka ke halaman Detail.
- Halaman awal lebih hidup dengan “Trending titles”.
- Pencarian user via `@username` menggunakan `UserService.searchUsers` (index `usernameLower/handleLower`).

### Detail
- Tombol favorite dengan haptic feedback.
- Aksi status baca, tab komentar, serta bagian informasi.

### Chat
- Daftar chat & DM dengan GIF picker, indikator baca (check/double-check), dan penanda terakhir dibaca.
- Popup in-app (snackbar) untuk pesan baru saat aplikasi di-foreground.

### Notifikasi
- FCM di aplikasi: simpan/refresh token, handler background, snackbar foreground, dan handler saat notifikasi dibuka.
- Cloud Functions: kirim notifikasi untuk pesan baru, like komentar, dan follower baru.

### Aset & Lainnya
- Migrasi gambar legacy dan pembaruan `pubspec.yaml`.
- Integrasi Firebase Analytics & Crashlytics (global error handler, event app_open).

### UI Reusable
- Menambahkan `lib/ui/widgets/common.dart` (SectionTitle, DarkListTile, TagChip) untuk konsistensi komponen.

### Peningkatan Terbaru (Follow-up yang sudah ditangani)
- Pencarian user terhubung ke stream Firestore + penambahan index.
- Tap notifikasi DM membuka halaman ChatList.
- Standarisasi Local Storage via `SharedPrefsService`.
- CI/CD GitHub Actions (format, analyze, test, build APK & AAB) + smoke & flow test.


### Pembaruan Prioritas (terbaru)
- Rebrand tampilan menjadi “Coment” (penggantian nama di UI).
- Tema Terang (Light) ditambahkan dan toggle tema (Ikuti Sistem/Terang/Gelap) tersedia di halaman Profile.
- Splash Screen kini tunggal dengan animasi scale + fade yang halus (tanpa jeda putih).
- Home: avatar user di AppBar tampil (fallback ikon bila kosong); kartu poster mengikuti rasio 16:9 dengan BoxFit.cover seperti “Trending titles”.
- Profile: tombol DM dihapus (DM diakses dari Home); Followers/Following menjadi section yang dapat diketuk untuk membuka daftar terkait.
- Tambah halaman “Tentang” (About Us) dan tautannya di Profile.

