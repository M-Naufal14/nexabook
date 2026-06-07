import 'package:flutter/material.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../helper/image_helper.dart';
import '../main.dart';
import 'home_page.dart';

class BookingFlowPage extends StatefulWidget {
  final Map<String, dynamic> vendor;

  const BookingFlowPage({super.key, required this.vendor});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  int _currentStep = 1; // Step 1: Detail, Step 2: Paket, Step 3: Form, Step 4: Bayar

  // Step 2 State
  String _selectedCategory = 'Foto'; // 'Foto', 'Video', 'Foto + Video'
  String _selectedPackageName = 'Standard'; // 'Basic', 'Standard', 'Premium'
  late int _selectedPackagePriceRaw;
  late String _selectedPackagePrice;

  Color _getScaffoldBg() => Theme.of(context).scaffoldBackgroundColor;
  Color _getCardBg() => Theme.of(context).cardColor;
  Color _getTextColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF0F172A);
  Color _getBorderColor() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF334155)
      : Colors.grey.shade300;
  Color _getTextSubColor() => Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade600;

  // Step 3 State (Form)
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _agreeToTerms = true;

  // Step 4 State (Payment)
  String _selectedPaymentMethod = 'Bank Transfer'; // 'Bank Transfer', 'E-Wallet', 'Card'

  @override
  void initState() {
    super.initState();
    // Initialize default prices based on vendor price
    _updatePackageSelection('Standard');
    _locationController.text = widget.vendor['location'] ?? '';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Format integer to IDR Currency string
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

  void _updatePackageSelection(String packageName) {
    _selectedPackageName = packageName;
    final basePriceRaw = widget.vendor['priceRaw'] as int? ?? 2500000;
    
    if (packageName == 'Basic') {
      _selectedPackagePriceRaw = (basePriceRaw * 0.7).round();
    } else if (packageName == 'Premium') {
      _selectedPackagePriceRaw = (basePriceRaw * 1.4).round();
    } else {
      // Standard
      _selectedPackagePriceRaw = basePriceRaw;
    }
    _selectedPackagePrice = _formatIDR(_selectedPackagePriceRaw);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      final dayName = days[picked.weekday % 7];
      final monthName = months[picked.month - 1];
      setState(() {
        _dateController.text = '$dayName, ${picked.day} $monthName ${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} WIB';
        });
      }
    }
  }

  Future<void> _handlePayment() async {
    final email = FirebaseSqliteHelper.currentUserEmail;
    if (email == null) return;

    // Loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      ),
    );

    // Save booking date & package details
    final formattedBookingDate = '${_dateController.text} (${_timeController.text})';
    final customPackageType = '${widget.vendor['name']} - $_selectedPackageName Package';

    await FirebaseSqliteHelper.instance.createBooking(
      email,
      widget.vendor['id'] as int,
      customPackageType,
      _selectedPackagePrice,
      formattedBookingDate,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
      
      // Show gorgeous custom success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: _getCardBg(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 70,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pembayaran Berhasil!',
                style: TextStyle(color: _getTextColor(), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Terima kasih! Pesanan Anda di ${widget.vendor['name']} telah berhasil dibooking secara resmi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _getTextSubColor(), fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // Navigate to Home page and reset back to dashboard/schedule
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Lihat Jadwal Saya',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      body: SafeArea(
        child: Column(
          children: [
            // STEP PROGRESS HEADER
            _buildStepIndicator(),
            
            // BODY SCROLLABLE AREA
            Expanded(
              child: _buildCurrentStepView(),
            ),

            // BOTTOM ACTION BAR
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _getCardBg(),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentStep > 1) {
                setState(() {
                  _currentStep--;
                });
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.arrow_back, color: _getTextColor()),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(4, (index) {
                    final isDone = index + 1 < _currentStep;
                    final isCurrent = index + 1 == _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDone || isCurrent
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Detail Vendor';
      case 2:
        return 'Pilih Paket Jasa';
      case 3:
        return 'Booking Form';
      case 4:
        return 'Konfirmasi Pembayaran';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Detail();
      case 2:
        return _buildStep2Package();
      case 3:
        return _buildStep3BookingForm();
      case 4:
        return _buildStep4Payment();
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: VENDOR DETAIL ---
  Widget _buildStep1Detail() {
    final List<Map<String, dynamic>> reviewsList = [
      {
        'user': 'Rian Sumenep',
        'rating': '5.0',
        'date': '2 minggu lalu',
        'comment': 'Sangat profesional! Foto wisuda keluarga kami hasilnya tajam, pencahayaan alami dan pose diarahkan dengan sabar.'
      },
      {
        'user': 'Indah Pamekasan',
        'rating': '4.9',
        'date': '1 bulan lalu',
        'comment': 'Teaser pre-wedding kami cinematic banget, semua teman kagum pas diputar di resepsi. Top buat jasanya.'
      }
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Cover Image
        Stack(
          children: [
            NexaImage(
              imagePath: widget.vendor['image'] ?? 'assets/images/bg.png',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Profile Card Detail
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Category tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.vendor['name'] ?? 'Vendor Jasa',
                      style: TextStyle(color: _getTextColor(), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.vendor['type'] ?? 'Fotografer',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Rating / reviews & location
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.vendor['rating'] ?? "5.0"} (${widget.vendor['reviews'] ?? "12"} Ulasan)',
                    style: TextStyle(color: _getTextColor(), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.vendor['location'] ?? 'Madura',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: _getBorderColor()),
              const SizedBox(height: 16),

              // Tabs Selector (Visual dummy tabs)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Info', 'Portofolio', 'Paket', 'Ulasan'].map((tab) {
                    final isActive = tab == 'Info';
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981) : _getCardBg(),
                        borderRadius: BorderRadius.circular(20),
                        border: isActive ? null : Border.all(color: _getBorderColor()),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isActive ? Colors.black : _getTextSubColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Tentang Kami
              Text(
                'Tentang Kami',
                style: TextStyle(color: _getTextColor(), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.vendor['desc'] ??
                    'Kami menyediakan layanan dokumentasi visual profesional untuk menangkap setiap momen spesial Anda secara indah, jernih, dan bernilai seni tinggi.',
                style: TextStyle(color: _getTextSubColor(), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Quick Specs
              Row(
                children: [
                  Expanded(
                    child: _buildSpecCard(Icons.map_outlined, 'Wilayah Layanan', widget.vendor['location'] ?? 'Madura'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSpecCard(Icons.calendar_month_outlined, 'Bergabung Sejak', 'Tahun 2023'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Portofolio Terbaru
              Text(
                'Portofolio Terbaru',
                style: TextStyle(color: _getTextColor(), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildPortfolioItem('assets/images/bg1.png'),
                  _buildPortfolioItem('assets/images/bg2.png'),
                  _buildPortfolioItem('assets/images/nexavisual.png'),
                  _buildPortfolioItem('assets/images/kisahkita.png'),
                ],
              ),
              
              const SizedBox(height: 24),
              // Section: Ulasan
              Text(
                'Ulasan Pelanggan',
                style: TextStyle(color: _getTextColor(), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...reviewsList.map((rev) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rev['user'], style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(rev['date'], style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(rev['rating'], style: TextStyle(color: _getTextColor(), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rev['comment'], style: TextStyle(color: _getTextSubColor(), fontSize: 12, height: 1.4)),
                  ],
                ),
              )),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecCard(IconData icon, String title, String val) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: _getTextColor(), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(String image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(image, fit: BoxFit.cover),
    );
  }

  // --- STEP 2: SELECT PACKAGE ---
  Widget _buildStep2Package() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Tabs Category selector
        Row(
          children: ['Foto', 'Video', 'Foto + Video'].map((cat) {
            final active = cat == _selectedCategory;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF10B981) : _getCardBg(),
                    borderRadius: BorderRadius.circular(14),
                    border: active ? null : Border.all(color: _getBorderColor()),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: active ? Colors.black : _getTextSubColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Package Cards List
        _buildPackageCard('Basic', 'Paket hemat berkualitas tinggi'),
        const SizedBox(height: 16),
        _buildPackageCard('Standard', 'Paling populer untuk momen intim'),
        const SizedBox(height: 16),
        _buildPackageCard('Premium', 'Dokumentasi visual bintang lima terlengkap'),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPackageCard(String name, String tagline) {
    final isSelected = _selectedPackageName == name;
    
    // Compute price
    final basePriceRaw = widget.vendor['priceRaw'] as int? ?? 2500000;
    int priceRaw = basePriceRaw;
    if (name == 'Basic') priceRaw = (basePriceRaw * 0.7).round();
    if (name == 'Premium') priceRaw = (basePriceRaw * 1.4).round();
    final priceStr = _formatIDR(priceRaw);

    // Dynamic lists of features
    List<String> listFeats = [];
    if (name == 'Basic') {
      listFeats = ['3 Jam Service', '1 Photographer', 'Semua Soft Copy', 'Pilih 30 Foto Ter-edit'];
    } else if (name == 'Premium') {
      listFeats = ['10 Jam Service', '2 Photographer + 1 Assistant', 'Semua Soft Copy', 'Cetak Album Cetak Premium', 'Video Highlight 1 Menit'];
    } else {
      final defaultList = widget.vendor['features'] as List<dynamic>?;
      listFeats = defaultList != null ? List<String>.from(defaultList) : ['6 Jam Service', '2 Photographer', 'Semua Soft Copy', 'Pilih 50 Foto Ter-edit'];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _updatePackageSelection(name);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : _getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(color: _getTextColor(), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(tagline, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 16)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              priceStr,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Divider(color: _getBorderColor()),
            const SizedBox(height: 12),
            ...listFeats.map((feat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(feat, style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: BOOKING FORM ---
  Widget _buildStep3BookingForm() {
    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Banner Vendor Ringkas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: NexaImage(
                    imagePath: widget.vendor['image'] ?? 'assets/images/bg.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.vendor['name'] ?? 'Vendor Jasa', style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$_selectedPackageName Package • $_selectedCategory', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildFormLabel('Tanggal Acara'),
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dateController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Pilih tanggal acara' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormDecoration('Pilih tanggal pelaksanaan acara', Icons.calendar_month_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFormLabel('Waktu Acara'),
          GestureDetector(
            onTap: _selectTime,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _timeController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Pilih waktu acara' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormDecoration('Pilih jam pelaksanaan acara', Icons.access_time_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFormLabel('Lokasi Acara'),
          TextFormField(
            controller: _locationController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Masukkan lokasi acara' : null,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormDecoration('Masukkan lokasi lengkap / nama gedung', Icons.location_on_outlined),
          ),
          const SizedBox(height: 16),

          _buildFormLabel('Detail Acara'),
          TextFormField(
            controller: _detailsController,
            maxLines: 3,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormDecoration('Contoh: Pernikahan indoor di aula gedung, estimasi tamu 200 orang...', Icons.info_outline),
          ),
          const SizedBox(height: 16),

          _buildFormLabel('Catatan Tambahan (Opsional)'),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormDecoration('Tulis catatan khusus bagi tim vendor...', Icons.edit_note_outlined),
          ),
          const SizedBox(height: 20),

          // Checkbox Persetujuan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeToTerms,
                activeColor: const Color(0xFF10B981),
                checkColor: Colors.black,
                onChanged: (val) {
                  setState(() {
                    _agreeToTerms = val ?? true;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan serta Kebijakan Privasi platform Nexabook.',
                  style: TextStyle(color: _getTextSubColor(), fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  InputDecoration _buildFormDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _getTextSubColor().withOpacity(0.7), fontSize: 13),
      filled: true,
      fillColor: _getCardBg(),
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _getBorderColor()),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // --- STEP 4: PAYMENT CONFIRMATION ---
  Widget _buildStep4Payment() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Rincian Pesanan Card
        Text(
          'Rincian Pesanan',
          style: TextStyle(color: _getTextColor(), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getBorderColor()),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Vendor', widget.vendor['name'] ?? 'Jasa'),
              Divider(color: _getBorderColor(), height: 20),
              _buildSummaryRow('Paket Layanan', '$_selectedPackageName Package'),
              Divider(color: _getBorderColor(), height: 20),
              _buildSummaryRow('Tanggal Acara', _dateController.text),
              Divider(color: _getBorderColor(), height: 20),
              _buildSummaryRow('Waktu Sesi', _timeController.text),
              Divider(color: _getBorderColor(), height: 20),
              _buildSummaryRow('Lokasi Acara', _locationController.text),
              Divider(color: _getBorderColor(), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran', style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
                  Text(
                    _selectedPackagePrice,
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Metode Pembayaran
        Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(color: _getTextColor(), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard('Bank Transfer', 'Transfer BCA / Mandiri / BNI', Icons.account_balance),
        const SizedBox(height: 10),
        _buildPaymentMethodCard('E-Wallet', 'Gopay / OVO / Dana / ShopeePay', Icons.wallet_outlined),
        const SizedBox(height: 10),
        _buildPaymentMethodCard('Card', 'Kartu Kredit / Debit Online', Icons.credit_card_outlined),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String type, String desc, IconData icon) {
    final isSel = _selectedPaymentMethod == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFF10B981) : _getBorderColor(),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? const Color(0xFF10B981) : Colors.grey,
                  width: 2,
                ),
                color: isSel ? const Color(0xFF10B981) : Colors.transparent,
              ),
              child: isSel ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS BAR BOTTOM ---
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _getCardBg(),
        border: Border(top: BorderSide(color: _getBorderColor(), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step 1 & 2 Left detail
          if (_currentStep == 1 || _currentStep == 2)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mulai Dari', style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _currentStep == 1 ? (widget.vendor['price'] ?? 'Rp0') : _selectedPackagePrice,
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          
          if (_currentStep == 3)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Pembayaran', style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _selectedPackagePrice,
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

          if (_currentStep == 4)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: TextStyle(color: _getTextSubColor(), fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _selectedPackagePrice,
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

          // Main Button Right
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            onPressed: () {
              if (_currentStep == 1) {
                setState(() {
                  _currentStep = 2;
                });
              } else if (_currentStep == 2) {
                setState(() {
                  _currentStep = 3;
                });
              } else if (_currentStep == 3) {
                if (_formKey.currentState!.validate()) {
                  if (!_agreeToTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anda harus menyetujui syarat & ketentuan terlebih dahulu!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _currentStep = 4;
                  });
                }
              } else if (_currentStep == 4) {
                _handlePayment();
              }
            },
            child: Text(
              _getActionText(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionText() {
    switch (_currentStep) {
      case 1:
        return 'Book Now';
      case 2:
        return 'Lanjutkan';
      case 3:
        return 'Lanjutkan Pembayaran';
      case 4:
        return 'Bayar Sekarang';
      default:
        return '';
    }
  }
}
