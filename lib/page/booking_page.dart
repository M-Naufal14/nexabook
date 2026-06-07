import 'package:flutter/material.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../helper/image_helper.dart';
import 'vendor_chat_room_page.dart';


class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'Semua';

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
    _loadData();
  }

  Future<void> _loadData() async {
    final email = FirebaseSqliteHelper.currentUserEmail;
    if (email != null) {
      final bks = await FirebaseSqliteHelper.instance.getBookings(email);
      if (mounted) {
        setState(() {
          _bookings = bks;
          _isLoading = false;
        });
        _applyFilter();
      }
    } else {
      if (mounted) {
        setState(() {
          _bookings = [];
          _isLoading = false;
        });
        _applyFilter();
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedStatusFilter == 'Semua') {
        _filteredBookings = _bookings;
      } else if (_selectedStatusFilter == 'Menunggu') {
        _filteredBookings = _bookings.where((b) => b['status'] == 'Menunggu').toList();
      } else if (_selectedStatusFilter == 'Dikonfirmasi') {
        // Map database status 'Aktif' and 'Dikonfirmasi' to the Dikonfirmasi filter
        _filteredBookings = _bookings.where((b) => b['status'] == 'Aktif' || b['status'] == 'Dikonfirmasi').toList();
      } else if (_selectedStatusFilter == 'Selesai') {
        _filteredBookings = _bookings.where((b) => b['status'] == 'Selesai').toList();
      } else if (_selectedStatusFilter == 'Dibatalkan') {
        _filteredBookings = _bookings.where((b) => b['status'] == 'Dibatalkan').toList();
      }
    });
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedStatusFilter = newFilter;
    });
    _applyFilter();
  }

  Future<void> _cancelBooking(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardBg(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin membatalkan pesanan "$code"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await FirebaseSqliteHelper.instance.updateBookingStatus(id, 'Dibatalkan');
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan $code berhasil dibatalkan.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APP HEADER BAR (Visual Match to Screenshot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _getScaffoldBg(),
                border: Border(
                  bottom: BorderSide(color: _getBorderColor(), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger Drawer Trigger
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                  ),

                  // BRAND TITLE CENTERED
                  const Text(
                    "NexaBook",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Color(0xFF10B981),
                    ),
                  ),

                  // NOTIFICATION BELL (Stack with badge dot)
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SUB HEADER (Booking Saya Title & Description)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking Saya",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _getTextColor(),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Kelola semua jadwal acara dan vendor Anda di sini.",
                    style: TextStyle(
                      fontSize: 13,
                      color: _getTextSubColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // FILTER CHIPS ROW (Scrollable Horizontal Chips)
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip('Semua'),
                  _buildFilterChip('Menunggu'),
                  _buildFilterChip('Dikonfirmasi'),
                  _buildFilterChip('Selesai'),
                  _buildFilterChip('Dibatalkan'),
                ],
              ),
            ),

            // BOOKINGS CONTENT AREA
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  : _filteredBookings.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final bk = _filteredBookings[index];
                            return _buildBookingCard(bk);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDER: FILTER CHIP
  Widget _buildFilterChip(String filterName) {
    final isSelected = _selectedStatusFilter == filterName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onFilterChanged(filterName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : _getBorderColor(),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            filterName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET BUILDER: EMPTY STATE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 60,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Belum Ada Booking",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Anda belum memesan layanan vendor apa pun di kategori $_selectedStatusFilter.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _getTextSubColor(),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDER: PREMIUM BOOKING CARD
  Widget _buildBookingCard(Map<String, dynamic> bk) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = bk['status']?.toString() ?? 'Aktif';
    
    // Status visual mapping based on design guidelines
    String displayStatusText = 'Dikonfirmasi';
    Color badgeBgColor = const Color(0xFF10B981).withOpacity(0.2);
    Color badgeTextColor = const Color(0xFF10B981);

    if (status == 'Menunggu') {
      displayStatusText = 'Menunggu';
      badgeBgColor = isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade200;
      badgeTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    } else if (status == 'Selesai') {
      displayStatusText = 'Selesai';
      badgeBgColor = isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50;
      badgeTextColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    } else if (status == 'Dibatalkan') {
      displayStatusText = 'Dibatalkan';
      badgeBgColor = Colors.redAccent.withOpacity(0.15);
      badgeTextColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD IMAGE WITH OVERLAY BADGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: NexaImage(
                  imagePath: bk['image'] ?? 'assets/images/bg.png',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => Container(
                    height: 160,
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    child: const Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),
              ),

              // COVER GRADIENT OVERLAY
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // Melayang Status Badge (Top Right)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatusText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // CARD DETAILS
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Name
                Text(
                  bk['name']?.toString() ?? 'Vendor Jasa',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _getTextColor(),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Calendar & Session Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: _getTextSubColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bk['date']?.toString() ?? 'Jadwal belum diset',
                        style: TextStyle(
                          fontSize: 13,
                          color: _getTextSubColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _getTextSubColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bk['location']?.toString() ?? 'Lokasi tidak dispesifikasi',
                        style: TextStyle(
                          fontSize: 13,
                          color: _getTextSubColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: _getBorderColor(), height: 1),
                const SizedBox(height: 16),

                // CARD STATUS SENSITIVE BUTTON ROWS
                _buildActionButtons(bk, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: ACTIONS BUTTONS
  Widget _buildActionButtons(Map<String, dynamic> bk, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = bk['id'] as int? ?? 0;
    final code = bk['booking_code']?.toString() ?? 'BK-XXXX';

    // 1. STATUS SELESAI -> Dialog Beri Ulasan dengan rating bintang
    if (status == 'Selesai') {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _getBorderColor(), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            int _selectedRating = 5;
            final TextEditingController _reviewController = TextEditingController();
            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Column(
                    children: [
                      Text(
                        'Beri Ulasan',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bk['name']?.toString() ?? 'Vendor',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Seberapa puas Anda dengan layanan ini?', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return GestureDetector(
                            onTap: () => setDialogState(() => _selectedRating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i < _selectedRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Ceritakan pengalaman Anda... (opsional)',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _getBorderColor()),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ulasan $_selectedRating bintang untuk ${bk['name']} berhasil dikirim!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.star_border, color: Color(0xFF10B981), size: 18),
          label: Text(
            'Beri Ulasan',
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // 2. STATUS MENUNGGU -> Detail + Batalkan (outlined)
    if (status == 'Menunggu') {
      return Row(
        children: [
          // Detail button
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showBookingDetailsDialog(bk),
                child: Text(
                  'Detail',
                  style: TextStyle(
                    color: _getTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Batalkan button
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _cancelBooking(id, code),
                child: const Text(
                  'Batalkan',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 3. STATUS DIBATALKAN -> Show simple details only
    if (status == 'Dibatalkan') {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _showBookingDetailsDialog(bk),
          child: Text(
            'Lihat Detail Pembatalan',
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // 4. STATUS AKTIF / DIKONFIRMASI -> Detail + Chat Vendor (Emerald Green)
    return Row(
      children: [
        // Detail button
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showBookingDetailsDialog(bk),
              child: Text(
                'Detail',
                style: TextStyle(
                  color: _getTextColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Chat Vendor button -> navigasi ke VendorChatRoomPage
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final vendorName = bk['name']?.toString() ?? 'Vendor';
                final initials = vendorName.length >= 2
                    ? vendorName.substring(0, 2).toUpperCase()
                    : vendorName.substring(0, 1).toUpperCase();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorChatRoomPage(
                      clientName: vendorName,
                      clientInitial: initials,
                    ),
                  ),
                );
              },
              child: const Text(
                'Chat Vendor',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DIALOG BUILDER: BOOKING DETAILS POPUP
  void _showBookingDetailsDialog(Map<String, dynamic> bk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _getCardBg(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rincian Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bk['booking_code']?.toString() ?? 'BK-XXXX',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Vendor', bk['name']?.toString() ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Layanan', bk['type']?.toString() ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Tanggal & Waktu', bk['date']?.toString() ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Lokasi Pelaksanaan', bk['location']?.toString() ?? '-'),
            const Divider(height: 24),
            _buildDetailRow('Total Pembayaran', bk['price']?.toString() ?? '-', isBold: true),
            const Divider(height: 24),
            _buildDetailRow('Status Pesanan', bk['status']?.toString() ?? 'Aktif', isStatus: true),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invoice untuk ${bk['booking_code']} berhasil diunduh."),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                child: const Text(
                  'Unduh Invoice PDF',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isStatus = false}) {
    Color valColor = _getTextColor();
    if (isStatus) {
      valColor = const Color(0xFF10B981);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: _getTextSubColor(), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valColor,
              fontWeight: isBold || isStatus ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ),
      ],
    );
  }
}
