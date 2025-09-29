# TODO: Konversi Home Screen dan Bottom Navbar ke Flutter

Berdasarkan rencana yang disetujui, berikut langkah-langkah untuk mengonversi layout Android XML ke Flutter:

- [ ] Step 1: Edit lib/core/constants.dart - Tambahkan konstanta warna gelap (e.g., AppColors.black = Color(0xFF000000), AppColors.white = Color(0xFFFFFFFF)).

- [ ] Step 2: Edit lib/app.dart - Ubah tema ke dark (scaffoldBackgroundColor: AppColors.black, colorScheme: ColorScheme.dark(primary: Color(0xFF1E40AF))), ganti home: const MainScreen().

- [ ] Step 3: Buat lib/ui/screens/main_screen.dart - StatefulWidget dengan BottomNavigationBar (items: Home, Search, Library, Profile; icons: Icons.home, Icons.search, Icons.library_books, Icons.person), gunakan IndexedStack untuk \_screens = [HomeScreen(), SearchScreen(), LibraryScreen(), ProfileScreen()]; \_currentIndex untuk switching.

- [ ] Step 4: Buat placeholder screens:

  - lib/ui/screens/search_screen.dart: Scaffold dengan AppBar title 'Search', body: Center(child: Text('Search Screen')).
  - lib/ui/screens/library_screen.dart: Scaffold dengan AppBar title 'Library', body: Center(child: Text('Library Screen')).
  - lib/ui/screens/profile_screen.dart: Scaffold dengan AppBar title 'Profile', body: Center(child: Text('Profile Screen')).

- [ ] Step 5: Edit lib/ui/screens/home_screen.dart - Update AppBar: title: Text(AppConst.appName, style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)), backgroundColor: AppColors.black, actions: [IconButton(icon: Icon(Icons.send, color: AppColors.white), onPressed: () {}), CircleAvatar(radius: 20, backgroundColor: AppColors.white, child: Icon(Icons.person, color: AppColors.black))]. Body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(height: 16), _buildSection('Featured Titles', prov.getFeatured()), SizedBox(height: 24), _buildSection('Categories', prov.getCategories()), ... untuk Popular dan New Releases])), di mana \_buildSection(String title, List items) => Column(children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)), SizedBox(height: 8), SizedBox(height: 200, child: ListView.builder(horizontal, itemCount: items.length, itemBuilder: (ctx, i) => ItemCard(item: items[i], ...)))).

- [ ] Step 6: Edit lib/state/item_provider.dart - Tambahkan getter/method: List<Item> get getFeatured => items.sublist(0, 5); List<Item> get getCategories => items.sublist(5, 10); List<Item> get getPopular => items.sublist(10, 15); List<Item> get getNewReleases => items.sublist(15, 20); (asumsikan items punya minimal 20 untuk dummy).

- [ ] Step 7: Edit lib/ui/widgets/item_card.dart - Tambahkan parameter bool isHorizontal = false, if(isHorizontal) kurangi padding/margin (e.g., Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4))), sesuaikan ukuran untuk horizontal fit (e.g., width: 150).

- [ ] Step 8: Jalankan 'flutter pub get' untuk update dependencies jika ada perubahan.

- [ ] Step 9: Test dengan 'flutter run' - Verifikasi: tema gelap, AppBar dengan actions, section horizontal di home, bottom nav switching screens tanpa error.

- [ ] Step 10: Update TODO.md dengan marking completed steps dan catatan hasil test.

Setelah selesai, konversi dasar home screen dan bottom navbar siap. Integrasi data real dari API bisa dilakukan selanjutnya.
