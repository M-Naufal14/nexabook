import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/database_helper.dart';
import '../helper/image_helper.dart';
import '../main.dart';

class VendorPortalPage extends StatefulWidget {
  const VendorPortalPage({super.key});

  @override
  State<VendorPortalPage> createState() => _VendorPortalPageState();
}

class _VendorPortalPageState extends State<VendorPortalPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  Map<String, dynamic>? _vendorProfile;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  // Stats
  int _totalBookings = 0;
  int _pendingBookings = 0;
  int _completedBookings = 0;
  int _totalEarnings = 0;

  // Profile Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Fotografer';
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();

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
    _loadVendorData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      _isLoading = true;
    });

    final email = DatabaseHelper.currentUserEmail;
    if (email != null) {
      final profile = await DatabaseHelper.instance.getVendorByOwnerEmail(email);
      if (profile != null) {
        final bks = await DatabaseHelper.instance.getBookingsForVendor(profile['id'] as int);
        
        // Calculate stats
        int total = bks.length;
        int pending = bks.where((b) => b['status'] == 'Aktif').length;
        int completed = bks.where((b) => b['status'] == 'Selesai').length;
        
        int earnings = 0;
        for (final bk in bks) {
          if (bk['status'] == 'Selesai') {
            final priceStr = bk['price'] as String? ?? 'Rp0';
            final cleanPrice = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
            earnings += int.tryParse(cleanPrice) ?? 0;
          }
        }

        if (mounted) {
          setState(() {
            _vendorProfile = profile;
            _bookings = bks;
            _totalBookings = total;
            _pendingBookings = pending;
            _completedBookings = completed;
            _totalEarnings = earnings;
            
            // Fill controllers for editing
            _nameController.text = profile['name'] ?? '';
            _selectedType = profile['type'] ?? 'Fotografer';
            _priceController.text = profile['price'] ?? '';
            _locationController.text = profile['location'] ?? '';
            _descController.text = profile['desc'] ?? '';
            
            final feats = profile['features'] as List<dynamic>?;
            _featuresController.text = feats?.join(', ') ?? '';

            _tabController ??= TabController(length: 4, vsync: this);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _vendorProfile = null;
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectCoverPhoto() {
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                    const Text(
                      'Pilih Foto Sampul Jasa Anda',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
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
                              maxWidth: 1200,
                              maxHeight: 1200,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setState(() {
                                _vendorProfile!['image'] = image.path;
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
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
                              maxWidth: 1200,
                              maxHeight: 1200,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setState(() {
                                _vendorProfile!['image'] = image.path;
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
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
                      onPressed: () {
                        final customUrl = customUrlController.text.trim();
                        if (customUrl.isNotEmpty) {
                          setState(() {
                            _vendorProfile!['image'] = customUrl;
                          });
                          Navigator.pop(context);
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
                      onTap: () {
                        setState(() {
                          _vendorProfile!['image'] = img;
                        });
                        Navigator.pop(context);
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

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = DatabaseHelper.currentUserEmail;
    if (email == null) return;

    // clean price value for database raw pricing
    final cleanPriceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final priceRaw = int.tryParse(cleanPriceText) ?? 1500000;
    
    // ensure starting text starts with Rp
    var formattedPrice = _priceController.text.trim();
    if (!formattedPrice.startsWith('Rp') && !formattedPrice.startsWith('rp')) {
      formattedPrice = 'Rp${_formatNumberString(cleanPriceText)}';
    }

    // Split features
    final listFeats = _featuresController.text
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    final success = await DatabaseHelper.instance.createOrUpdateVendor({
      'owner_email': email,
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'price': formattedPrice,
      'priceRaw': priceRaw,
      'location': _locationController.text.trim(),
      'desc': _descController.text.trim(),
      'features': listFeats,
      'image': _vendorProfile != null ? _vendorProfile!['image'] : 'assets/images/bg.png',
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil Vendor berhasil disimpan!'),
          backgroundColor: Color(0xFF118954),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadVendorData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil vendor.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatNumberString(String s) {
    if (s.isEmpty) return '0';
    final amount = int.tryParse(s) ?? 0;
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
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _handleUpdateBooking(int bookingId, String code, String action) async {
    final status = action == 'complete' ? 'Selesai' : 'Dibatalkan';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Aksi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menandai transaksi "$code" sebagai "$status"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'complete' ? const Color(0xFF118954) : Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'complete' ? 'Selesaikan' : 'Batalkan', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await DatabaseHelper.instance.updateBookingStatus(bookingId, status);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi $code berhasil ditandai sebagai $status.'),
            backgroundColor: const Color(0xFF118954),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadVendorData();
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        content: const Text('Apakah Anda yakin ingin keluar dari Vendor Portal?'),
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

    // VENDOR PROFILE NOT FOUND FORM CREATOR
    if (_vendorProfile == null) {
      return Scaffold(
        backgroundColor: _getScaffoldBg(),
        appBar: AppBar(
          backgroundColor: _getScaffoldBg(),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Buat Profil Vendor', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          actions: [
            const ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _showLogoutDialog,
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lengkapi Detail Jasa Visual Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor()),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Daftarkan studio atau layanan pribadi Anda agar calon pelanggan dapat langsung memesan jasa Anda.',
                    style: TextStyle(color: _getTextSubColor(), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _getBorderColor()),
                  const SizedBox(height: 16),
                  
                  _buildFormLabel('Nama Jasa / Studio'),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                    style: TextStyle(color: _getTextColor()),
                    decoration: _buildFormInputDecoration('Masukkan nama studio foto/video Anda'),
                  ),
                  const SizedBox(height: 16),

                  _buildFormLabel('Kategori Jasa'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _getCardBg(),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _getBorderColor()),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedType,
                        dropdownColor: _getCardBg(),
                        style: TextStyle(color: _getTextColor(), fontSize: 14, fontWeight: FontWeight.w500),
                        items: ['Fotografer', 'Videografer']
                            .map((type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFormLabel('Harga Awal Jasa (Contoh: 1500000)'),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Harga tidak boleh kosong' : null,
                    style: TextStyle(color: _getTextColor()),
                    decoration: _buildFormInputDecoration('Masukkan besaran harga awal Rp'),
                  ),
                  const SizedBox(height: 16),

                  _buildFormLabel('Lokasi Pelayanan (Contoh: Pamekasan)'),
                  TextFormField(
                    controller: _locationController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi tidak boleh kosong' : null,
                    style: TextStyle(color: _getTextColor()),
                    decoration: _buildFormInputDecoration('Masukkan wilayah layanan Anda'),
                  ),
                  const SizedBox(height: 16),

                  _buildFormLabel('Deskripsi Layanan & Keunggulan'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                    style: TextStyle(color: _getTextColor()),
                    decoration: _buildFormInputDecoration('Tuliskan rincian studio dan peralatan Anda...'),
                  ),
                  const SizedBox(height: 16),

                  _buildFormLabel('Fitur Paket (Pisahkan dengan koma ",")'),
                  TextFormField(
                    controller: _featuresController,
                    style: TextStyle(color: _getTextColor()),
                    decoration: _buildFormInputDecoration('Contoh: 2 Fotografer, Unlimited Shoots, Frame 16R'),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      onPressed: _handleSaveProfile,
                      child: const Text(
                        'Simpan & Buat Jasa',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // MAIN VENDOR DASHBOARD PAGE WITH SECTIONS
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
              child: const Icon(Icons.storefront, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vendorProfile!['name'] ?? 'Vendor Jasa',
                  style: TextStyle(color: _getTextColor(), fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Portal Bisnis Visual',
                  style: TextStyle(color: _getTextSubColor(), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _loadVendorData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _showLogoutDialog,
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
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Dashboard'),
            Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Pesanan'),
            Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Edit Profil'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'Obrolan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildBookingsTab(),
          _buildEditProfileTab(),
          _buildChatsTab(),
        ],
      ),
    );
  }

  // A. VENDOR PORTAL - DASHBOARD TAB
  Widget _buildDashboardTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Premium Profile Banner Overview
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: NexaImage(
                  imagePath: _vendorProfile!['image'] ?? 'assets/images/bg.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.white24,
                    child: const Icon(Icons.image, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vendorProfile!['name'] ?? 'Studio',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_vendorProfile!['type']} • ${_vendorProfile!['location']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_vendorProfile!['rating']} (${_vendorProfile!['reviews']} Ulasan)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // STATS BOXES
        Text(
          'Kinerja Bisnis Jasa Anda',
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
            _buildStatBox('Pendapatan Bersih', _formatIDR(_totalEarnings), Icons.monetization_on_outlined, Colors.green),
            _buildStatBox('Semua Booking', _totalBookings.toString(), Icons.history_edu, Colors.blue),
            _buildStatBox('Pesanan Aktif', _pendingBookings.toString(), Icons.pending_actions, Colors.orange),
            _buildStatBox('Layanan Selesai', _completedBookings.toString(), Icons.task_alt, Colors.purple),
          ],
        ),
        const SizedBox(height: 24),

        // PRICE VIEW CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _getBorderColor()),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Awal Jasa Saat Ini', style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      _vendorProfile!['price'] ?? 'Rp0',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _tabController!.animateTo(2),
                child: const Text('Ubah Harga', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: _getTextSubColor(), fontSize: 12)),
        ],
      ),
    );
  }

  // B. VENDOR PORTAL - BOOKINGS TAB
  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('Belum ada pesanan masuk untuk Anda.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _bookings.length,
      itemBuilder: (context, i) {
        final bk = _bookings[i];
        Color statusColor = Colors.grey;
        if (bk['status'] == 'Aktif') {
          statusColor = const Color(0xFF118954);
        } else if (bk['status'] == 'Selesai') {
          statusColor = Colors.blue;
        } else if (bk['status'] == 'Dibatalkan') {
          statusColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _getBorderColor()),
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
                      bk['booking_code'] ?? 'BK-XXXXX',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _getTextSubColor(), fontSize: 12),
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
                  bk['type'] ?? 'Session Booking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor()),
                ),
                const SizedBox(height: 6),
                Text('Pelanggan: ${bk['user_email']}', style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
                Text('Jadwal Pelaksanaan: ${bk['date']}', style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
                Text('Nilai Pesanan: ${bk['price']}', style: TextStyle(color: _getTextSubColor(), fontSize: 13)),
                const SizedBox(height: 16),
                if (bk['status'] == 'Aktif') ...[
                  Divider(color: _getBorderColor()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _handleUpdateBooking(bk['id'], bk['booking_code'], 'cancel'),
                          child: const Text('Batalkan', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _handleUpdateBooking(bk['id'], bk['booking_code'], 'complete'),
                          child: const Text('Selesaikan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // C. VENDOR PORTAL - EDIT PROFILE TAB
  Widget _buildEditProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _getBorderColor()),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbarui Profil Bisnis Jasa Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor()),
              ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: NexaImage(
                        imagePath: _vendorProfile!['image'] ?? 'assets/images/bg.png',
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: double.infinity,
                          height: 150,
                          color: _getScaffoldBg(),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                        onPressed: _selectCoverPhoto,
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Ganti Cover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildFormLabel('Nama Jasa / Studio'),
              TextFormField(
                controller: _nameController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormInputDecoration('Masukkan nama studio foto/video Anda'),
              ),
              const SizedBox(height: 16),
 
              _buildFormLabel('Kategori Jasa'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _getCardBg(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedType,
                    dropdownColor: _getCardBg(),
                    items: ['Fotografer', 'Videografer']
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
 
              _buildFormLabel('Harga Awal Jasa (Contoh: Rp2.500.000)'),
              TextFormField(
                controller: _priceController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Harga tidak boleh kosong' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormInputDecoration('Masukkan besaran harga jasa'),
              ),
              const SizedBox(height: 16),
 
              _buildFormLabel('Lokasi Pelayanan'),
              TextFormField(
                controller: _locationController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi tidak boleh kosong' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormInputDecoration('Masukkan wilayah layanan Anda'),
              ),
              const SizedBox(height: 16),
 
              _buildFormLabel('Deskripsi Layanan & Keunggulan'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormInputDecoration('Tuliskan rincian studio dan peralatan Anda...'),
              ),
              const SizedBox(height: 16),
 
              _buildFormLabel('Fitur Paket (Pisahkan dengan koma ",")'),
              TextFormField(
                controller: _featuresController,
                style: TextStyle(color: _getTextColor()),
                decoration: _buildFormInputDecoration('Contoh: 2 Fotografer, Unlimited Shoots, Frame 16R'),
              ),
              const SizedBox(height: 28),
 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  onPressed: _handleSaveProfile,
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // D. VENDOR PORTAL - SIMULATION CHATS TAB
  Widget _buildChatsTab() {
    final List<Map<String, dynamic>> dummyChats = [
      {
        'initial': 'N',
        'name': 'Naufal Pelanggan',
        'msg': 'Halo kak, untuk wedding session tanggal 24 Mei besok ready kan ya?',
        'time': '12:45',
        'unread': 1,
      },
      {
        'initial': 'A',
        'name': 'Amelia Sumenep',
        'msg': 'Baik kak, nanti DP-nya saya transfer ke rekening studio ya.',
        'time': 'Kemarin',
        'unread': 0,
      },
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: dummyChats.length,
      itemBuilder: (context, i) {
        final chat = dummyChats[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _getCardBg(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getBorderColor()),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
              child: Text(
                chat['initial'],
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chat['name'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor(), fontSize: 15),
                ),
                Text(
                  chat['time'],
                  style: TextStyle(color: _getTextSubColor(), fontSize: 11),
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
                      chat['msg'],
                      style: TextStyle(color: _getTextSubColor(), fontSize: 13, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (chat['unread'] > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      child: Text(
                        "${chat['unread']}",
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  // HELPER STYLES FOR FORMS
  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor(), fontSize: 13),
      ),
    );
  }

  InputDecoration _buildFormInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _getTextSubColor().withOpacity(0.7), fontSize: 14),
      filled: true,
      fillColor: _getCardBg(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _getBorderColor()),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }
}
