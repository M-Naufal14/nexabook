import 'package:flutter/material.dart';
import '../helper/database_helper.dart';
import '../helper/image_helper.dart';
import '../main.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Stats
  int _totalPelanggan = 0;
  int _totalVendor = 0;
  int _totalBooking = 0;
  int _totalRevenue = 0;
  
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _users = [];
  
  bool _isLoading = true;

  Color _getScaffoldBg() => Theme.of(context).scaffoldBackgroundColor;
  Color _getCardBg() => Theme.of(context).cardColor;
  Color _getTextColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF0F172A);
  Color _getBorderColor() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF334155)
      : Colors.grey.shade200;
  Color _getTextSubColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;
    final allUsers = await db.getAllUsersAdmin();
    final allVendors = await db.getVendors();
    final allBookings = await db.getAllBookingsAdmin();

    // Calculate stats
    int pelangganCount = allUsers.where((u) => u['role'] == 'Pelanggan').length;
    int vendorCount = allVendors.length;
    int bookingCount = allBookings.length;
    
    // Calculate total revenue from 'Selesai' bookings
    int revenue = 0;
    for (final bk in allBookings) {
      if (bk['status'] == 'Selesai') {
        final priceStr = bk['price'] as String? ?? 'Rp0';
        // Clean price string, e.g. Rp3.500.000 -> 3500000
        final cleanPrice = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
        revenue += int.tryParse(cleanPrice) ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _users = allUsers;
        _vendors = allVendors;
        _bookings = allBookings;
        _totalPelanggan = pelangganCount;
        _totalVendor = vendorCount;
        _totalBooking = bookingCount;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    }
  }

  String _formatIDR(int amount) {
    if (amount == 0) return 'Rp0';
    final buffer = StringBuffer();
    final str = amount.toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp${buffer.toString().split('').reversed.join('')}';
  }

  Future<void> _handleDeleteVendor(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Moderasi Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus Vendor "$name"? Tindakan ini juga akan menghapus seluruh data booking terkait vendor tersebut.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await DatabaseHelper.instance.deleteVendor(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor "$name" berhasil dihapus dari platform.'),
            backgroundColor: const Color(0xFF118954),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAdminData();
      }
    }
  }

  Future<void> _handleDeleteUser(int id, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Moderasi Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus pengguna "$email"? Semua riwayat booking & favorit miliknya akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await DatabaseHelper.instance.deleteUser(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengguna "$email" berhasil dihapus dari platform.'),
            backgroundColor: const Color(0xFF118954),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAdminData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus pengguna (Admin tidak dapat dihapus).'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdateBookingStatus(int id, String code, String currentStatus) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Perbarui Status $code', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Aktif'),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: Color(0xFF118954)),
                SizedBox(width: 12),
                Text('Aktif / Pending', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Selesai'),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue),
                SizedBox(width: 12),
                Text('Selesai / Lunas', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Dibatalkan'),
            child: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.redAccent),
                SizedBox(width: 12),
                Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      final success = await DatabaseHelper.instance.updateBookingStatus(id, newStatus);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status booking $code berhasil diperbarui ke "$newStatus".'),
            backgroundColor: const Color(0xFF118954),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAdminData();
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        content: const Text('Apakah Anda yakin ingin keluar dari Admin Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              DatabaseHelper.currentUserEmail = null;
              DatabaseHelper.currentUserRole = null;
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SplashPage()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      appBar: AppBar(
        backgroundColor: _getScaffoldBg(),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexabook Admin',
                  style: TextStyle(color: _getTextColor(), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Platform Moderasi Jasa Visual',
                  style: TextStyle(color: _getTextSubColor(), fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _loadAdminData,
            tooltip: 'Segarkan Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _showLogoutDialog,
            tooltip: 'Keluar',
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: _getTextSubColor(),
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Beranda'),
            Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Booking'),
            Tab(icon: Icon(Icons.storefront_outlined, size: 20), text: 'Vendor'),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Pengguna'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBookingsTab(),
                _buildVendorsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  // 1. OVERVIEW / DASHBOARD TAB
  Widget _buildOverviewTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Welcome Alert
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF118954), Color(0xFF0F7C4C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF118954).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang di Admin Panel',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Kelola, pantau, dan moderasi seluruh aktivitas transaksi pemesanan serta vendor visual Anda secara real-time.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 30),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // STATS GRID
        Text(
          'Statistik Ringkas Platform',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getTextColor()),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              'Total Omzet',
              _formatIDR(_totalRevenue),
              Icons.monetization_on,
              Colors.green,
            ),
            _buildStatCard(
              'Total Booking',
              _totalBooking.toString(),
              Icons.shopping_bag,
              Colors.blue,
            ),
            _buildStatCard(
              'Pelanggan Aktif',
              _totalPelanggan.toString(),
              Icons.people,
              Colors.orange,
            ),
            _buildStatCard(
              'Vendor Terdaftar',
              _totalVendor.toString(),
              Icons.storefront,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // LATEST TRANSACTIONS SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Booking Terbaru Platform',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getTextColor()),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _bookings.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Center(child: Text('Belum ada transaksi di platform.', style: TextStyle(color: _getTextSubColor()))),
              )
            : Container(
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookings.length > 5 ? 5 : _bookings.length,
                  separatorBuilder: (context, i) => Divider(height: 1, color: _getBorderColor()),
                  itemBuilder: (context, i) {
                    final bk = _bookings[i];
                    Color statusColor = Colors.grey;
                    if (bk['status'] == 'Aktif') {
                      statusColor = const Color(0xFF10B981);
                    } else if (bk['status'] == 'Selesai') {
                      statusColor = Colors.blue;
                    } else if (bk['status'] == 'Dibatalkan') {
                      statusColor = Colors.redAccent;
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        bk['name'] ?? 'Vendor Jasa',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${bk['booking_code']} • ${bk['user_email']}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bk['price'] ?? 'Rp0',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bk['status'] ?? 'Aktif',
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: _getTextSubColor(), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 2. BOOKINGS TAB (Full List with search and actions)
  Widget _buildBookingsTab() {
    return _bookings.isEmpty
        ? Center(child: Text('Belum ada pesanan yang masuk.', style: TextStyle(color: _getTextSubColor())))
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _bookings.length,
            itemBuilder: (context, i) {
              final bk = _bookings[i];
              Color statusColor = Colors.grey;
              if (bk['status'] == 'Aktif') {
                statusColor = const Color(0xFF10B981);
              } else if (bk['status'] == 'Selesai') {
                statusColor = Colors.blue;
              } else if (bk['status'] == 'Dibatalkan') {
                statusColor = Colors.redAccent;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bk['booking_code'] ?? 'BK-XXXXX',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _getTextSubColor()),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bk['status'] ?? 'Aktif',
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bk['name'] ?? 'Vendor Jasa',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getTextColor()),
                      ),
                      const SizedBox(height: 6),
                      Text('Pemesan: ${bk['user_email']}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                      Text('Layanan: ${bk['type']}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                      Text('Tanggal Sesi: ${bk['date']}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                      const SizedBox(height: 12),
                      Divider(color: _getBorderColor()),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bk['price'] ?? 'Rp0',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _handleUpdateBookingStatus(bk['id'], bk['booking_code'], bk['status']),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // 3. VENDORS TAB (Manage & Moderate Vendors)
  Widget _buildVendorsTab() {
    return _vendors.isEmpty
        ? Center(child: Text('Belum ada vendor terdaftar.', style: TextStyle(color: _getTextSubColor())))
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _vendors.length,
            itemBuilder: (context, i) {
              final vd = _vendors[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: NexaImage(
                      imagePath: vd['image'] ?? 'assets/images/bg.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 50,
                        height: 50,
                        color: _getScaffoldBg(),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          vd['name'] ?? 'Nama Vendor',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vd['type'] ?? 'Fotografer',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pemilik: ${vd['owner_email'] ?? "- (Placeholder)"}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(vd['location'] ?? 'Lokasi', style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('${vd['rating']} (${vd['reviews']} ulasan)', style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _handleDeleteVendor(vd['id'], vd['name']),
                  ),
                ),
              );
            },
          );
  }

  // 4. USERS TAB (Manage & Delete Users)
  Widget _buildUsersTab() {
    return _users.isEmpty
        ? Center(child: Text('Belum ada pengguna terdaftar.', style: TextStyle(color: _getTextSubColor())))
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _users.length,
            itemBuilder: (context, i) {
              final us = _users[i];
              Color roleColor = Colors.grey;
              if (us['role'] == 'Admin') {
                roleColor = Colors.redAccent;
              } else if (us['role'] == 'Vendor') {
                roleColor = const Color(0xFF10B981);
              } else if (us['role'] == 'Pelanggan') {
                roleColor = Colors.blue;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.12),
                    child: Icon(
                      us['role'] == 'Admin'
                          ? Icons.admin_panel_settings
                          : us['role'] == 'Vendor'
                              ? Icons.storefront
                              : Icons.person,
                      color: roleColor,
                    ),
                  ),
                  title: Text(
                    us['email'] ?? 'User Email',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Password: ${us['password']}', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          us['role'] ?? 'Pelanggan',
                          style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (us['role'] != 'Admin') ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _handleDeleteUser(us['id'], us['email']),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }
}
