import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexabook/page/explore_page.dart';
import 'package:nexabook/page/booking_page.dart';
import 'package:nexabook/page/booking_flow_page.dart';
import 'package:nexabook/page/vendor_chat_room_page.dart';
import 'package:nexabook/main.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../helper/image_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedNav = 0;
  int _bookingCount = 0;
  int _favoriteCount = 0;
  String? _userProfileImage;
  List<Map<String, dynamic>> _recommendations = [];

  final List<Map<String, dynamic>> _mockChats = [
    {
      'initials': 'NV',
      'name': 'Nexa Visual',
      'msg': 'Halo kak, untuk tanggal 24 Mei jadwal kami masih kosong...',
      'time': '10:30',
      'unread': 2,
      'color': Colors.blue,
    },
    {
      'initials': 'KK',
      'name': 'Kisah Kita',
      'msg': 'Baik kak, data pesanan Anda sudah masuk sistem...',
      'time': 'Kemarin',
      'unread': 0,
      'color': Colors.orange,
    },
    {
      'initials': 'AK',
      'name': 'Arsip Kita',
      'msg': 'Sama-sama kak, nanti hasil videonya kami upload ke drive...',
      'time': '19 Mei',
      'unread': 0,
      'color': Colors.purple,
    }
  ];

  Color _getScaffoldBg() => Theme.of(context).scaffoldBackgroundColor;
  Color _getCardBg() => Theme.of(context).cardColor;
  Color _getTextColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF2C3E50);
  Color _getBorderColor() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF334155)
      : Colors.grey.shade200;
  Color _getTextSubColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final email = FirebaseSqliteHelper.currentUserEmail;
    if (email != null) {
      final bCount = await FirebaseSqliteHelper.instance.getBookingCount(email);
      final fCount = await FirebaseSqliteHelper.instance.getFavoriteCount(email);
      final uImg = await FirebaseSqliteHelper.instance.getUserImage(email);
      final recs = await FirebaseSqliteHelper.instance.getVendors(sortBy: 'Rating Tertinggi');
      if (mounted) {
        setState(() {
          _bookingCount = bCount;
          _favoriteCount = fCount;
          _userProfileImage = uImg;
          _recommendations = recs.take(5).toList();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _bookingCount = 0;
          _favoriteCount = 0;
          _userProfileImage = null;
          _recommendations = [];
        });
      }
    }
  }

  void _selectProfilePhoto() {
    final presets = [
      'assets/images/bg.png',
      'assets/images/bg1.png',
      'assets/images/bg2.png',
      'assets/images/nexavisual.png',
      'assets/images/kisahkita.png',
      'assets/images/arsipkita.png',
    ];
    final TextEditingController customUrlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _getCardBg(),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Foto Profil Anda',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor()),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil dari Galeri HP / Kamera:',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF118954),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1000,
                              maxHeight: 1000,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              final email = FirebaseSqliteHelper.currentUserEmail;
                              if (email != null) {
                                await FirebaseSqliteHelper.instance.updateUserImage(email, image.path);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadData();
                                }
                              }
                            }
                          } catch (e) {
                            debugPrint("Error picking image: $e");
                          }
                        },
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        label: const Text('Buka Galeri', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1000,
                              maxHeight: 1000,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              final email = FirebaseSqliteHelper.currentUserEmail;
                              if (email != null) {
                                await FirebaseSqliteHelper.instance.updateUserImage(email, image.path);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadData();
                                }
                              }
                            }
                          } catch (e) {
                            debugPrint("Error taking photo: $e");
                          }
                        },
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Atau Gunakan URL Gambar Kustom:',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customUrlController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan link gambar kustom (https://...)',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF118954), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF118954),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final customUrl = customUrlController.text.trim();
                        if (customUrl.isNotEmpty) {
                           final email = FirebaseSqliteHelper.currentUserEmail;
                           if (email != null) {
                             await FirebaseSqliteHelper.instance.updateUserImage(email, customUrl);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          }
                        }
                      },
                      child: const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Atau Pilihan Preset Premium:',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final img = presets[index];
                    return GestureDetector(
                      onTap: () async {
                        final email = FirebaseSqliteHelper.currentUserEmail;
                        if (email != null) {
                          await FirebaseSqliteHelper.instance.updateUserImage(email, img);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadData();
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(img, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserDisplayName() {
    final email = FirebaseSqliteHelper.currentUserEmail ?? 'naufal@gmail.com';
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      final username = parts[0];
      final nameParts = username.split(RegExp(r'[._-]'));
      final formattedName = nameParts.map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + part.substring(1);
      }).join(' ');
      return formattedName;
    }
    return 'Pengguna Nexabook';
  }

  Widget _buildSideDrawer() {
    final role = FirebaseSqliteHelper.currentUserRole ?? 'Pelanggan';
    final email = FirebaseSqliteHelper.currentUserEmail ?? 'naufal@gmail.com';
    
    return Drawer(
      backgroundColor: _getScaffoldBg(),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _getBorderColor(), width: 0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                    backgroundImage: _userProfileImage != null ? getCustomImageProvider(_userProfileImage!) : null,
                    child: _userProfileImage == null ? const Icon(Icons.person, color: Color(0xFF10B981)) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getUserDisplayName(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor(), fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawer Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildDrawerItem(Icons.home_outlined, 'Dashboard Utama', 0),
                  _buildDrawerItem(Icons.explore_outlined, 'Jelajahi Vendor', 1),
                  _buildDrawerItem(Icons.calendar_today_outlined, 'Booking Saya', 2),
                  _buildDrawerItem(Icons.chat_bubble_outline, 'Pesan / Obrolan', 3),
                  _buildDrawerItem(Icons.person_outline, 'Profil & Pengaturan', 4),
                  
                  const Divider(height: 24),
                  
                  // Portal items based on Role
                  if (role == 'Admin')
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blue),
                      title: const Text('Portal Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin-portal');
                      },
                    )
                  else if (role == 'Vendor')
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined, color: Color(0xFF10B981)),
                      title: const Text('Portal Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/vendor-portal');
                      },
                    )
                  else // Pelanggan/Customer has option to upgrade/become vendor
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined, color: Colors.amber),
                      title: const Text('Portal Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Daftar/Kelola Jasa Visual Anda', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/vendor-portal');
                      },
                    ),
                ],
              ),
            ),
            
            // Footer with theme toggle & logout
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _getBorderColor(), width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleButton(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    label: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int tabIndex) {
    final active = selectedNav == tabIndex;
    final activeColor = const Color(0xFF10B981);
    
    return ListTile(
      leading: Icon(icon, color: active ? activeColor : Colors.grey, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: active ? activeColor : _getTextColor(),
        ),
      ),
      selected: active,
      selectedTileColor: activeColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedNav = tabIndex;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (selectedNav != 0) {
          setState(() {
            selectedNav = 0;
          });
        } else {
          final exitApp = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _getCardBg(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Keluar Aplikasi',
                style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
              ),
              content: Text(
                'Apakah Anda yakin ingin keluar dari aplikasi NexaBook?',
                style: TextStyle(color: _getTextColor()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (exitApp == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _getScaffoldBg(),
        drawer: _buildSideDrawer(),
        body: SafeArea(
          child: IndexedStack(
            index: selectedNav,
            children: [
              _buildHomeTab(),
              const ExplorePage(),
              const BookingPage(),
              _buildChatTab(),
              _buildProfileTab(),
            ],
          ),
        ),

        // FLOATING NAVBAR
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home, 0),
              navItem(Icons.explore, 1),
              navItem(Icons.calendar_today, 2),
              navItem(Icons.chat_bubble_outline, 3),
              navItem(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  // ICON BUTTON
  Widget iconButton(IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: _getTextColor()),
    );
  }

  // KATEGORY ITEM
  Widget categoryItem(String title, String imagePath, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF118954)
                    : const Color(0xFF118954).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
              color: isDark ? Colors.white : null,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    ));
  }

  // VENDOR CARD
  Widget vendorCard(
    String name,
    String location,
    String rating,
    String price,
    String image, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF118954)
              : const Color(0xFF118954).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Image.asset(
              image,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF118954),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(
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
    ));
  }

  // NAV ITEM
  Widget navItem(IconData icon, int index) {
    bool active = selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedNav = index;
        });
        if (index == 0 || index == 2 || index == 4) {
          _loadData();
        }
      },
      child: Icon(
        icon,
        size: 28,
        color: active ? const Color(0xFF118954) : Colors.grey,
      ),
    );
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // APP BAR
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: _getCardBg(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LOGO
              Image.asset(
                "assets/images/logo1.png",
                width: 110,
                color: isDark ? Colors.white : null,
              ),
              // ICON
              Row(
                children: [
                  const ThemeToggleButton(),
                  const SizedBox(width: 8),
                  iconButton(Icons.notifications_none),
                  const SizedBox(width: 12),
                  iconButton(Icons.chat_bubble_outline),
                ],
              ),
            ],
          ),
        ),

        // BODY
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // BANNER ATAS
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  image: const DecorationImage(
                    image: AssetImage(
                      "assets/images/bg2.png",
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity( 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity( 0.15),
                        Colors.black.withOpacity( 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      const Text(
                        "Temukan Vendor\nTerbaik Untuk\nMomen Spesialmu",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF118954),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedNav = 1; // Switches directly to Explore page tab!
                            });
                          },
                          child: const Text(
                            "Jelajahi Sekarang",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SEARCH BAR (Interactive)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedNav = 1; // Switches to explore tab for searching
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: _getCardBg(),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF118954)
                          : const Color(0xFF118954).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF118954)),
                      const SizedBox(width: 12),
                      Text(
                        "Cari fotografer atau videografer...",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // KATEGORI
              Text(
                "Kategori",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),

              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    categoryItem(
                      "Wedding",
                      "assets/images/wedding.png",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage(initialSearchQuery: 'Wedding', showBackButton: true))),
                    ),
                    categoryItem(
                      "Engagement",
                      "assets/images/engagement.png",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage(initialSearchQuery: 'Engagement', showBackButton: true))),
                    ),
                    categoryItem(
                      "Prewed",
                      "assets/images/prewedding.png",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage(initialSearchQuery: 'Prewed', showBackButton: true))),
                    ),
                    categoryItem(
                      "Graduation",
                      "assets/images/graduation.png",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage(initialSearchQuery: 'Graduation', showBackButton: true))),
                    ),
                    categoryItem(
                      "Lainnya",
                      "assets/images/lainnya.png",
                      onTap: () {
                        setState(() { selectedNav = 1; });
                      }
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // REKOMENDASI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rekomendasi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedNav = 1;
                      });
                    },
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(
                        color: Color(0xFF118954),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final vendor = _recommendations[index];
                    return vendorCard(
                      vendor['name'] ?? '',
                      vendor['location'] ?? '',
                      vendor['rating']?.toString() ?? '0',
                      vendor['price'] ?? '',
                      vendor['image'] ?? 'assets/images/bg.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingFlowPage(vendor: vendor),
                          ),
                        ).then((_) {
                          _loadData(); // refresh bookings when coming back
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // PROMO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF118954),
                      Color(0xFF0D6E43),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Diskon Hingga 50%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Booking vendor favoritmu sekarang juga.",
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity( 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }



  // 2. MOCKUP TAB PESAN / CHAT (Premium UI)
  Widget _buildChatTab() {

    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      appBar: AppBar(
        backgroundColor: _getScaffoldBg(),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Pesan",
          style: TextStyle(color: Color(0xFF118954), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        itemCount: _mockChats.length,
        itemBuilder: (context, index) {
          final ch = _mockChats[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor()),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.01), blurRadius: 6),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: (ch['color'] as Color).withOpacity(0.15),
                child: Text(
                  ch['initials'],
                  style: TextStyle(color: ch['color'] as Color, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ch['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor(), fontSize: 16),
                  ),
                  Text(
                    ch['time'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ch['msg'],
                        style: TextStyle(color: _getTextSubColor(), fontSize: 13, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (ch['unread'] > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF118954), shape: BoxShape.circle),
                        child: Text(
                          "${ch['unread']}",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () {
                // Navigate to existing vendor chat room page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorChatRoomPage(
                      clientName: ch['name'],
                      clientInitial: ch['initials'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 3. MOCKUP TAB PROFIL & LOGOUT FUNGSIONAL (Premium UI)
  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      appBar: AppBar(
        backgroundColor: _getScaffoldBg(),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profil Saya",
          style: TextStyle(color: Color(0xFF118954), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        children: [
          // Profil Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF118954), Color(0xFF0F7C4C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF118954).withOpacity( 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selectProfilePhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _userProfileImage != null
                            ? getCustomImageProvider(_userProfileImage!)
                            : null,
                        child: _userProfileImage == null
                            ? const Icon(Icons.person, size: 50, color: Color(0xFF118954))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF118954), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getUserDisplayName(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseSqliteHelper.currentUserEmail ?? 'naufal@gmail.com',
                  style: TextStyle(color: Colors.white.withOpacity( 0.8), fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity( 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${FirebaseSqliteHelper.currentUserRole ?? 'Pelanggan'} Premium",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_bookingCount.toString(), "Total Booking"),
                Container(width: 1, height: 30, color: _getBorderColor()),
                _buildStatItem(_favoriteCount.toString(), "Favorit"),
                Container(width: 1, height: 30, color: _getBorderColor()),
                _buildStatItem(_mockChats.length.toString(), "Obrolan"),
              ],
            ),
          ),
          const SizedBox(height: 24),



          // Menu Options
          Container(
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Column(
              children: [
                _buildProfileMenuTile(Icons.person_outline, "Edit Profil"),
                Divider(height: 1, indent: 56, color: _getBorderColor()),
                _buildProfileMenuTile(Icons.notifications_none, "Notifikasi"),
                Divider(height: 1, indent: 56, color: _getBorderColor()),
                _buildProfileMenuTile(Icons.help_outline, "Pusat Bantuan"),
                Divider(height: 1, indent: 56, color: _getBorderColor()),
                _buildProfileMenuTile(Icons.info_outline, "Tentang Aplikasi"),
                Divider(height: 1, indent: 56, color: _getBorderColor()),
                _buildProfileMenuTile(
                  Icons.logout,
                  "Keluar",
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor()),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProfileMenuTile(
    IconData icon,
    String title, {
    Color? textColor,
    Color iconColor = const Color(0xFF118954),
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTitleColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity( 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 14, 
          color: textColor ?? defaultTitleColor,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _getCardBg(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Konfirmasi Keluar",
            style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
          ),
          content: Text(
            "Apakah Anda yakin ingin keluar dari akun Anda saat ini?",
            style: TextStyle(color: _getTextSubColor()),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 20, right: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                // Clear session
                FirebaseSqliteHelper.currentUserEmail = null;
                FirebaseSqliteHelper.currentUserRole = null;

                // Route back to Splash/Start screen
                Navigator.pop(context); // close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashPage()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anda telah berhasil keluar.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}