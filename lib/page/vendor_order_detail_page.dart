import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../helper/database_helper.dart';
import 'vendor_chat_room_page.dart';


class VendorOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  const VendorOrderDetailPage({super.key, required this.booking});

  @override
  State<VendorOrderDetailPage> createState() => _VendorOrderDetailPageState();
}

class _VendorOrderDetailPageState extends State<VendorOrderDetailPage> {
  late Map<String, dynamic> _bookingData;
  bool _isUpdating = false;

  // Fallback dark palette constants
  static const Color kDarkBackground = Color(0xFF051424);
  static const Color kDarkSurfaceCard = Color(0xFF122131);
  static const Color kDarkPrimaryGreen = Color(0xFF3FE56C);
  static const Color kDarkOnPrimary = Color(0xFF003912);
  static const Color kDarkOnSurface = Color(0xFFD4E4FA);
  static const Color kDarkOnSurfaceVariant = Color(0xFFBBCBB8);
  static const Color kDarkBorderColor = Color(0x1FFFFFFF);

  @override
  void initState() {
    super.initState();
    _bookingData = Map<String, dynamic>.from(widget.booking);
  }

  // Format currencies dynamically based on the price format (Rp vs $)
  String _formatCurrency(double amount, String symbol) {
    if (symbol == '\$') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    
    // Indonesian Rupiah (Rp) formatting
    final intAmount = amount.toInt();
    final buffer = StringBuffer();
    final str = intAmount.toString();
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

  // Update status in database
  Future<void> _changeBookingStatus(String newStatus) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? kDarkPrimaryGreen : const Color(0xFF118954);

    final bookingId = _bookingData['id'] as int?;
    if (bookingId == null || bookingId == 9991 || bookingId == 9992 || bookingId == 9993 || bookingId == 8881 || bookingId == 8882 || bookingId == 8883) {
      // Mock booking update
      setState(() {
        _bookingData['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan simulasi diubah menjadi $newStatus.'),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);
    final success = await DatabaseHelper.instance.updateBookingStatus(bookingId, newStatus);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      setState(() {
        _bookingData['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan berhasil diperbarui ke "$newStatus".'),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status pesanan.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Dialog for editing/updating booking state
  void _showEditOptionsDialog() {
    final currentStatus = _bookingData['status']?.toString() ?? 'Aktif';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurfaceCard : Colors.white;
    final primaryGreen = isDark ? kDarkPrimaryGreen : const Color(0xFF118954);
    final textOnSurface = isDark ? kDarkOnSurface : const Color(0xFF0F172A);
    final textOnSurfaceVariant = isDark ? kDarkOnSurfaceVariant : const Color(0xFF64748B);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Status Pesanan',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Perbarui status pengerjaan jasa visual untuk klien.',
                style: TextStyle(color: textOnSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildStatusOptionItem('Aktif', currentStatus == 'Aktif' || currentStatus == 'Dikonfirmasi', () {
                Navigator.pop(context);
                _changeBookingStatus('Aktif');
              }, primaryGreen, textOnSurface, textOnSurfaceVariant, titleColor, isDark),
              _buildStatusOptionItem('Menunggu', currentStatus == 'Menunggu', () {
                Navigator.pop(context);
                _changeBookingStatus('Menunggu');
              }, primaryGreen, textOnSurface, textOnSurfaceVariant, titleColor, isDark),
              _buildStatusOptionItem('Selesai', currentStatus == 'Selesai', () {
                Navigator.pop(context);
                _changeBookingStatus('Selesai');
              }, primaryGreen, textOnSurface, textOnSurfaceVariant, titleColor, isDark),
              _buildStatusOptionItem('Dibatalkan', currentStatus == 'Dibatalkan', () {
                Navigator.pop(context);
                _changeBookingStatus('Dibatalkan');
              }, primaryGreen, textOnSurface, textOnSurfaceVariant, titleColor, isDark),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOptionItem(
    String status,
    bool isActive,
    VoidCallback onTap,
    Color primaryGreen,
    Color textOnSurface,
    Color textOnSurfaceVariant,
    Color titleColor,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isActive ? Icons.check_circle : Icons.radio_button_off,
        color: isActive ? primaryGreen : textOnSurfaceVariant,
      ),
      title: Text(
        status,
        style: TextStyle(
          color: isActive ? titleColor : textOnSurface,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Color Resolution
    final scaffoldBg = isDark ? kDarkBackground : const Color(0xFFF8FAFC);
    final cardColor = isDark ? kDarkSurfaceCard : Colors.white;
    final primaryGreen = isDark ? kDarkPrimaryGreen : const Color(0xFF118954);
    final onPrimary = isDark ? kDarkOnPrimary : Colors.white;
    final textOnSurface = isDark ? kDarkOnSurface : const Color(0xFF0F172A);
    final textOnSurfaceVariant = isDark ? kDarkOnSurfaceVariant : const Color(0xFF64748B);
    final borderColor = isDark ? kDarkBorderColor : const Color(0xFFE2E8F0);
    final mapBgColor = isDark ? const Color(0xFF0F1E2E) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // 1. Parse Status and Badge visual elements
    final rawStatus = _bookingData['status']?.toString() ?? 'Aktif';
    String displayStatusText = 'Active Order';
    Color badgeBgColor = primaryGreen.withOpacity(0.12);
    Color badgeTextColor = primaryGreen;

    if (rawStatus == 'Menunggu') {
      displayStatusText = 'Pending Order';
      badgeBgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
      badgeTextColor = textOnSurfaceVariant;
    } else if (rawStatus == 'Selesai') {
      displayStatusText = 'Completed Order';
      badgeBgColor = isDark ? Colors.blue.withOpacity(0.12) : Colors.blue.shade50;
      badgeTextColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    } else if (rawStatus == 'Dibatalkan') {
      displayStatusText = 'Cancelled Order';
      badgeBgColor = isDark ? Colors.redAccent.withOpacity(0.12) : Colors.red.shade50;
      badgeTextColor = isDark ? Colors.redAccent : Colors.red.shade600;
    }

    // 2. Extract service specifics
    final serviceType = _bookingData['type']?.toString() ?? 'Corporate Portraiture';
    final scheduledDate = _bookingData['date']?.toString() ?? 'October 24, 2023';
    final rawPriceString = _bookingData['price']?.toString() ?? 'Rp3.500.000';
    final bookingCode = _bookingData['booking_code']?.toString() ?? '#NX-882910';
    final serviceLocation = _bookingData['location']?.toString() ?? 'SCBD Sudirman, Jakarta Selatan';

    // 3. Financial breakdown parsing
    final currencySymbol = rawPriceString.startsWith('\$') ? '\$' : 'Rp';
    final cleanPriceText = rawPriceString.replaceAll(RegExp(r'[^0-9]'), '');
    final totalRevenue = double.tryParse(cleanPriceText) ?? 1015.0;

    final surcharge = totalRevenue * 0.05; // 5% fee
    final locationFee = rawPriceString.startsWith('\$') ? 120.0 : 150000.0; // location flat rate
    final baseRate = totalRevenue - surcharge - locationFee;

    // 4. Client details mapping
    final clientEmail = _bookingData['user_email']?.toString() ?? 'adrian.thorne@enterprise.com';
    final clientName = clientEmail.split('@')[0].toUpperCase();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textOnSurfaceVariant),
          onPressed: () {
            Navigator.pop(context, true); // Trigger reload on previous screen!
          },
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textOnSurfaceVariant),
            onPressed: _showEditOptionsDialog,
          ),
        ],
      ),
      body: _isUpdating
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Tag & Kode Order
                  _buildStatusHeader(displayStatusText, badgeBgColor, badgeTextColor, bookingCode, textOnSurfaceVariant),
                  const SizedBox(height: 8),

                  // Judul Layanan
                  Text(
                    serviceType,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tanggal Jadwal
                  Text(
                    "Scheduled for $scheduledDate",
                    style: TextStyle(
                      color: textOnSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Edit & Chat Client
                  _buildActionButtons(clientName, primaryGreen, onPrimary, cardColor, borderColor, titleColor),
                  const SizedBox(height: 24),

                  // Kartu Peta Taktis & Lokasi Detil
                  _buildMapLocationCard(serviceLocation, cardColor, borderColor, mapBgColor, scaffoldBg, primaryGreen, onPrimary, textOnSurfaceVariant, titleColor),
                  const SizedBox(height: 16),

                  // Profil Klien
                  _buildClientCard(clientName, clientEmail, cardColor, borderColor, primaryGreen, textOnSurface, textOnSurfaceVariant, titleColor),
                  const SizedBox(height: 16),

                  // Spesifikasi Layanan
                  _buildServiceSpecificsCard(serviceType, cardColor, borderColor, textOnSurfaceVariant, primaryGreen, textOnSurface, titleColor),
                  const SizedBox(height: 16),

                  // Ringkasan Transaksi Finansial
                  _buildFinancialsCard(baseRate, locationFee, surcharge, totalRevenue, currencySymbol, cardColor, borderColor, textOnSurfaceVariant, textOnSurface, primaryGreen, titleColor),
                  const SizedBox(height: 16),

                  // Catatan Klien (Notes)
                  _buildClientNotesCard(serviceType, cardColor, borderColor, textOnSurfaceVariant, textOnSurface),
                  const SizedBox(height: 60),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorChatRoomPage(
                clientName: clientName,
                clientInitial: clientName.isNotEmpty ? clientName[0] : 'C',
              ),
            ),
          );
        },
        shape: const CircleBorder(),
        child: Icon(
          Icons.chat_bubble,
          color: onPrimary,
        ),
      ),
    );
  }

  // Header Status Tag
  Widget _buildStatusHeader(String statusText, Color bg, Color text, String code, Color textOnSurfaceVariant) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: text.withOpacity(0.2)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          code,
          style: TextStyle(
            color: textOnSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Tombol Aksi Utama
  Widget _buildActionButtons(String clientName, Color primaryGreen, Color onPrimary, Color cardColor, Color borderColor, Color titleColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showEditOptionsDialog,
            icon: Icon(Icons.edit_outlined, color: titleColor, size: 20),
            label: Text(
              'Edit Status',
              style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: cardColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorChatRoomPage(
                    clientName: clientName,
                    clientInitial: clientName.isNotEmpty ? clientName[0] : 'C',
                  ),
                ),
              );
            },
            icon: Icon(Icons.chat_bubble_outline, color: onPrimary, size: 20),
            label: Text(
              'Chat Client',
              style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Tampilan Peta Digital
  Widget _buildMapLocationCard(
    String location,
    Color cardColor,
    Color borderColor,
    Color mapBgColor,
    Color scaffoldBg,
    Color primaryGreen,
    Color onPrimary,
    Color textOnSurfaceVariant,
    Color titleColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Peta dengan Canvas Custom Drawing
          Container(
            height: 180,
            color: mapBgColor,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapGridPainter(primaryGreen: primaryGreen),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        scaffoldBg.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Informasi Lokasi Fisik & Tombol Rute
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVICE LOCATION',
                        style: TextStyle(
                          color: textOnSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location.split(',')[0],
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location.contains(',') ? location : "$location, Jawa Timur",
                        style: TextStyle(
                          color: textOnSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Membuka rute ke $location di Google Maps..."),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: primaryGreen,
                      ),
                    );
                  },
                  icon: Icon(Icons.directions_outlined, color: primaryGreen, size: 18),
                  label: Text(
                    'Open\nMaps',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profil Detail Klien
  Widget _buildClientCard(
    String name,
    String email,
    Color cardColor,
    Color borderColor,
    Color primaryGreen,
    Color textOnSurface,
    Color textOnSurfaceVariant,
    Color titleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CLIENT',
            style: TextStyle(
              color: textOnSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryGreen.withOpacity(0.3), width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=256",
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: textOnSurfaceVariant, size: 30);
                    },
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: textOnSurfaceVariant,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: textOnSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text(
                "Verified Enterprise Client",
                style: TextStyle(color: textOnSurface, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded, color: primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                "4.9 (12 previous orders)",
                style: TextStyle(color: textOnSurface, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Profil klien $name terverifikasi keamanan ESCROW."),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: primaryGreen,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'View Full Profile',
              style: TextStyle(color: textOnSurface, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Rincian Kategori Spesifik Layanan
  Widget _buildServiceSpecificsCard(
    String type,
    Color cardColor,
    Color borderColor,
    Color textOnSurfaceVariant,
    Color primaryGreen,
    Color textOnSurface,
    Color titleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SERVICE SPECIFICS',
            style: TextStyle(
              color: textOnSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecificRow(Icons.category_outlined, 'Service Type', type, primaryGreen, textOnSurface, titleColor),
          Divider(color: borderColor, height: 24),
          _buildSpecificRow(Icons.access_time_outlined, 'Duration', '4 Hours Session', primaryGreen, textOnSurface, titleColor),
          Divider(color: borderColor, height: 24),
          _buildSpecificRow(Icons.people_outline_outlined, 'Participants', 'Up to 10 People', primaryGreen, textOnSurface, titleColor),
          Divider(color: borderColor, height: 24),
          _buildSpecificRow(Icons.photo_library_outlined, 'Deliverables', '25 Retouched High-Res', primaryGreen, textOnSurface, titleColor, isLast: true),
        ],
      ),
    );
  }

  Widget _buildSpecificRow(
    IconData icon,
    String title,
    String value,
    Color primaryGreen,
    Color textOnSurface,
    Color titleColor, {
    bool isLast = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryGreen, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(color: textOnSurface, fontSize: 15),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Ringkasan Finansial Transaksi
  Widget _buildFinancialsCard(
    double base,
    double locationFee,
    double surcharge,
    double total,
    String symbol,
    Color cardColor,
    Color borderColor,
    Color textOnSurfaceVariant,
    Color textOnSurface,
    Color primaryGreen,
    Color titleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TRANSACTION SUMMARY',
            style: TextStyle(
              color: textOnSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          _buildFinancialRow('Base Rate', _formatCurrency(base, symbol), textOnSurface, textOnSurfaceVariant),
          const SizedBox(height: 10),
          _buildFinancialRow('On-location Fee', _formatCurrency(locationFee, symbol), textOnSurface, textOnSurfaceVariant),
          const SizedBox(height: 10),
          _buildFinancialRow('Platform Surcharge', _formatCurrency(surcharge, symbol), textOnSurface, textOnSurfaceVariant),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatCurrency(total, symbol),
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: primaryGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                     'Payment secured by NexaEscrow',
                     style: TextStyle(
                       color: primaryGreen,
                       fontSize: 12,
                       fontWeight: FontWeight.bold,
                     ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String title, String value, Color textOnSurface, Color textOnSurfaceVariant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: textOnSurfaceVariant, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(color: textOnSurface, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Teks Catatan Klien
  Widget _buildClientNotesCard(
    String type,
    Color cardColor,
    Color borderColor,
    Color textOnSurfaceVariant,
    Color textOnSurface,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CLIENT NOTES',
            style: TextStyle(
              color: textOnSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"Kami membutuhkan pengerjaan sesi $type dengan gaya sinematik, estetika modern, kontras tinggi, dan bernuansa gelap agar selaras dengan kebutuhan publikasi portofolio korporat kami. Mohon persiapkan peralatan pencahayaan tambahan untuk area pelaksanaan."',
            style: TextStyle(
              color: textOnSurface,
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk merender visual peta grid neon melingkar secara taktis
class _MapGridPainter extends CustomPainter {
  final Color primaryGreen;
  _MapGridPainter({required this.primaryGreen});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = primaryGreen.withOpacity(0.12)
      ..strokeWidth = 1.0;

    final Paint mainRoutePaint = Paint()
      ..color = primaryGreen.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double cx = size.width * 0.4;
    final double cy = size.height * 0.6;

    // Gambar garis kisi radial koordinat (radial street lines)
    for (int i = 0; i < 18; i++) {
      final double angle = (i * 20) * 3.14159 / 180;
      final double rx = cx + 300 * math.cos(angle);
      final double ry = cy + 300 * math.sin(angle);
      canvas.drawLine(Offset(cx, cy), Offset(rx, ry), linePaint);
    }

    // Gambar lingkaran radar konsentrik
    for (double r = 40; r < 240; r += 40) {
      canvas.drawCircle(Offset(cx, cy), r, linePaint..style = PaintingStyle.stroke);
    }

    // Gambar jalan raya organik neon utama (arterial tracks)
    final Path path1 = Path()
      ..moveTo(0, cy - 40)
      ..lineTo(cx - 50, cy - 20)
      ..quadraticBezierTo(cx - 20, cy - 10, cx, cy)
      ..lineTo(size.width, cy + 80);

    final Path path2 = Path()
      ..moveTo(cx + 100, 0)
      ..lineTo(cx + 20, cy - 120)
      ..lineTo(cx, cy)
      ..lineTo(0, size.height);

    canvas.drawPath(path1, mainRoutePaint..style = PaintingStyle.stroke);
    canvas.drawPath(path2, mainRoutePaint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
