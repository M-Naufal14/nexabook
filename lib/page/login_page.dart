import 'package:flutter/material.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../main.dart';
import 'home_page.dart';
import 'daftar_page.dart';
import 'vendor_portal_page.dart';
import 'admin_portal_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Email tidak boleh kosong!"),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Kata sandi tidak boleh kosong!"),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF118954),
        ),
      ),
    );

    final user = await FirebaseSqliteHelper.instance.loginUserWithoutRole(email, password);

    // Tutup loading dialog
    if (mounted) Navigator.pop(context);

    if (user != null) {
      final userRole = user['role'] as String?;
      // Set session aktif
      FirebaseSqliteHelper.currentUserEmail = user['email'] as String?;
      FirebaseSqliteHelper.currentUserRole = userRole;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, ${user['email']}!"),
            backgroundColor: const Color(0xFF118954),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (userRole == 'Admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminPortalPage()),
            (route) => false,
          );
        } else if (userRole == 'Vendor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VendorPortalPage()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Email atau kata sandi salah!"),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.92) : Colors.white.withOpacity(0.92);
    final textMainColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final textSubColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final inputBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : Colors.grey.shade300;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              "assets/images/bg1.png",
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for cinematic depth
          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          // Elegant Circular Back Button & Theme Toggle at Top
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF118954)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const ThemeToggleButton(),
                ),
              ],
            ),
          ),

          // Central Card Container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF118954).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_person_outlined,
                              color: Color(0xFF118954),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Selamat Datang Kembali",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textMainColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Masuk ke akun Nexabook Anda",
                            style: TextStyle(
                              color: textSubColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),



                    // Label Email
                    Text(
                      "Email",
                      style: TextStyle(
                        color: textMainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textMainColor),
                      decoration: InputDecoration(
                        hintText: "Masukkan Email Anda",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF118954), size: 20),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF118954), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Label Password
                    Text(
                      "Kata Sandi",
                      style: TextStyle(
                        color: textMainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textMainColor),
                      decoration: InputDecoration(
                        hintText: "Masukkan Password",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF118954), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF118954), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lupa Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF118954).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_reset_outlined, color: Color(0xFF118954), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Lupa Kata Sandi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jika Anda lupa kata sandi, silakan hubungi administrator platform untuk mereset akun Anda.',
                                    style: TextStyle(fontSize: 13, height: 1.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF118954).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.email_outlined, color: Color(0xFF118954), size: 18),
                                        SizedBox(width: 10),
                                        Text(
                                          'admin@nexabook.com',
                                          style: TextStyle(
                                            color: Color(0xFF118954),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF118954),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Lupa kata sandi?",
                          style: TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF118954),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF118954).withOpacity(0.4),
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          "Masuk",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle ke Halaman Daftar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Belum punya akun? ",
                          style: TextStyle(color: textSubColor, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DaftarPage()),
                            );
                          },
                          child: const Text(
                            "Daftar",
                            style: TextStyle(
                              color: Color(0xFF118954),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}