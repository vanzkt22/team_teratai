import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'buyer'; // default role

Future<void> register() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email dan password harus diisi')),
    );
    return;
  }

  try {
    // 1. Daftarkan user ke auth
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;

    // Supabase signUp can return a user even if an error occurred (e.g., email already registered)
    // but the error field in AuthResponse would be populated.
    if (res.session == null && res.user == null) {
      // This case might indicate an issue where no session or user was created
      // without an explicit AuthException. Could be an internal Supabase issue.
      throw 'Registrasi gagal, tidak ada sesi atau pengguna yang dibuat.';
    }

    if (user == null) {
      // This should ideally be caught by AuthException, but as a fallback.
      throw 'Registrasi gagal: Pengguna tidak ditemukan setelah pendaftaran.';
    }

    // 2. Coba insert ke profiles dengan retry maksimal 10x
    bool inserted = false;
    for (int i = 0; i < 10; i++) {
      try {
        await supabase.from('profiles').insert({
          'id': user.id,
          'name': email.split('@')[0],
          'role': selectedRole,
        });
        inserted = true;
        break;
      } on PostgrestException catch (e) {
        // Handle database specific errors during profile insertion
        print('Error inserting profile (attempt ${i + 1}): ${e.message}');
        if (i == 9) { // If it's the last attempt
          throw 'Gagal menyimpan data profil ke database setelah beberapa kali percobaan: ${e.message}';
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        // Catch any other unexpected errors during profile insertion
        print('Unexpected error during profile insertion (attempt ${i + 1}): $e');
        if (i == 9) { // If it's the last attempt
          throw 'Terjadi kesalahan tidak terduga saat menyimpan data profil: $e';
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (!inserted) {
      throw 'Gagal menyimpan data profil ke database setelah beberapa kali percobaan.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil mendaftar! Silakan Login.')),
    );

    Navigator.pop(context); // Kembali ke halaman login
  } on AuthException catch (e) {
    String errorMessage;
    switch (e.statusCode) {
      case '400': // Bad Request, often due to invalid email/password format, or email already registered
        if (e.message.contains('Email already registered')) {
          errorMessage = 'Email ini sudah terdaftar. Silakan login atau gunakan email lain.';
        } else if (e.message.contains('Invalid email or password')) {
          errorMessage = 'Format email atau password tidak valid.';
        } else {
          errorMessage = 'Permintaan tidak valid: ${e.message}';
        }
        break;
      case '429': // Too Many Requests
        errorMessage = 'Terlalu banyak percobaan pendaftaran. Harap coba lagi nanti.';
        break;
      // You can add more specific status codes or error messages here
      default:
        errorMessage = 'Terjadi kesalahan autentikasi: ${e.message}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } on PostgrestException catch (e) {
    // This catches Postgrest (database) errors that might occur
    // if the retry logic above didn't explicitly throw, or for other unexpected DB issues.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal terhubung ke database: ${e.message}')),
    );
  } catch (e) {
    // General catch-all for any other unexpected errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mendaftar: $e')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: _inputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Password'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Daftar sebagai:'),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'buyer', child: Text('Pembeli')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: register,
                    child: const Text('Mendaftar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
}
