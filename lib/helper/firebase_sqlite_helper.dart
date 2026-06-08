import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseSqliteHelper {
  // Singleton instance
  static final FirebaseSqliteHelper instance = FirebaseSqliteHelper._init();
  static Database? _database;

  FirebaseSqliteHelper._init();

  // Session user aktif
  static String? currentUserEmail;
  static String? currentUserRole;


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
      'password': 'admin123',
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

  Future<void> seedFirebaseUsers() async {
    final defaultUsers = [
      {'email': 'naufal@gmail.com', 'password': 'password123', 'role': 'Pelanggan'},
      {'email': 'admin@nexabook.com', 'password': 'admin123', 'role': 'Admin'},
      {'email': 'nexa@vendor.com', 'password': 'vendor123', 'role': 'Vendor'},
      {'email': 'kisah@vendor.com', 'password': 'vendor123', 'role': 'Vendor'},
      {'email': 'arsip@vendor.com', 'password': 'vendor123', 'role': 'Vendor'},
      {'email': 'lensa@vendor.com', 'password': 'vendor123', 'role': 'Vendor'},
      {'email': 'frame@vendor.com', 'password': 'vendor123', 'role': 'Vendor'},
    ];

    for (final u in defaultUsers) {
      try {
        final email = u['email']!;
        final password = u['password']!;
        final role = u['role']!;
        
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email.toLowerCase(),
            'role': role,
            'image': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint("Seeded firebase user: $email");
        }
      } catch (e) {
        // Abaikan jika email sudah terdaftar
      }
    }

    // Seed default vendors, bookings, and favorites
    await seedFirebaseVendors();
  }

  Future<void> seedFirebaseVendors() async {
    final List<Map<String, dynamic>> defaultVendors = [
      {
        'id': 1,
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
        'features': ['2 Fotografer Profesional', 'Unlimited Shoots', 'Album Cetak Premium 20x30cm', 'Semua File di Google Drive', 'Gratis Frame 16R'],
      },
      {
        'id': 2,
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
        'features': ['1 Fotografer + 1 Asisten', '50 Foto Ter-edit', 'USB Flashdisk Berisi Semua File', 'Cetak 10 Lembar 4R', 'Photobook 40 Halaman'],
      },
      {
        'id': 3,
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
        'features': ['2 Videografer & Drone Pilot', 'Video Highlight 3 Menit (Teaser)', 'Video Full Dokumenter 15 Menit', 'Kualitas Video 4K Ultra HD', 'Revisi Video 2 Kali'],
      },
      {
        'id': 4,
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
        'features': ['1 Fotografer Studio', 'Sesi Foto 2 Jam', 'Gratis Sewa Kostum Wisuda', '10 Foto Cetak + Frame', 'Softcopy Google Drive'],
      },
      {
        'id': 5,
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
        'features': ['1 Sutradara + 2 Kameramen', 'Konsep Scriptwriting & Storyboard', 'Voice Over & Backsound Berlisensi', 'Motion Graphics Sederhana', 'Video Promosi 60 Detik'],
      }
    ];

    for (final vendor in defaultVendors) {
      try {
        final id = vendor['id'] as int;
        final docRef = FirebaseFirestore.instance.collection('vendors').doc(id.toString());
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set(vendor);
          debugPrint("Seeded firebase vendor: ${vendor['name']}");
        }
      } catch (e) {
        debugPrint("Error seeding firebase vendor: $e");
      }
    }

    // Seed default booking
    final List<Map<String, dynamic>> defaultBookings = [
      {
        'id': 99281,
        'booking_code': 'BK-99281',
        'user_email': 'naufal@gmail.com',
        'vendor_id': 1,
        'type': 'Wedding Session',
        'date': 'Sabtu, 24 Mei 2026 (19:00 WIB)',
        'price': 'Rp3.500.000',
        'status': 'Aktif',
        'name': 'Nexa Visual',
        'image': 'assets/images/nexavisual.png',
        'location': 'Pamekasan',
      },
      {
        'id': 88371,
        'booking_code': 'BK-88371',
        'user_email': 'naufal@gmail.com',
        'vendor_id': 2,
        'type': 'Intimate Lamaran',
        'date': 'Senin, 18 November 2026 (09:00 WIB)',
        'price': 'Rp2.800.000',
        'status': 'Menunggu',
        'name': 'Kisah Kita',
        'image': 'assets/images/kisahkita.png',
        'location': 'Sumenep',
      },
      {
        'id': 77462,
        'booking_code': 'BK-77462',
        'user_email': 'naufal@gmail.com',
        'vendor_id': 3,
        'type': 'Cinematic Highlight',
        'date': 'Kamis, 01 September 2026 (17:00 WIB)',
        'price': 'Rp2.500.000',
        'status': 'Selesai',
        'name': 'Arsip Kita',
        'image': 'assets/images/arsipkita.png',
        'location': 'Madura',
      }
    ];

    for (final booking in defaultBookings) {
      try {
        final id = booking['id'] as int;
        final docRef = FirebaseFirestore.instance.collection('bookings').doc(id.toString());
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set(booking);
          debugPrint("Seeded firebase booking: ${booking['booking_code']}");
        }
      } catch (e) {
        debugPrint("Error seeding firebase booking: $e");
      }
    }

    // Seed default favorite
    try {
      final docId = "naufal@gmail.com_1";
      final docRef = FirebaseFirestore.instance.collection('favorites').doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'user_email': 'naufal@gmail.com',
          'vendor_id': 1,
        });
        debugPrint("Seeded firebase favorite for naufal@gmail.com on vendor 1");
      }
    } catch (e) {
      debugPrint("Error seeding firebase favorite: $e");
    }
  }

  Future<bool> registerUser(String email, String password, String role) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email.trim().toLowerCase(),
          'role': role,
          'image': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error registering user: $e");
      return false; 
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password, String role) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['role'] == role) {
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint("Error logging in: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> loginUserWithoutRole(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
        }
        return {
          'email': user.email,
          'role': 'Pelanggan',
          'uid': user.uid,
        };
      }
    } catch (e) {
      debugPrint("Error logging in without role: $e");
    }
    return null;
  }

  // ==================== CRUD VENDOR ====================

  Future<List<Map<String, dynamic>>> getVendors({
    String searchQuery = '',
    String selectedType = 'Semua',
    String sortBy = 'Default',
  }) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('vendors').get();
      List<Map<String, dynamic>> list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        List<String> featuresList = [];
        if (data['features'] != null) {
          try {
            featuresList = List<String>.from(data['features'] as List);
          } catch (e) {
            featuresList = [];
          }
        }
        final vendorMap = Map<String, dynamic>.from(data);
        vendorMap['features'] = featuresList;
        return vendorMap;
      }).toList();

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        list = list.where((v) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final loc = (v['location'] ?? '').toString().toLowerCase();
          final type = (v['type'] ?? '').toString().toLowerCase();
          return name.contains(q) || loc.contains(q) || type.contains(q);
        }).toList();
      }

      // Filter by type
      if (selectedType != 'Semua') {
        list = list.where((v) => v['type'] == selectedType).toList();
      }

      // Sort
      if (sortBy == 'Harga Terendah') {
        list.sort((a, b) => (a['priceRaw'] as num? ?? 0).compareTo(b['priceRaw'] as num? ?? 0));
      } else if (sortBy == 'Rating Tertinggi') {
        list.sort((a, b) => (b['ratingRaw'] as num? ?? 0.0).compareTo(a['ratingRaw'] as num? ?? 0.0));
      }

      return list;
    } catch (e) {
      debugPrint("Error getVendors from Firestore: $e");
      return [];
    }
  }

  // ==================== CRUD FAVORIT ====================

  Future<bool> isFavorite(String email, int vendorId) async {
    try {
      final docId = "${email.toLowerCase()}_$vendorId";
      final doc = await FirebaseFirestore.instance.collection('favorites').doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error isFavorite: $e");
      return false;
    }
  }

  Future<void> toggleFavorite(String email, int vendorId) async {
    try {
      final docId = "${email.toLowerCase()}_$vendorId";
      final docRef = FirebaseFirestore.instance.collection('favorites').doc(docId);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'user_email': email.toLowerCase(),
          'vendor_id': vendorId,
        });
      }
    } catch (e) {
      debugPrint("Error toggleFavorite: $e");
    }
  }

  Future<int> getFavoriteCount(String email) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('favorites')
          .where('user_email', isEqualTo: email.toLowerCase())
          .get();
      return qs.docs.length;
    } catch (e) {
      debugPrint("Error getFavoriteCount: $e");
      return 0;
    }
  }

  // ==================== CRUD BOOKING ====================

  Future<void> createBooking(String email, int vendorId, String type, String price, [String? customDate]) async {
    try {
      // 1. Fetch vendor from Firestore
      final vendorQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('id', isEqualTo: vendorId)
          .limit(1)
          .get();
      if (vendorQuery.docs.isEmpty) return;
      final vendorData = vendorQuery.docs.first.data();

      // Generate booking code BK-#####
      final now = DateTime.now();
      final randomCode = 'BK-${10000 + (now.millisecondsSinceEpoch % 90000)}';

      String dateToSave;
      if (customDate != null) {
        dateToSave = customDate;
      } else {
        final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
        final dayName = days[now.weekday % 7];
        final monthName = months[now.month - 1];
        dateToSave = '$dayName, ${now.day} $monthName ${now.year}';
      }

      final bookingId = now.millisecondsSinceEpoch;
      final vendorOwnerEmail = (vendorData['owner_email'] as String? ?? '').toLowerCase();

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId.toString()).set({
        'id': bookingId,
        'booking_code': randomCode,
        'user_email': email.toLowerCase(),
        'vendor_owner_email': vendorOwnerEmail,
        'vendor_id': vendorId,
        'type': type,
        'date': dateToSave,
        'price': price,
        'status': 'Aktif',
        'name': vendorData['name'] ?? '',
        'image': vendorData['image'] ?? '',
        'location': vendorData['location'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error createBooking: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getBookings(String email) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('user_email', isEqualTo: email.toLowerCase())
          .get();
      
      final list = qs.docs.map((doc) => Map<String, dynamic>.from(doc.data())).toList();
      list.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
      return list;
    } catch (e) {
      debugPrint("Error getBookings: $e");
      return [];
    }
  }

  Future<int> getBookingCount(String email) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('user_email', isEqualTo: email.toLowerCase())
          .get();
      return qs.docs.length;
    } catch (e) {
      debugPrint("Error getBookingCount: $e");
      return 0;
    }
  }

  // ==================== USER PROFILE IMAGE ====================

  Future<String?> getUserImage(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['image'] as String?;
      }
    } catch (e) {
      debugPrint("Error getting user image from Firestore: $e");
    }
    return null;
  }

  Future<void> updateUserImage(String email, String imagePath) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'image': imagePath,
        });
      }
    } catch (e) {
      debugPrint("Error updating user image in Firestore: $e");
    }
  }

  // ==================== CRUD CUSTOM VENDOR PORTAL ====================

  Future<Map<String, dynamic>?> getVendorByOwnerEmail(String email) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('vendors')
          .where('owner_email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) {
        final data = qs.docs.first.data();
        List<String> featuresList = [];
        if (data['features'] != null) {
          try {
            featuresList = List<String>.from(data['features'] as List);
          } catch (e) {}
        }
        final vendorMap = Map<String, dynamic>.from(data);
        vendorMap['features'] = featuresList;
        return vendorMap;
      }
    } catch (e) {
      debugPrint("Error getVendorByOwnerEmail: $e");
    }
    return null;
  }

  Future<bool> createOrUpdateVendor(Map<String, dynamic> vendorData) async {
    try {
      final String email = (vendorData['owner_email'] as String).toLowerCase();
      final existing = await getVendorByOwnerEmail(email);
      
      final map = Map<String, dynamic>.from(vendorData);
      map['owner_email'] = email;
      if (map['features'] is String) {
        try {
          map['features'] = jsonDecode(map['features']);
        } catch (e) {
          map['features'] = [map['features']];
        }
      }

      if (existing != null) {
        final docId = existing['id'].toString();
        await FirebaseFirestore.instance.collection('vendors').doc(docId).update(map);
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch;
        map['id'] = newId;
        map['rating'] = '5.0';
        map['ratingRaw'] = 5.0;
        map['reviews'] = 0;
        map['image'] = map['image'] ?? 'assets/images/bg.png';
        await FirebaseFirestore.instance.collection('vendors').doc(newId.toString()).set(map);
      }
      return true;
    } catch (e) {
      debugPrint("Error createOrUpdateVendor: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBookingsForVendor(int vendorId) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('vendor_id', isEqualTo: vendorId)
          .get();
      
      final list = qs.docs.map((doc) => Map<String, dynamic>.from(doc.data())).toList();
      list.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
      return list;
    } catch (e) {
      debugPrint("Error getBookingsForVendor: $e");
      return [];
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId.toString())
          .update({'status': status});
      return true;
    } catch (e) {
      debugPrint("Error updateBookingStatus: $e");
      return false;
    }
  }

  // ==================== CRUD ADMIN PORTAL ====================

  Future<List<Map<String, dynamic>>> getAllUsersAdmin() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('email')
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id.hashCode,
          'uid': doc.id,
          'email': data['email'] ?? '',
          'password': '🔐 Encrypted',
          'role': data['role'] ?? 'Pelanggan',
          'image': data['image'],
        };
      }).toList();
    } catch (e) {
      debugPrint("Error getting all users for admin: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllBookingsAdmin() async {
    try {
      final qs = await FirebaseFirestore.instance.collection('bookings').get();
      final list = qs.docs.map((doc) => Map<String, dynamic>.from(doc.data())).toList();
      list.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
      return list;
    } catch (e) {
      debugPrint("Error getAllBookingsAdmin: $e");
      return [];
    }
  }

  Future<bool> deleteVendor(int id) async {
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(id.toString()).delete();
      
      final favsQuery = await FirebaseFirestore.instance
          .collection('favorites')
          .where('vendor_id', isEqualTo: id)
          .get();
      for (final doc in favsQuery.docs) {
        await doc.reference.delete();
      }

      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('vendor_id', isEqualTo: id)
          .get();
      for (final doc in bookingsQuery.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      debugPrint("Error deleteVendor: $e");
      return false;
    }
  }

  Future<bool> deleteUser(int id, [String? email]) async {
    if (email != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final role = doc.data()['role'] as String?;
          if (role == 'Admin') return false;
          await doc.reference.delete();
        }
        
        final favsQuery = await FirebaseFirestore.instance
            .collection('favorites')
            .where('user_email', isEqualTo: email.toLowerCase())
            .get();
        for (final doc in favsQuery.docs) {
          await doc.reference.delete();
        }

        final bookingsQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('user_email', isEqualTo: email.toLowerCase())
            .get();
        for (final doc in bookingsQuery.docs) {
          await doc.reference.delete();
        }
        return true;
      } catch (e) {
        debugPrint("Error deleting user from Firestore: $e");
        return false;
      }
    }
    return false;
  }

  // ==================== REAL-TIME CHAT ====================

  /// Generates a consistent chat room ID from two email addresses.
  /// The ID is always the same regardless of which user initiates.
  static String getChatRoomId(String emailA, String emailB) {
    final sorted = [emailA.toLowerCase(), emailB.toLowerCase()]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Sends a message to a Firestore chat room.
  Future<void> sendMessage(String chatRoomId, String senderEmail, String text) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderEmail': senderEmail.toLowerCase(),
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error sendMessage: $e");
    }
  }

  /// Returns a real-time stream of messages for a chat room, ordered by timestamp.
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Returns a stream of only the latest 1 message — for chat list preview & unread badge.
  Stream<QuerySnapshot<Map<String, dynamic>>> getLatestMessageStream(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }
}
