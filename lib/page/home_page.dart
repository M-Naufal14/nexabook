import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      body: SafeArea(
        child: Column(
          children: [

            
            // APP BAR
            
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // LOGO
                  Image.asset(
                    "assets/images/logo1.png",
                    width: 110,
                  ),

                  // ICON
                  Row(
                    children: [

                      iconButton(Icons.notifications_none),

                      const SizedBox(width: 12),

                      iconButton(Icons.chat_bubble_outline),

                    ],
                  ),
                ],
              ),
            ),

            
            // BODY
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  
                  // BANNER ATAS
                  
                  Container(
                    height: 220,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),

                      image: const DecorationImage(
                        image: AssetImage(
                          "assets/images/bg2.png",
                        ),
                        fit: BoxFit.cover,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Container(
                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),

                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,

                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Spacer(),

                          const Text(
                            "Temukan Vendor\nTerbaik Untuk\nMomen Spesialmu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 48,

                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF118954),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),

                              onPressed: () {},

                              child: const Text(
                                "Jelajahi Sekarang",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  
                  // SEARCH
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,

                        icon: Icon(
                          Icons.search,
                          color: Color(0xFF118954),
                        ),

                        hintText: "Cari fotografer atau videografer",
                        hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  
                  // KATEGORY
                  
                  const Text(
                    "Kategori",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children: [

                        categoryItem(
                          "Wedding",
                          "assets/images/wedding.png",
                        ),

                        categoryItem(
                          "Engagement",
                          "assets/images/engagement.png",
                        ),

                        categoryItem(
                          "Prewed",
                          "assets/images/prewedding.png",
                        ),

                        categoryItem(
                          "Graduation",
                          "assets/images/graduation.png",
                        ),

                        categoryItem(
                          "Lainnya",
                          "assets/images/lainnya.png",
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  
                  // REKOMENDASI
                  
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [

                      const Text(
                        "Rekomendasi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: Color(0xFF118954),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 290,

                    child: ListView(
                      scrollDirection: Axis.horizontal,

                      children: [

                        vendorCard(
                          "Nexa Visual",
                          "Pamekasan",
                          "4.9",
                          "Mulai 500K",
                          "assets/images/nexavisual.png",
                        ),

                        vendorCard(
                          "Kisah Kita",
                          "Sumenep",
                          "4.8",
                          "Mulai 650K",
                          "assets/images/kisahkita.png",
                        ),

                        vendorCard(
                          "Arsip Kita",
                          "Madura",
                          "5.0",
                          "Mulai 700K",
                          "assets/images/arsipkita.png",
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  
                  // PROMO
                  
                  Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),

                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF118954),
                          Color(0xFF0D6E43),
                        ],
                      ),
                    ),

                    child: Row(
                      children: [

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Diskon Hingga 50%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                "Booking vendor favoritmu sekarang juga.",
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 60,
                          height: 60,

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),

      
      // FLOATING NAVBAR
      
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),

        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,

          children: [

            navItem(Icons.home, 0),

            navItem(Icons.explore, 1),

            navItem(Icons.calendar_today, 2),

            navItem(Icons.chat_bubble_outline, 3),

            navItem(Icons.person_outline, 4),

          ],
        ),
      ),
    );
  }

  
  // ICON BUTTON
  
  Widget iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Icon(icon),
    );
  }

  
  // KATEGORY ITEM
  
  Widget categoryItem(
    String title,
    String imagePath,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16),

      child: Column(
        children: [

          Container(
            width: 65,
            height: 65,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                ),
              ],
            ),

            child: Image.asset(
              imagePath,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  
  // VENDOR CARD
  
  Widget vendorCard(
    String name,
    String location,
    String rating,
    String price,
    String image,
  ) {
    return Container(
      width: 190,

      margin: const EdgeInsets.only(right: 18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),

            child: Image.asset(
              image,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.verified,
                      color: Color(0xFF118954),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 4),

                    Text(rating),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF118954),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  // NAV ITEM
  
  Widget navItem(
    IconData icon,
    int index,
  ) {
    bool active = selectedNav == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedNav = index;
        });
      },

      child: Icon(
        icon,
        size: 28,
        color: active
            ? const Color(0xFF118954)
            : Colors.grey,
      ),
    );
  }
}