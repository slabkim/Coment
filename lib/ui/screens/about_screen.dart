import 'package:flutter/material.dart';
import '../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Coment'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              'Selamat datang di Coment (Comic Enthusiast)!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Coment adalah aplikasi yang kami bangun untuk memudahkan para pecinta komik menemukan, menyimpan, dan berbagi judul favorit. '
              'Kami terinspirasi dari pengalaman pribadi saat mencari rekomendasi manga, manhwa, dan manhua yang sesuai minat.',
            ),
            SizedBox(height: 12),
            Text(
              'Apa yang kami tawarkan:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text('• Rekomendasi personal berdasarkan favorit dan kategori Anda.'),
            Text('• Daftar bacaan dengan status (Plan, Reading, Completed, dll).'),
            Text('• Diskusi melalui komentar dan Direct Message.'),
            Text('• Pencarian cepat judul dan pengguna lain.'),
            SizedBox(height: 12),
            Text(
              'Misi kami sederhana: membantu komunitas komik menemukan bacaan terbaik dengan pengalaman yang cepat, bersih, dan menyenangkan. '
              'Terima kasih telah menggunakan Coment!'
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}


