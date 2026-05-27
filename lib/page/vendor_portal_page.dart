import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/database_helper.dart';
import '../helper/image_helper.dart';
import '../main.dart';
import 'vendor_order_detail_page.dart';
import 'vendor_chat_room_page.dart';


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
  bool _isAvailable = true;

  int _activeTabIndex = 0;
  String _selectedCategory = 'Fotografer';
  final List<String> _categories = [
    'Fotografer',
    'Videografer',
    'Architectural Design',
    '3D Visualization',
    'Interior Design'
  ];

  final List<Map<String, dynamic>> _pricingPackages = [
    {
      'id': '1',
      'title': 'Basic Rendering',
      'description': 'Single high-res 4K still image with daylight settings.',
      'price': 450,
    },
    {
      'id': '2',
      'title': 'Full Project Walkthrough',
      'description': '60-second 4K animation + 5 interior stills.',
      'price': 1200,
    }
  ];

  final List<Map<String, String>> _portfolioItems = [
    {
      'id': 'p1',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA5OzpzVkCzRjMMZjXn-bi_oYhpna7FaCXH0fPRNCgOQrwxUzC-MiS6eaMKG39sufw2aryxpdUMpFl4dqaleIsUSzjPkKWjuLJJu_cYdIzh7ATpDZ-dD0FEYfq7YvoeWKloil3pVwnXtZ1jV58V5tQEhK2RTef5K-TxthiOtGlw3arlfYqGVkU5b8BZk3nic8jk-syci5h1bdnIV8Wj1Tgwx7_CUym4yWNcZMtQ9cbBVMKivfyQ3y_n3IiIeOmio7DGiOkMu0lbGJ3d',
      'title': 'Modern Villa at Dusk',
    },
    {
      'id': 'p2',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAUwUvqVmMNcmJ6U8_StvNQC4jciBI3ClVpQika9bZihmSMin3wUMWLJpRpe2VUhoK7DWln95xKoPMc7H7pqtY6tdSbJuUZJxZazndmfdO36d-W6Wep44rKOmLIrcWscIcadrXrvXS531tMBUQ5DsaP96oqCDC4W_bfRzx1kz2Cye4H0TELvmc34TP3XSQ6hYbdyCREBzppMmTWHxbQpZL4tsrzG9Hp1iObpzYs9h57F-KXAoPWBjL7-rnjzbfRmqvI1Wgm6DA1cYNi',
      'title': 'Marble Kitchen Interior',
    },
    {
      'id': 'p3',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBirAyhHdfc0ZwIza0ww1hycy9s-9IWF1DVGkuhBJgRkKcZIuG3rRqKiaam0XO9RROrIUAoJp2IVMx1bFEHTzvKIEPmiRe_VtRsnT8DVaf95M0Hy-9MV3N24QoGGCkCCALn1NsBVr19TVX1XYN7BRpmUVN77npKnwbtDEldZwlwbKUFCS99fAZVkD77UbHjn13WtJ0v7Z7SyhGQvIg65ZzdHnBDnY8DrmMJOT5fzr58qSW6XcVhPYohCYEnIPkbNgb94CtyWIlZxavY',
      'title': 'Futuristic Office Lobby',
    }
  ];

  // Stats
  int _totalBookings = 0;
  int _pendingBookings = 0;
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
            _totalEarnings = earnings;
            
            // Fill controllers for editing
            _nameController.text = profile['name'] ?? '';
            _selectedType = profile['type'] ?? 'Fotografer';
            _selectedCategory = _selectedType;
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
    return PopScope(
      canPop: _tabController == null || _tabController!.index == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_tabController != null && _tabController!.index != 0) {
          _tabController!.animateTo(0);
        }
      },
      child: Scaffold(
        backgroundColor: _getScaffoldBg(),
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: _getScaffoldBg(),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF10B981)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const Text(
            "NexaBook",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Color(0xFF10B981),
            ),
          ),
          centerTitle: false,
          actions: [
            const ThemeToggleButton(),
            // Bell alarm notification with badge dot
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: _getTextColor()),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Belum ada notifikasi baru."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 14,
                  right: 14,
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
            const SizedBox(width: 8),
            // Circular Profile Photo
            GestureDetector(
              onTap: () {
                _tabController!.animateTo(2); // Jump to Edit Profil Tab
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                backgroundImage: _vendorProfile != null && _vendorProfile!['image'] != null
                    ? getCustomImageProvider(_vendorProfile!['image']!)
                    : null,
                child: _vendorProfile == null || _vendorProfile!['image'] == null
                    ? const Icon(Icons.person, size: 16, color: Color(0xFF10B981))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
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
      ),
    );
  }

  // A. VENDOR PORTAL - DASHBOARD TAB (Match Mockup Premium)
  Widget _buildDashboardTab() {
    // Setup Active Bookings from DB + Mock Fallbacks to showcase screenshot perfectly
    final List<Map<String, dynamic>> activeList = _bookings
        .where((b) => b['status'] == 'Aktif' || b['status'] == 'Menunggu')
        .toList();

    if (activeList.isEmpty) {
      activeList.addAll([
        {
          'id': 9991,
          'booking_code': 'BK-AMANDA',
          'name': 'Amanda Wijaya',
          'location': 'Grand Ballroom, Jakarta',
          'date': '24 Oct, 2023',
          'type': 'Wedding Session',
          'price': 'Rp4.500.000',
          'user_email': 'amanda.wijaya@gmail.com',
          'is_mock': true,
        },
        {
          'id': 9992,
          'booking_code': 'BK-RUDI',
          'name': 'Rudi Santoso',
          'location': 'Outdoor Studio, Bandung',
          'date': '28 Oct, 2023',
          'type': 'Photo Session',
          'price': 'Rp1.800.000',
          'user_email': 'rudi.santoso@gmail.com',
          'is_mock': true,
        },
        {
          'id': 9993,
          'booking_code': 'BK-SITI',
          'name': 'Siti Aisyah',
          'location': 'Convention Center, Surabaya',
          'date': '02 Nov, 2023',
          'type': 'Video & Launch',
          'price': 'Rp2.500.000',
          'user_email': 'siti.aisyah@gmail.com',
          'is_mock': true,
        },
      ]);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      children: [
        // DASHBOARD INTRO
        Text(
          "Vendor Dashboard",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _getTextColor(),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Manage your services, track bookings, and grow your revenue.",
          style: TextStyle(
            fontSize: 13,
            color: _getTextSubColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // STACKED METRICS CARDS (Match Mockup UI)
        _buildMetricCard(
          Icons.account_balance_wallet_outlined,
          "Total Revenue",
          _totalEarnings == 0 ? "Rp 42.050.000" : _formatIDR(_totalEarnings),
          "+2.4% vs last month",
        ),
        _buildMetricCard(
          Icons.calendar_month_outlined,
          "Total Bookings",
          _totalBookings == 0 ? "156" : _totalBookings.toString(),
          "+12% vs last month",
        ),
        _buildMetricCard(
          Icons.rocket_launch_outlined,
          "Active Projects",
          _pendingBookings == 0 ? "12" : _pendingBookings.toString(),
          "+5% this week",
        ),
        const SizedBox(height: 16),

        // ACTIVE BOOKINGS SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Bookings",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _getTextColor(),
              ),
            ),
            GestureDetector(
              onTap: () {
                _tabController!.animateTo(1); // switch to Pesanan (Bookings) tab
              },
              child: const Text(
                "View all",
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Active Booking Cards
        ...activeList.map((bk) => _buildActiveBookingCard(bk)),
        const SizedBox(height: 24),

        // ANALYTICS SECTION
        Text(
          "Analytics",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _getTextColor(),
          ),
        ),
        const SizedBox(height: 14),
        _buildAnalyticsChart(),
        const SizedBox(height: 24),

        // QUICK ACTIONS SECTION
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _getTextColor(),
          ),
        ),
        const SizedBox(height: 14),
        _buildQuickActions(),
      ],
    );
  }

  // WIDGET BUILDER: METRIC CARD
  Widget _buildMetricCard(IconData icon, String title, String value, String rate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: _getTextSubColor(), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _getTextColor()),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rate,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: ACTIVE BOOKING CARD (With Complete Action)
  Widget _buildActiveBookingCard(Map<String, dynamic> bk) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMock = bk['is_mock'] == true;
    final bookingCode = bk['booking_code']?.toString() ?? 'BK-XXXX';

    return GestureDetector(
      onTap: () async {
        final reload = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorOrderDetailPage(booking: bk),
          ),
        );
        if (reload == true) {
          _loadVendorData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.01),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Avatar Icon/Photo
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
              child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 14),
            
            // Customer Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bk['name']?.toString() ?? 'Pelanggan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _getTextColor()),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 12),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          bk['location']?.toString() ?? 'Jakarta',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${bk['date']} • ${bk['type']}",
                    style: TextStyle(fontSize: 10, color: _getTextSubColor(), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
  
            // Complete Button (emerald green background, black bold text, rounded corners)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () {
                  if (isMock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pesanan simulasi "$bookingCode" berhasil diselesaikan!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  } else {
                    _handleUpdateBooking(bk['id'] as int, bookingCode, 'complete');
                  }
                },
                child: const Text(
                  'Complete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDER: WEEKLY ANALYTICS CHART
  Widget _buildAnalyticsChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> chartData = [
      {'day': 'Mon', 'height': 45.0, 'active': false},
      {'day': 'Tue', 'height': 60.0, 'active': false},
      {'day': 'Wed', 'height': 50.0, 'active': false},
      {'day': 'Thu', 'height': 95.0, 'active': true}, // Thursday highlighted & tallest
      {'day': 'Fri', 'height': 75.0, 'active': false},
      {'day': 'Sat', 'height': 55.0, 'active': false},
      {'day': 'Sun', 'height': 65.0, 'active': false},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly View',
                style: TextStyle(fontSize: 12, color: _getTextSubColor(), fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((item) {
              final active = item['active'] as bool;
              final height = item['height'] as double;
              final day = item['day'] as String;

              return Column(
                children: [
                  Container(
                    height: 120, // boundary height
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: height,
                      width: 14,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? const Color(0xFF10B981) : _getTextSubColor(),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: QUICK ACTIONS GRID
  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: [
        _buildActionCard(
          Icons.add_circle_outline,
          'New Service',
          () => _tabController!.animateTo(2), // jump to Edit Profil Tab where they publish packages
        ),
        _buildActionCard(
          Icons.chat_bubble_outline,
          'Inbox',
          () => _tabController!.animateTo(3), // Chats
        ),
        _buildActionCard(
          Icons.settings_outlined,
          'Settings',
          () => _tabController!.animateTo(2), // Settings
        ),
        _buildActionCard(
          Icons.account_balance_wallet_outlined,
          'Withdraw',
          () {
            // High-fidelity withdrawal alert snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Penarikan dana bisnis visual sedang diproses ke rekening Anda.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.01),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF10B981), size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _getTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // B. VENDOR PORTAL - BOOKINGS TAB (Kelola Jadwal)
  Widget _buildBookingsTab() {
    // Get real active/pending bookings from database
    final List<Map<String, dynamic>> realActiveList = _bookings
        .where((b) => b['status'] == 'Aktif' || b['status'] == 'Menunggu')
        .toList();

    // Setup Mock high-fidelity list to match mockup screenshot exactly
    final List<Map<String, dynamic>> mockAgendaList = [
      {
        'id': 8881,
        'booking_code': 'BK-ANDI',
        'name': 'Andi Pratama',
        'location': 'Sudirman Central Business District, Jakarta',
        'time': '10:00 - 12:00',
        'status': 'Dikonfirmasi',
        'type': 'Wedding Session',
        'price': 'Rp4.500.000',
        'user_email': 'andi.pratama@gmail.com',
        'is_mock': true,
      },
      {
        'id': 8882,
        'booking_code': 'BK-SITI-AM',
        'name': 'Siti Aminah',
        'location': 'Menteng, Jakarta Pusat',
        'time': '13:00 - 15:00',
        'status': 'Menunggu',
        'type': 'Engagement Session',
        'price': 'Rp2.800.000',
        'user_email': 'siti.aminah@gmail.com',
        'is_mock': true,
      },
      {
        'id': 8883,
        'booking_code': 'BK-BUDI',
        'name': 'Budi Santosa',
        'location': 'BSD City, Tangerang',
        'time': '15:00 - 17:00',
        'status': 'Dikonfirmasi',
        'type': 'Prewedding Portrait',
        'price': 'Rp3.500.000',
        'user_email': 'budi.santosa@gmail.com',
        'is_mock': true,
      },
    ];

    // Combine mock lists + database active lists for high-fidelity interactive flow
    final List<Map<String, dynamic>> combinedAgenda = [];
    combinedAgenda.addAll(mockAgendaList);
    for (final dbBk in realActiveList) {
      combinedAgenda.add({
        'id': dbBk['id'],
        'booking_code': dbBk['booking_code']?.toString() ?? 'BK-XXXX',
        'name': dbBk['user_email']?.split('@')[0]?.toUpperCase() ?? 'Klien Nexa',
        'location': dbBk['location']?.toString() ?? 'Lokasi Acara',
        'time': '16:00 - 18:00', // Default mock schedule time
        'status': dbBk['status'] == 'Aktif' ? 'Dikonfirmasi' : 'Menunggu',
        'type': dbBk['type']?.toString() ?? 'Booking Layanan',
        'price': dbBk['price']?.toString() ?? 'Rp3.500.000',
        'user_email': dbBk['user_email']?.toString() ?? 'klien@gmail.com',
        'is_mock': false,
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAgendaDialog,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20).copyWith(bottom: 120),
        children: [
          // SUB HEADER INTRO
          Text(
            "Kelola Jadwal",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _getTextColor(),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Pantau pesanan masuk dan atur ketersediaan layanan Anda.",
            style: TextStyle(
              fontSize: 13,
              color: _getTextSubColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // AVAILABILITY TOGGLE CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _getCardBg(),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status Ketersediaan",
                      style: TextStyle(fontSize: 10, color: _getTextSubColor(), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAvailable ? "Menerima Pesanan" : "Tutup Sementara",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAvailable ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (val) {
                    setState(() {
                      _isAvailable = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? "Status ketersediaan diubah ke Menerima Pesanan."
                              : "Status ketersediaan diubah ke Tutup Sementara.",
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: val ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    );
                  },
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CALENDAR WIDGET CARD
          _buildCalendarCard(),
          const SizedBox(height: 24),

          // UPCOMING AGENDA HEADER
          Text(
            "Agenda Terdekat",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 14),

          // Agenda Cards List
          ...combinedAgenda.map((item) => _buildAgendaCard(
                clientName: item['name'],
                type: item['type'],
                location: item['location'],
                time: item['time'],
                status: item['status'],
                isMock: item['is_mock'] == true,
                bookingId: item['id'] as int?,
                bookingCode: item['booking_code'],
                price: item['price'],
                userEmail: item['user_email'],
              )),
          const SizedBox(height: 24),

          // MAP LOCATIONS SECTION
          _buildMapCard(),
        ],
      ),
    );
  }

  // WIDGET BUILDER: CUSTOM INTERACTIVE CALENDAR
  Widget _buildCalendarCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu'];

    // October 2023 dates grid (starts on Sunday, Oct 1)
    final List<String> gridCells = [
      '', '', '', '1', '2', '3', '4',
      '5', '6', '7', '8', '9', '10', '11',
      '12', '13', '14', '15', '16', '17', '18',
      '19', '20', '21', '22', '23', '24', '25',
      '26', '27', '28', '29', '30', '31', '',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dropdown & arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Oktober 2023",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: _getTextColor(), size: 20),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: _getTextSubColor()),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _getTextSubColor()),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Days labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTextSubColor(),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Grid Builder
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: gridCells.length,
            itemBuilder: (context, index) {
              final dateStr = gridCells[index];
              if (dateStr.isEmpty) {
                return const SizedBox.shrink();
              }

              final isConfirmed = dateStr == '5';
              final isPending = dateStr == '10';

              Color? textColor = _getTextColor();
              BoxDecoration? decoration;

              if (isConfirmed) {
                textColor = const Color(0xFF10B981);
                decoration = BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  color: const Color(0xFF10B981).withOpacity(0.12),
                );
              } else if (isPending) {
                textColor = Colors.redAccent;
                decoration = BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  color: Colors.redAccent.withOpacity(0.12),
                );
              }

              return Container(
                decoration: decoration,
                child: Center(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: (isConfirmed || isPending) ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF10B981), "Dikonfirmasi"),
               const SizedBox(width: 16),
              _buildLegendItem(Colors.redAccent, "Menunggu"),
               const SizedBox(width: 16),
              _buildLegendItem(Colors.amber, "Libur"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getTextSubColor(),
          ),
        ),
      ],
    );
  }

  // WIDGET BUILDER: AGENDA CARD
  Widget _buildAgendaCard({
    required String clientName,
    required String type,
    required String location,
    required String time,
    required String status,
    required bool isMock,
    int? bookingId,
    String? bookingCode,
    String? price,
    String? userEmail,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isConfirmed = status == 'Dikonfirmasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isConfirmed ? const Color(0xFF10B981) : Colors.redAccent,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isConfirmed ? "DITERIMA" : "PENDING",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isConfirmed ? const Color(0xFF10B981) : Colors.redAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getTextSubColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Client Name
              Text(
                clientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getTextColor(),
                ),
              ),
               const SizedBox(height: 6),

              // Location Row
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: _getTextSubColor(), size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTextSubColor(),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Buttons
              if (isConfirmed) ...[
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final bookingMap = {
                        'id': bookingId,
                        'booking_code': bookingCode ?? 'BK-MOCK',
                        'user_email': userEmail ?? (clientName.toLowerCase().replaceAll(' ', '') + '@gmail.com'),
                        'name': clientName,
                        'location': location,
                        'time': time,
                        'status': status == 'Dikonfirmasi' ? 'Aktif' : status,
                        'type': type,
                        'price': price ?? 'Rp3.500.000',
                        'is_mock': isMock,
                      };
                      final reload = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VendorOrderDetailPage(booking: bookingMap),
                        ),
                      );
                      if (reload == true) {
                        _loadVendorData();
                      }
                    },
                    child: Text(
                      'LIHAT DETAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _getTextColor(),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (isMock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Berhasil menerima pesanan simulasi!"),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } else if (bookingId != null && bookingCode != null) {
                              _handleUpdateBooking(bookingId, bookingCode, 'complete');
                            }
                          },
                          child: const Text(
                            'TERIMA',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (isMock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Berhasil menolak pesanan simulasi."),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } else if (bookingId != null && bookingCode != null) {
                              _handleUpdateBooking(bookingId, bookingCode, 'cancel');
                            }
                          },
                          child: const Text(
                            'TOLAK',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.redAccent, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BUILDER: LOKASI MAPS ACARA
  Widget _buildMapCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lokasi Pesanan Hari ini",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 16),

          // Modern Dark Minimap Background representation
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.12 : 0.35,
                    child: GridPaper(
                      color: isDark ? Colors.white : Colors.grey,
                      divisions: 1,
                      subdivisions: 1,
                      interval: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 30, left: 20, right: 20, bottom: 40,
                  child: CustomPaint(
                    painter: _MapPathPainter(isDark: isDark),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 60,
                  child: _buildMapPin("Andi (Sudirman)", const Color(0xFF10B981)),
                ),
                Positioned(
                  top: 90,
                  right: 80,
                  child: _buildMapPin("Siti (Menteng)", Colors.redAccent),
                ),
                Positioned(
                  bottom: 30,
                  left: 140,
                  child: _buildMapPin("Budi (BSD)", const Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Map Tags Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMapTagItem(const Color(0xFF10B981), "Andi (Sudirman)"),
              _buildMapTagItem(Colors.redAccent, "Siti (Menteng)"),
              _buildMapTagItem(const Color(0xFF10B981), "Budi (BSD City)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = _getTextColor();
    final textSub = _getTextSubColor();

    return Drawer(
      backgroundColor: _getScaffoldBg(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Avatar Photo
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                  backgroundImage: _vendorProfile != null && _vendorProfile!['image'] != null
                      ? getCustomImageProvider(_vendorProfile!['image']!)
                      : null,
                  child: _vendorProfile == null || _vendorProfile!['image'] == null
                      ? const Icon(Icons.person, size: 36, color: Color(0xFF10B981))
                      : null,
                ),
                const SizedBox(height: 16),
                // Vendor Name
                Text(
                  _vendorProfile != null ? _vendorProfile!['name'] ?? 'Studio Vendor' : 'Studio Vendor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  DatabaseHelper.currentUserEmail ?? 'vendor@nexabook.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Drawer Navigation List Tiles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // 1. Dashboard
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _tabController!.animateTo(0); // Jump to Dashboard tab
                  },
                ),
                // 2. Detail Profil
                _buildDrawerItem(
                  icon: Icons.account_circle_outlined,
                  title: 'Detail Profil',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    setState(() {
                      _activeTabIndex = 0; // Profile Info sub-tab
                    });
                    _tabController!.animateTo(2); // Jump to Edit Profil tab
                  },
                ),
                // 3. Pengaturan
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    setState(() {
                      _activeTabIndex = 3; // Settings sub-tab
                    });
                    _tabController!.animateTo(2); // Jump to Edit Profil tab
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Divider(),
                ),
                // 4. Keluar (Logout)
                _buildDrawerItem(
                  icon: Icons.logout_outlined,
                  title: 'Keluar',
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _showLogoutDialog(); // Trigger logout confirmation
                  },
                ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'NexaBook Vendor v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: textSub.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF10B981), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor ?? _getTextColor(),
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Widget _buildMapPin(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 0.8),
          ),
          child: Text(
            label.split(' ')[0],
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 1),
        Icon(Icons.location_on, color: color, size: 16),
      ],
    );
  }

  Widget _buildMapTagItem(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  // DIALOG BUILDERS & HELPER POPUPS

  void _showAddAgendaDialog() {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardBg(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tambah Agenda Manual', style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor())),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: _buildFormInputDecoration('Nama Klien'),
                style: TextStyle(color: _getTextColor()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: _buildFormInputDecoration('Jenis Acara (Contoh: Wedding)'),
                style: TextStyle(color: _getTextColor()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: _buildFormInputDecoration('Lokasi Acara'),
                style: TextStyle(color: _getTextColor()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: _buildFormInputDecoration('Waktu (Contoh: 10:00 - 12:00)'),
                style: TextStyle(color: _getTextColor()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Agenda "${nameCtrl.text}" berhasil ditambahkan secara manual!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // C. VENDOR PORTAL - EDIT PROFILE TAB (Premium Multi-tab Settings Layout)
  Widget _buildEditProfileTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                  left: 20.0, right: 20.0, top: 16.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Section
                  _buildProfileHeaderWidget(),
                  const SizedBox(height: 24),

                  // Tabs Bar
                  _buildTabsRowWidget(),
                  const SizedBox(height: 24),

                  // Active Tab section body
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_activeTabIndex == 0)
                          _buildBasicInformationCard()
                        else if (_activeTabIndex == 1)
                          _buildPricingPackagesSection()
                        else if (_activeTabIndex == 2)
                          _buildPortfolioSection()
                        else
                          _buildSettingsSection(),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // Top-anchored warning warning of unsaved changes overlay
            _buildBottomBannerBarWidget(),
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDER: PREMIUM PROFILE HEADER
  Widget _buildProfileHeaderWidget() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    width: 4,
                  ),
                  image: DecorationImage(
                    image: getCustomImageProvider(
                      _vendorProfile != null && _vendorProfile!['image'] != null
                          ? _vendorProfile!['image']!
                          : 'assets/images/bg.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _selectCoverPhoto,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Studio Vendor Jasa',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _descController.text.isNotEmpty
                ? (_descController.text.length > 80
                    ? "${_descController.text.substring(0, 80)}..."
                    : _descController.text)
                : 'Layanan jasa visual premium di NexaBook.',
            style: TextStyle(
              fontSize: 13,
              color: _getTextSubColor(),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: const Text(
                  'Verified Partner',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getBorderColor(),
                  ),
                ),
                child: Text(
                  'Top Rated',
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: TABS SCROLLABLE ROW
  Widget _buildTabsRowWidget() {
    final List<String> tabTitles = [
      'Profile Info',
      'Services & Pricing',
      'Portfolio',
      'Settings'
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _getBorderColor(), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabTitles.length, (index) {
            final isSelected = _activeTabIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabTitles[index],
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF10B981) : _getTextSubColor(),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // WIDGET BUILDER: BASIC INFORMATION FORM
  Widget _buildBasicInformationCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Studio Name Input
          _buildFormLabel('Nama Jasa / Studio'),
          TextFormField(
            controller: _nameController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormInputDecoration('Masukkan nama studio foto/video Anda'),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 20),

          // Primary Category Dropdown
          _buildFormLabel('Kategori Jasa Utama'),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            dropdownColor: _getCardBg(),
            style: TextStyle(color: _getTextColor(), fontSize: 14),
            decoration: _buildFormInputDecoration('Pilih Kategori Jasa'),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w500)),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCategory = newValue;
                  _selectedType = newValue; // Sync Category to Database Type!
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // Professional Bio Textarea
          _buildFormLabel('Professional Bio (Deskripsi)'),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            style: TextStyle(color: _getTextColor(), fontSize: 14),
            decoration: _buildFormInputDecoration('Tuliskan rincian studio dan peralatan Anda...'),
            onChanged: (text) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: SERVICES & PRICING
  Widget _buildPricingPackagesSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.payment_outlined, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Pricing Packages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _addNewPackage,
                child: const Text(
                  '+ Add Package',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pricingPackages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final package = _pricingPackages[index];
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: _getBorderColor(),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            package['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: _getTextSubColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package['price'].toString().startsWith('Rp')
                              ? package['price'].toString()
                              : 'Rp${_formatNumberString(package['price'].toString())}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Starting from',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTextSubColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _pricingPackages.removeAt(index);
                            });
                          },
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: PORTFOLIO SECTION
  Widget _buildPortfolioSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.photo_library_outlined, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Upload Portfolio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _uploadPortfolioFile,
                icon: const Icon(Icons.upload, size: 14),
                label: const Text('Upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _portfolioItems.length + 1,
            itemBuilder: (context, index) {
              if (index < _portfolioItems.length) {
                final item = _portfolioItems[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      getCustomImageProvider(item['imageUrl']!) is AssetImage
                          ? Image.asset(item['imageUrl']!, fit: BoxFit.cover)
                          : Image.network(item['imageUrl']!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.black87.withOpacity(0.65),
                          child: Text(
                            item['title']!,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _portfolioItems.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4.0),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: _uploadPortfolioFile,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _getBorderColor(), width: 1.5),
                      borderRadius: BorderRadius.circular(16.0),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B).withOpacity(0.2)
                          : Colors.grey.shade50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: _getTextSubColor(), size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Add Media',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getTextSubColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: SETTINGS (Availability + Location + Features)
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _getCardBg(),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings_outlined, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Portal & Service Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pricing / Price Input
          _buildFormLabel('Harga Dasar Layanan (Contoh: Rp2.500.000)'),
          TextFormField(
            controller: _priceController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Harga tidak boleh kosong' : null,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormInputDecoration('Masukkan harga minimal jasa Rp'),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Location Input
          _buildFormLabel('Lokasi Pelayanan Utama'),
          TextFormField(
            controller: _locationController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi tidak boleh kosong' : null,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormInputDecoration('Masukkan wilayah jangkauan Anda'),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Features Input
          _buildFormLabel('Fitur Keunggulan Paket (Pisahkan dengan koma ",")'),
          TextFormField(
            controller: _featuresController,
            style: TextStyle(color: _getTextColor()),
            decoration: _buildFormInputDecoration('Contoh: Kamera Sony A7IV, Unlimited Shoots, Frame 16R'),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 24),

          // Availability Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Ketersediaan Bisnis',
                    style: TextStyle(fontSize: 13, color: _getTextColor(), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable ? 'Menerima Pesanan' : 'Tutup Sementara',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isAvailable ? const Color(0xFF10B981) : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isAvailable,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) {
                  setState(() {
                    _isAvailable = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: FLOATING BOTTOM UNSAVED CHANGES BANNER
  Widget _buildBottomBannerBarWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _getCardBg(),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unsaved Changes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap Save to persist details.',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTextSubColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _loadVendorData(); // Reloads vendor data to discard unsaved updates!
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perubahan dibatalkan.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Discard', style: TextStyle(color: _getTextSubColor(), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: _handleSaveProfile, // Calls SQLite Save function!
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG: ADD PRICING PACKAGE
  void _addNewPackage() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _getCardBg(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: _getBorderColor(), width: 1),
          ),
          title: const Text(
            'Add Pricing Package',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: _getTextColor()),
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: TextStyle(color: _getTextColor()),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: _getTextColor()),
                  decoration: const InputDecoration(
                    labelText: 'Price (Rp)',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  setState(() {
                    _pricingPackages.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'description': descController.text,
                      'price': int.tryParse(priceController.text) ?? 0,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
              ),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // PORTFOLIO PHOTO UPLOADER
  void _uploadPortfolioFile() {
    setState(() {
      _portfolioItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrl': 'assets/images/bg2.png', // Premium local preset asset
        'title': 'Uploaded Work Project',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated image added to your portfolio!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF10B981),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorChatRoomPage(
                    clientName: chat['name'],
                    clientInitial: chat['initial'],
                  ),
                ),
              );
            },
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

class _MapPathPainter extends CustomPainter {
  final bool isDark;
  _MapPathPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.4, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height);

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
