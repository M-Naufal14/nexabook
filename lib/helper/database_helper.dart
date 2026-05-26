import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Session user aktif
  static String? currentUserEmail = 'naufal@gmail.com'; // Default user untuk testing
  static String? currentUserRole = 'Pelanggan';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inisialisasi FFI jika berjalan di platform Windows/Linux Desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'nexabook.db');

    return await openDatabase(
      pathString,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE vendors ADD COLUMN owner_email TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN image TEXT');
      } catch (e) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        image TEXT
      )
    ''');

    // 2. Tabel vendors
    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_email TEXT,
        name TEXT,
        type TEXT,
        rating TEXT,
        reviews INTEGER,
        location TEXT,
        price TEXT,
        priceRaw INTEGER,
        ratingRaw REAL,
        image TEXT,
        desc TEXT,
        features TEXT
      )
    ''');

    // 3. Tabel favorites (relasi user & vendor terfavorit)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT,
        vendor_id INTEGER,
        UNIQUE(user_email, vendor_id)
      )
    ''');

    // 4. Tabel bookings (transaksi pemesanan)
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_code TEXT,
        user_email TEXT,
        vendor_id INTEGER,
        type TEXT,
        date TEXT,
        price TEXT,
        status TEXT
      )
    ''');

    // Seeding data awal
    await _seedUsers(db);
    await _seedVendors(db);
  }

  Future<void> _seedUsers(Database db) async {
    await db.insert('users', {
      'email': 'naufal@gmail.com',
      'password': 'password123',
      'role': 'Pelanggan',
    });
    await db.insert('users', {
      'email': 'admin@nexabook.com',
      'password': 'admin',
      'role': 'Admin',
    });
    await db.insert('users', {
      'email': 'nexa@vendor.com',
      'password': 'vendor123',
      'role': 'Vendor',
    });
    await db.insert('users', {
      'email': 'kisah@vendor.com',
      'password': 'vendor123',
      'role': 'Vendor',
    });
    await db.insert('users', {
      'email': 'arsip@vendor.com',
      'password': 'vendor123',
      'role': 'Vendor',
    });
    await db.insert('users', {
      'email': 'lensa@vendor.com',
      'password': 'vendor123',
      'role': 'Vendor',
    });
    await db.insert('users', {
      'email': 'frame@vendor.com',
      'password': 'vendor123',
      'role': 'Vendor',
    });
  }

  Future<void> _seedVendors(Database db) async {
    final List<Map<String, dynamic>> vendors = [
      {
        'owner_email': 'nexa@vendor.com',
        'name': 'Nexa Visual',
        'type': 'Fotografer',
        'rating': '5.0',
        'reviews': 128,
        'location': 'Pamekasan',
        'price': 'Rp3.500.000',
        'priceRaw': 3500000,
        'ratingRaw': 5.0,
        'image': 'assets/images/nexavisual.png',
        'desc': 'Spesialis fotografi pernikahan dan pre-wedding dengan gaya sinematik modern. Menggunakan peralatan high-end untuk memastikan setiap momen berharga Anda diabadikan dengan sempurna.',
        'features': jsonEncode(['2 Fotografer Profesional', 'Unlimited Shoots', 'Album Cetak Premium 20x30cm', 'Semua File di Google Drive', 'Gratis Frame 16R']),
      },
      {
        'owner_email': 'kisah@vendor.com',
        'name': 'Kisah Kita',
        'type': 'Fotografer',
        'rating': '4.9',
        'reviews': 96,
        'location': 'Sumenep',
        'price': 'Rp2.800.000',
        'priceRaw': 2800000,
        'ratingRaw': 4.9,
        'image': 'assets/images/kisahkita.png',
        'desc': 'Mengabadikan kehangatan kisah cinta Anda lewat jepretan bernuansa hangat dan penuh emosi. Sempurna untuk acara lamaran, tunangan, dan pernikahan intim.',
        'features': jsonEncode(['1 Fotografer + 1 Asisten', '50 Foto Ter-edit', 'USB Flashdisk Berisi Semua File', 'Cetak 10 Lembar 4R', 'Photobook 40 Halaman']),
      },
      {
        'owner_email': 'arsip@vendor.com',
        'name': 'Arsip Kita',
        'type': 'Videografer',
        'rating': '4.8',
        'reviews': 75,
        'location': 'Madura',
        'price': 'Rp2.500.000',
        'priceRaw': 2500000,
        'ratingRaw': 4.8,
        'image': 'assets/images/arsipkita.png',
        'desc': 'Spesialis video dokumenter pernikahan, teaser pre-wedding, dan cinematic highlight. Kami merangkai memori indah Anda menjadi film pendek yang emosional dan abadi.',
        'features': jsonEncode(['2 Videografer & Drone Pilot', 'Video Highlight 3 Menit (Teaser)', 'Video Full Dokumenter 15 Menit', 'Kualitas Video 4K Ultra HD', 'Revisi Video 2 Kali']),
      },
      {
        'owner_email': 'lensa@vendor.com',
        'name': 'Lensa Creative',
        'type': 'Fotografer',
        'rating': '4.7',
        'reviews': 64,
        'location': 'Bandung',
        'price': 'Rp1.800.000',
        'priceRaw': 1800000,
        'ratingRaw': 4.7,
        'image': 'assets/images/bg2.png',
        'desc': 'Fotografi wisuda, korporat, dan potret keluarga dengan gaya minimalis, bersih, dan modern. Kami berfokus pada detail karakter unik setiap individu.',
        'features': jsonEncode(['1 Fotografer Studio', 'Sesi Foto 2 Jam', 'Gratis Sewa Kostum Wisuda', '10 Foto Cetak + Frame', 'Softcopy Google Drive']),
      },
      {
        'owner_email': 'frame@vendor.com',
        'name': 'Frame Moment',
        'type': 'Videografer',
        'rating': '4.6',
        'reviews': 42,
        'location': 'Surabaya',
        'price': 'Rp2.200.000',
        'priceRaw': 2200000,
        'ratingRaw': 4.6,
        'image': 'assets/images/bg1.png',
        'desc': 'Pembuatan video promosi komersial, event korporat, dan klip musik visual beresolusi tinggi. Kreativitas tanpa batas untuk memenuhi kebutuhan visual Anda.',
        'features': jsonEncode(['1 Sutradara + 2 Kameramen', 'Konsep Scriptwriting & Storyboard', 'Voice Over & Backsound Berlisensi', 'Motion Graphics Sederhana', 'Video Promosi 60 Detik']),
      }
    ];

    for (final vendor in vendors) {
      await db.insert('vendors', vendor);
    }

    // Seed default booking
    await db.insert('bookings', {
      'booking_code': 'BK-99281',
      'user_email': 'naufal@gmail.com',
      'vendor_id': 1,
      'type': 'Wedding Session',
      'date': 'Sabtu, 24 Mei 2026 (19:00 WIB)',
      'price': 'Rp3.500.000',
      'status': 'Aktif',
    });

    await db.insert('bookings', {
      'booking_code': 'BK-88371',
      'user_email': 'naufal@gmail.com',
      'vendor_id': 2,
      'type': 'Intimate Lamaran',
      'date': 'Senin, 18 November 2026 (09:00 WIB)',
      'price': 'Rp2.800.000',
      'status': 'Menunggu',
    });

    await db.insert('bookings', {
      'booking_code': 'BK-77462',
      'user_email': 'naufal@gmail.com',
      'vendor_id': 3,
      'type': 'Cinematic Highlight',
      'date': 'Kamis, 01 September 2026 (17:00 WIB)',
      'price': 'Rp2.500.000',
      'status': 'Selesai',
    });

    // Seed default favorit
    await db.insert('favorites', {
      'user_email': 'naufal@gmail.com',
      'vendor_id': 1,
    });
  }

  // ==================== CRUD AUTENTIKASI ====================

  Future<bool> registerUser(String email, String password, String role) async {
    final db = await database;
    try {
      await db.insert('users', {
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      });
      return true;
    } catch (e) {
      return false; // Email duplikat atau gagal
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password, String role) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ? AND role = ?',
      whereArgs: [email.trim().toLowerCase(), password, role],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // ==================== CRUD VENDOR ====================

  Future<List<Map<String, dynamic>>> getVendors({
    String searchQuery = '',
    String selectedType = 'Semua',
    String sortBy = 'Default',
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery.isNotEmpty) {
      whereClause += '(name LIKE ? OR location LIKE ? OR type LIKE ?)';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    if (selectedType != 'Semua') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(selectedType);
    }

    String? orderBy;
    if (sortBy == 'Harga Terendah') {
      orderBy = 'priceRaw ASC';
    } else if (sortBy == 'Rating Tertinggi') {
      orderBy = 'ratingRaw DESC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'vendors',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      final featuresStr = maps[i]['features'] as String?;
      List<String> featuresList = [];
      if (featuresStr != null) {
        try {
          featuresList = List<String>.from(jsonDecode(featuresStr));
        } catch (e) {
          featuresList = [];
        }
      }

      final vendorMap = Map<String, dynamic>.from(maps[i]);
      vendorMap['features'] = featuresList;
      return vendorMap;
    });
  }

  // ==================== CRUD FAVORIT ====================

  Future<bool> isFavorite(String email, int vendorId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_email = ? AND vendor_id = ?',
      whereArgs: [email.toLowerCase(), vendorId],
    );
    return maps.isNotEmpty;
  }

  Future<void> toggleFavorite(String email, int vendorId) async {
    final db = await database;
    final isFav = await isFavorite(email, vendorId);
    if (isFav) {
      await db.delete(
        'favorites',
        where: 'user_email = ? AND vendor_id = ?',
        whereArgs: [email.toLowerCase(), vendorId],
      );
    } else {
      await db.insert('favorites', {
        'user_email': email.toLowerCase(),
        'vendor_id': vendorId,
      });
    }
  }

  Future<int> getFavoriteCount(String email) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return maps.length;
  }

  // ==================== CRUD BOOKING ====================

  Future<void> createBooking(String email, int vendorId, String type, String price, [String? customDate]) async {
    final db = await database;
    
    // Ambil data vendor
    final vendorMaps = await db.query('vendors', where: 'id = ?', whereArgs: [vendorId]);
    if (vendorMaps.isEmpty) return;

    // Generate kode booking unik BK-#####
    final now = DateTime.now();
    final randomCode = 'BK-${(10000 + (db.hashCode % 90000)) + (now.millisecond * 17) % 90000}';

    String dateToSave;
    if (customDate != null) {
      dateToSave = customDate;
    } else {
      // Format tanggal indonesia e.g. Sabtu, 24 Mei 2026
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      final dayName = days[now.weekday % 7];
      final monthName = months[now.month - 1];
      dateToSave = '$dayName, ${now.day} $monthName ${now.year}';
    }

    await db.insert('bookings', {
      'booking_code': randomCode,
      'user_email': email.toLowerCase(),
      'vendor_id': vendorId,
      'type': type,
      'date': dateToSave,
      'price': price,
      'status': 'Aktif',
    });
  }

  Future<List<Map<String, dynamic>>> getBookings(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, v.name as name, v.image as image, v.location as location
      FROM bookings b
      JOIN vendors v ON b.vendor_id = v.id
      WHERE b.user_email = ?
      ORDER BY b.id DESC
    ''', [email.toLowerCase()]);
    
    return maps;
  }

  Future<int> getBookingCount(String email) async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: 'user_email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return maps.length;
  }

  // ==================== USER PROFILE IMAGE ====================

  Future<String?> getUserImage(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      columns: ['image'],
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (maps.isNotEmpty) {
      return maps.first['image'] as String?;
    }
    return null;
  }

  Future<void> updateUserImage(String email, String imagePath) async {
    final db = await database;
    await db.update(
      'users',
      {'image': imagePath},
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  // ==================== CRUD CUSTOM VENDOR PORTAL ====================

  Future<Map<String, dynamic>?> getVendorByOwnerEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vendors',
      where: 'owner_email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (maps.isNotEmpty) {
      final featuresStr = maps.first['features'] as String?;
      List<String> featuresList = [];
      if (featuresStr != null) {
        try {
          featuresList = List<String>.from(jsonDecode(featuresStr));
        } catch (e) {
          featuresList = [];
        }
      }
      final vendorMap = Map<String, dynamic>.from(maps.first);
      vendorMap['features'] = featuresList;
      return vendorMap;
    }
    return null;
  }

  Future<bool> createOrUpdateVendor(Map<String, dynamic> vendorData) async {
    final db = await database;
    final String email = (vendorData['owner_email'] as String).toLowerCase();
    
    final existing = await getVendorByOwnerEmail(email);
    
    final map = Map<String, dynamic>.from(vendorData);
    map['owner_email'] = email;
    if (map['features'] is List) {
      map['features'] = jsonEncode(map['features']);
    }

    try {
      if (existing != null) {
        await db.update(
          'vendors',
          map,
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
      } else {
        map['rating'] = '5.0';
        map['ratingRaw'] = 5.0;
        map['reviews'] = 0;
        map['image'] = map['image'] ?? 'assets/images/bg.png';
        await db.insert('vendors', map);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBookingsForVendor(int vendorId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, u.email as user_email
      FROM bookings b
      LEFT JOIN users u ON b.user_email = u.email
      WHERE b.vendor_id = ?
      ORDER BY b.id DESC
    ''', [vendorId]);
    return maps;
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    final db = await database;
    try {
      await db.update(
        'bookings',
        {'status': status},
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== CRUD ADMIN PORTAL ====================

  Future<List<Map<String, dynamic>>> getAllUsersAdmin() async {
    final db = await database;
    return await db.query('users', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getAllBookingsAdmin() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, v.name as name, v.image as image 
      FROM bookings b
      JOIN vendors v ON b.vendor_id = v.id
      ORDER BY b.id DESC
    ''');
    return maps;
  }

  Future<bool> deleteVendor(int id) async {
    final db = await database;
    try {
      await db.delete('vendors', where: 'id = ?', whereArgs: [id]);
      await db.delete('favorites', where: 'vendor_id = ?', whereArgs: [id]);
      await db.delete('bookings', where: 'vendor_id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    final db = await database;
    try {
      final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty && maps.first['role'] == 'Admin') return false;

      final email = maps.first['email'] as String;
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
      await db.delete('favorites', where: 'user_email = ?', whereArgs: [email]);
      await db.delete('bookings', where: 'user_email = ?', whereArgs: [email]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
