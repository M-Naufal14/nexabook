import 'package:flutter/material.dart';
import '../helper/database_helper.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> _filteredVendors = [];
  String _searchQuery = '';
  String _selectedType = 'Semua'; // 'Semua', 'Fotografer', 'Videografer'
  String _sortBy = 'Default'; // 'Default', 'Harga Terendah', 'Rating Tertinggi'
  Set<int> _favoriteVendorIds = {};

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    final list = await DatabaseHelper.instance.getVendors(
      searchQuery: _searchQuery,
      selectedType: _selectedType,
      sortBy: _sortBy,
    );
    if (mounted) {
      setState(() {
        _filteredVendors = list;
      });
      await _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    final email = DatabaseHelper.currentUserEmail;
    if (email != null) {
      final Set<int> favs = {};
      for (final vendor in _filteredVendors) {
        final id = vendor['id'] as int;
        if (await DatabaseHelper.instance.isFavorite(email, id)) {
          favs.add(id);
        }
      }
      if (mounted) {
        setState(() {
          _favoriteVendorIds = favs;
        });
      }
    }
  }

  Future<void> _toggleFavorite(int vendorId) async {
    final email = DatabaseHelper.currentUserEmail;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk terlebih dahulu untuk memfavoritkan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await DatabaseHelper.instance.toggleFavorite(email, vendorId);
    final isFavNow = await DatabaseHelper.instance.isFavorite(email, vendorId);

    if (mounted) {
      setState(() {
        if (isFavNow) {
          _favoriteVendorIds.add(vendorId);
        } else {
          _favoriteVendorIds.remove(vendorId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavNow ? 'Ditambahkan ke Favorit!' : 'Dihapus dari Favorit'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isFavNow ? const Color(0xFF118954) : Colors.grey.shade800,
        ),
      );
    }
  }

  void _showVendorDetail(Map<String, dynamic> vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isFav = _favoriteVendorIds.contains(vendor['id']);
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: Column(
                  children: [
                    // Handle Bar
                    const SizedBox(height: 12),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detail Content
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          // Header Image Stack
                          Stack(
                            children: [
                              Image.asset(
                                vendor['image'],
                                height: 260,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, err, stack) => Container(
                                  height: 260,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      color: isFav ? Colors.red : Colors.grey.shade700,
                                    ),
                                    onPressed: () {
                                      _toggleFavorite(vendor['id']);
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Details Text
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Tag
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vendor['name'],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF118954).withOpacity( 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        vendor['type'],
                                        style: const TextStyle(
                                          color: Color(0xFF118954),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Location & Rating
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      vendor['location'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    const SizedBox(width: 24),
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${vendor['rating']} (${vendor['reviews']} Ulasan)",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 16),

                                // Description
                                const Text(
                                  "Tentang Vendor",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  vendor['desc'],
                                  style: TextStyle(
                                    height: 1.5,
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Features / Package Includes
                                const Text(
                                  "Paket Sudah Termasuk",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...((vendor['features'] as List<String>).map((feat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF118954)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            feat,
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price & Booking Action Panel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity( 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Mulai Dari",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vendor['price'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF118954),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF118954),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                final email = DatabaseHelper.currentUserEmail;
                                if (email == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Silakan masuk terlebih dahulu untuk memesan!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF118954),
                                    ),
                                  ),
                                );

                                await DatabaseHelper.instance.createBooking(
                                  email,
                                  vendor['id'],
                                  '${vendor['type']} Session',
                                  vendor['price'],
                                );

                                if (context.mounted) {
                                  Navigator.pop(context); // Tutup loading dialog
                                  Navigator.pop(context); // Tutup detail bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Berhasil mem-booking ${vendor['name']}! Silakan cek menu Jadwal.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF118954),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Pesan Sekarang",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // Clean App Bar WITHOUT arrow back
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        automaticallyImplyLeading: false, // Ensures no back arrow shows
        title: const Text(
          "Eksplorasi Vendor",
          style: TextStyle(
            color: Color(0xFF118954),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sticky Search Bar
          Container(
            color: const Color(0xFFF7F8FA),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) {
                  _searchQuery = val;
                  _loadVendors();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Color(0xFF118954)),
                  hintText: "Cari fotografer, videografer, lokasi...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          // Interactive Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Category filter toggler
                  _buildInteractiveFilterChip(
                    "Tipe: $_selectedType",
                    Icons.tune,
                    isActive: _selectedType != 'Semua',
                    onTap: () {
                      setState(() {
                        if (_selectedType == 'Semua') {
                          _selectedType = 'Fotografer';
                        } else if (_selectedType == 'Fotografer') {
                          _selectedType = 'Videografer';
                        } else {
                          _selectedType = 'Semua';
                        }
                      });
                      _loadVendors();
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Sort filter toggler
                  _buildInteractiveFilterChip(
                    "Urut: $_sortBy",
                    Icons.sort,
                    isActive: _sortBy != 'Default',
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'Default') {
                          _sortBy = 'Harga Terendah';
                        } else if (_sortBy == 'Harga Terendah') {
                          _sortBy = 'Rating Tertinggi';
                        } else {
                          _sortBy = 'Default';
                        }
                      });
                      _loadVendors();
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Active Filter Counter
                  if (_searchQuery.isNotEmpty || _selectedType != 'Semua' || _sortBy != 'Default')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedType = 'Semua';
                          _sortBy = 'Default';
                        });
                        _loadVendors();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE74C3C).withOpacity( 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.clear, size: 14, color: Color(0xFFE74C3C)),
                            SizedBox(width: 4),
                            Text(
                              "Reset",
                              style: TextStyle(fontSize: 12, color: Color(0xFFE74C3C), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Results List
          Expanded(
            child: _filteredVendors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Vendor tidak ditemukan",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Coba ganti kata kunci atau reset filter",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
                    itemCount: _filteredVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = _filteredVendors[index];
                      return _buildVendorCard(vendor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFilterChip(String label, IconData icon, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF118954) : Colors.white,
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF118954).withOpacity( 0.3), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: isActive ? Colors.white : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final isFav = _favoriteVendorIds.contains(vendor['id']);
    return GestureDetector(
      onTap: () => _showVendorDetail(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.asset(
                    vendor['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(vendor['id']),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity( 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity( 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF118954).withOpacity( 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vendor['type'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  vendor['location'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            vendor['rating'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            " (${vendor['reviews']})",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mulai dari",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vendor['price'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF118954),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF118954),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        onPressed: () => _showVendorDetail(vendor),
                        child: const Text(
                          "Detail",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
