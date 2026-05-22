import 'package:flutter/material.dart';
import 'package:nexabook/page/explore_page.dart';
import 'package:nexabook/main.dart';
import '../helper/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedNav = 0;
  List<Map<String, dynamic>> _bookings = [];
  int _bookingCount = 0;
  int _favoriteCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final email = DatabaseHelper.currentUserEmail;
    if (email != null) {
      final bks = await DatabaseHelper.instance.getBookings(email);
      final bCount = await DatabaseHelper.instance.getBookingCount(email);
      final fCount = await DatabaseHelper.instance.getFavoriteCount(email);
      if (mounted) {
        setState(() {
          _bookings = bks;
          _bookingCount = bCount;
          _favoriteCount = fCount;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _bookings = [];
          _bookingCount = 0;
          _favoriteCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  String _getUserDisplayName() {
    final email = DatabaseHelper.currentUserEmail ?? 'naufal@gmail.com';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: IndexedStack(
          index: selectedNav,
          children: [
            _buildHomeTab(),
            const ExplorePage(),
            _buildBookingTab(),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.08),
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
    );
  }

  // ICON BUTTON
  Widget iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFF2C3E50)),
    );
  }

  // KATEGORY ITEM
  Widget categoryItem(String title, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity( 0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  // VENDOR CARD
  Widget vendorCard(
    String name,
    String location,
    String rating,
    String price,
    String image,
  ) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
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
    );
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
    return Column(
      children: [
        // APP BAR
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity( 0.03),
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
              ),
              // ICON
              Row(
                children: [
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity( 0.04),
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
              const Text(
                "Kategori",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
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
                    ),
                    categoryItem(
                      "Engagement",
                      "assets/images/engagement.png",
                    ),
                    categoryItem(
                      "Prewed",
                      "assets/images/prewedding.png",
                    ),
                    categoryItem(
                      "Graduation",
                      "assets/images/graduation.png",
                    ),
                    categoryItem(
                      "Lainnya",
                      "assets/images/lainnya.png",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // REKOMENDASI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Rekomendasi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
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
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    vendorCard(
                      "Nexa Visual",
                      "Pamekasan",
                      "4.9",
                      "Mulai Rp3.500K",
                      "assets/images/nexavisual.png",
                    ),
                    vendorCard(
                      "Kisah Kita",
                      "Sumenep",
                      "4.8",
                      "Mulai Rp2.800K",
                      "assets/images/kisahkita.png",
                    ),
                    vendorCard(
                      "Arsip Kita",
                      "Madura",
                      "5.0",
                      "Mulai Rp2.500K",
                      "assets/images/arsipkita.png",
                    ),
                  ],
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

  // 1. MOCKUP TAB JADWAL / BOOKING (Premium UI)
  Widget _buildBookingTab() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF118954)),
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            "Jadwal Booking",
            style: TextStyle(color: Color(0xFF118954), fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF118954).withOpacity( 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Color(0xFF118954),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Belum Ada Booking",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Anda belum memesan layanan vendor apa pun. Temukan fotografer atau videografer terbaik Anda sekarang!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF118954),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedNav = 1; // Pindah ke tab Eksplorasi
                      });
                    },
                    child: const Text(
                      "Mulai Jelajahi Vendor",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Jadwal Booking",
          style: TextStyle(color: Color(0xFF118954), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20).copyWith(bottom: 100),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final bk = _bookings[index];
          
          Color statusColor = Colors.grey;
          final status = bk['status']?.toString() ?? 'Aktif';
          if (status == 'Aktif') {
            statusColor = const Color(0xFF118954);
          } else if (status.contains('Konfirmasi') || status.contains('Pending')) {
            statusColor = Colors.orange;
          } else if (status == 'Selesai') {
            statusColor = Colors.blue;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity( 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bk['booking_code']?.toString() ?? 'BK-XXXXX',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity( 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bk['name']?.toString() ?? 'Vendor',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bk['type']?.toString() ?? 'Session',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        bk['date']?.toString() ?? '',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        bk['price']?.toString() ?? '',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF118954), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF118954)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedNav = 3; // Switch to chat
                            });
                          },
                          child: const Text(
                            "Hubungi Vendor",
                            style: TextStyle(color: Color(0xFF118954), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF118954),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Invoice untuk ${bk['booking_code']} berhasil diunduh."),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF118954),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Invoice",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. MOCKUP TAB PESAN / CHAT (Premium UI)
  Widget _buildChatTab() {
    final List<Map<String, dynamic>> chats = [
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
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
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final ch = chats[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity( 0.01), blurRadius: 6),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: (ch['color'] as Color).withOpacity( 0.15),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 16),
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
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, overflow: TextOverflow.ellipsis),
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
              onTap: () {},
            ),
          );
        },
      ),
    );
  }

  // 3. MOCKUP TAB PROFIL & LOGOUT FUNGSIONAL (Premium UI)
  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
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
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Color(0xFF118954)),
                ),
                const SizedBox(height: 16),
                Text(
                  _getUserDisplayName(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  DatabaseHelper.currentUserEmail ?? 'naufal@gmail.com',
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
                    "${DatabaseHelper.currentUserRole ?? 'Pelanggan'} Premium",
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_bookingCount.toString(), "Total Booking"),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                _buildStatItem(_favoriteCount.toString(), "Favorit"),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                _buildStatItem("12", "Obrolan"),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildProfileMenuTile(Icons.person_outline, "Edit Profil"),
                const Divider(height: 1, indent: 56),
                _buildProfileMenuTile(Icons.notifications_none, "Notifikasi"),
                const Divider(height: 1, indent: 56),
                _buildProfileMenuTile(Icons.help_outline, "Pusat Bantuan"),
                const Divider(height: 1, indent: 56),
                _buildProfileMenuTile(Icons.info_outline, "Tentang Aplikasi"),
                const Divider(height: 1, indent: 56),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
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
    Color textColor = const Color(0xFF2C3E50),
    Color iconColor = const Color(0xFF118954),
    VoidCallback? onTap,
  }) {
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
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Konfirmasi Keluar",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          content: const Text("Apakah Anda yakin ingin keluar dari akun Anda saat ini?"),
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