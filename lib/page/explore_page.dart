import 'package:flutter/material.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../helper/image_helper.dart';
import 'booking_flow_page.dart';

class ExplorePage extends StatefulWidget {
  final String? initialSearchQuery;
  final bool showBackButton;

  const ExplorePage({super.key, this.initialSearchQuery, this.showBackButton = false});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> _filteredVendors = [];
  late String _searchQuery;
  String _selectedType = 'Semua'; // 'Semua', 'Fotografer', 'Videografer'
  String _sortBy = 'Default'; // 'Default', 'Harga Terendah', 'Rating Tertinggi'
  Set<int> _favoriteVendorIds = {};

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
    _searchQuery = widget.initialSearchQuery ?? '';
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    final list = await FirebaseSqliteHelper.instance.getVendors(
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
    final email = FirebaseSqliteHelper.currentUserEmail;
    final Set<int> favs = {};
    if (email != null) {
      for (final vendor in _filteredVendors) {
        final id = vendor['id'] as int;
        if (await FirebaseSqliteHelper.instance.isFavorite(email, id)) {
          favs.add(id);
        }
      }
    }
    if (mounted) {
      setState(() {
        _favoriteVendorIds = favs;
      });
    }
  }

  Future<void> _toggleFavorite(int vendorId) async {
    final email = FirebaseSqliteHelper.currentUserEmail;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk terlebih dahulu untuk memfavoritkan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await FirebaseSqliteHelper.instance.toggleFavorite(email, vendorId);
    final isFavNow = await FirebaseSqliteHelper.instance.isFavorite(email, vendorId);

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFlowPage(vendor: vendor),
      ),
    ).then((_) {
      _loadVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _getScaffoldBg(),
      // Clean App Bar WITHOUT arrow back
      appBar: AppBar(
        backgroundColor: _getScaffoldBg(),
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: IconThemeData(color: const Color(0xFF118954)),
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
            color: _getScaffoldBg(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: _getCardBg(),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getBorderColor()),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: TextEditingController(text: _searchQuery),
                onChanged: (val) {
                  _searchQuery = val;
                  _loadVendors();
                },
                style: TextStyle(color: _getTextColor()),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF118954)),
                  hintText: "Cari fotografer, videografer, lokasi...",
                  hintStyle: TextStyle(color: _getTextSubColor(), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getTextSubColor()),
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
          color: isActive ? const Color(0xFF118954) : _getCardBg(),
          border: Border.all(color: isActive ? Colors.transparent : _getBorderColor()),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF118954).withOpacity( 0.3), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : _getTextColor()),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : _getTextColor(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = _favoriteVendorIds.contains(vendor['id']);
    return GestureDetector(
      onTap: () => _showVendorDetail(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: NexaImage(
                    imagePath: vendor['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                      color: const Color(0xFF118954).withOpacity(0.9),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(),
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(),
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
                  Divider(height: 1, color: _getBorderColor()),
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
