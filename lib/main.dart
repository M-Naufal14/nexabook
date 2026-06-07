import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Core Firebase
import 'firebase_options.dart'; // 2. Import opsi konfigurasi otomatis tadi
import 'page/login_page.dart';
import 'page/daftar_page.dart';
import 'page/vendor_portal_page.dart';
import 'page/admin_portal_page.dart';
import 'helper/firebase_sqlite_helper.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum inisialisasi asynchronous
  WidgetsFlutterBinding.ensureInitialized();

  // Jalankan koneksi ke Cloud Firebase Server
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Jalankan seeding default users ke Firebase Auth & Firestore
  await FirebaseSqliteHelper.instance.seedFirebaseUsers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF118954),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade300,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF118954),
              secondary: Color(0xFF10B981),
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF0F172A)),
              bodyMedium: TextStyle(color: Color(0xFF334155)),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF10B981),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardColor: const Color(0xFF1E293B),
            dividerColor: const Color(0xFF334155),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              secondary: Color(0xFF10B981),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          home: const SplashPage(),
          routes: {
            '/vendor-portal': (context) => const VendorPortalPage(),
            '/admin-portal': (context) => const AdminPortalPage(),
          },
        );
      },
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, mode, child) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: color ?? (isDark ? Colors.amber : Colors.grey.shade800),
          ),
          onPressed: () {
            MyApp.themeNotifier.value =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
        );
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

        // gambar background

          SizedBox.expand(
            child: Image.asset(
              "assets/images/bg.png",
              fit: BoxFit.cover,
            ),
          ),

          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: const ThemeToggleButton(color: Colors.white),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // logo
                        Center(
                          child: Image.asset(
                            "assets/images/logo.png",
                            width: 120,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Booking Visual Jadi Mudah",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const Spacer(),

                        // button login
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF118954),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DAFTAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Belum punya akun? ",
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DaftarPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "daftar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}