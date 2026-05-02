import 'package:flutter/material.dart';

class DaftarPage extends StatefulWidget {
    const DaftarPage({super.key});

    @override
    State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
    String? selectedRole;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Stack(
                children: [
                    SizedBox.expand(
                        child: Image.asset(
                            "assets/images/bg1.png",
                            fit: BoxFit.cover,
                        ),
                    ),                    

                    Center(
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: const Color(0xFF118954).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        "Daftar Sebagai",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                        ),
                                    ),

                                    const SizedBox(height: 8),

                                    SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: Container(                                        
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                    isExpanded: true,
                                                    value: selectedRole,
                                                    hint: const Text("Pilih Disini"),
                                                    items: ["Vendor", "Pelanggan"]
                                                    .map((item) => DropdownMenuItem<String>(
                                                        value: item,
                                                        child: Text(item),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                                        setState((){
                                                            selectedRole = value;
                                                        });
                                                    },
                                                ),
                                            ),
                                        ),
                                    ),

                                    const SizedBox(height: 16),

                                    const Text(
                                        "Email",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                        ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextField(
                                        decoration: InputDecoration(
                                            hintText: "Masukkan Email Anda",
                                            hintStyle: TextStyle(
                                                color: Colors.black.withOpacity(0.5),
                                            ),
                                        
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                            ),
                                        ),
                                    ),

                                    const SizedBox( height: 16),

                                    const Text(
                                        "Kata Sandi",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                        ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextField(
                                        obscureText: true,
                                        decoration: InputDecoration(
                                            hintText: "Masukkan Password",
                                            hintStyle: TextStyle(
                                                color: Colors.black.withOpacity(0.5),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                            ),
                                        ),
                                    ),

                                    const SizedBox(height: 16),

                                    SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF118954),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(35),
                                                ),
                                            ),
                                            onPressed: () {},
                                            child: const Text(
                                                "Masuk",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                ),
                                            ),
                                        ),
                                    ),
                                    
                                ],
                            ),
                        ),
                    ),

                ],
            ),
        );
    }
}