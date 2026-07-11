//login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/home_screen.dart'; // เปลี่ยนให้เปิดไปหน้า Home หลัก

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ฟังก์ชันการทำงานและตัวแปรจัดการ State (ห้ามเปลี่ยนฟังก์ชัน)
  bool _isLoading = false;
  bool _isDarkMode = false; // ตัวแปรสลับโหมดอุ่น/มืด มุมบนขวา

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // สมมติฟังก์ชันล็อกอินของ ApiService (อิงตามโครงสร้างเดิมของคุณ)
      final isSuccess = await ApiService.login(username, password); 

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showSnackBar('Invalid username or password');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // โทนสีอุ่น (Warm Cream) และ โหมดมืด (Dark Mode)
    final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAF6EE);
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2D261E);
    final subtitleColor = _isDarkMode ? Colors.white60 : const Color(0xFF6B5E4E);
    final primaryColor = _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFD97706);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ปุ่มสลับโหมดอุ่น-มืด มุมบนขวาตามต้องการ
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: primaryColor,
            ),
            tooltip: _isDarkMode ? 'Switch to Warm Mode' : 'Switch to Dark Mode',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ส่วนหัว App Logo / Icon สำหรับแอปฝึกพรีเซนต์
                Icon(
                  Icons.mic_none_rounded,
                  size: 72,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'SpeakFlow',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Master your presentation pacing',
                  style: TextStyle(
                    fontSize: 15,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 40),

                // กล่องฟอร์ม Login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isDarkMode ? Colors.transparent : const Color(0xFFEFEBE3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isDarkMode 
                            ? Colors.black.withValues(alpha: 0.2)
                            : const Color(0xFF7A7062).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ช่องกรอก Username
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                          filled: true,
                          fillColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFEBE3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ช่องกรอก Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
                          filled: true,
                          fillColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFEBE3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ปุ่ม Login
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_isDarkMode ? const Color(0xFF0F172A) : Colors.white),
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}