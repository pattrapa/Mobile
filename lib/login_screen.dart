import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _acceptLogin = false; // เก็บสถานะ Checkbox
  bool _obscurePassword = true; 
  bool _isLoading = false;

  @override
  void dispose() { //ถ้าเลิกใช้งานแล้วจะคืนค่าเดิม
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return; //เช็กว่า Widget นี้ยังอยู่บนหน้าจอไหม ถ้าไม่อยู่แล้วให้หยุดทำงานทันที

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptLogin) {
      _showSnackBar('Please check the checkbox first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isSuccess = await ApiService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;// เช็คว่าหน้านี้ยังอยู่ในจอหรือไม่

      if (isSuccess) {
        _showSnackBar('Login successful');
        _goToHome();
      } else {
        _showSnackBar('Invalid username or password');
      }
    } catch (e) {
      _showSnackBar('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF7AA6E8),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFDFDFF),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD7E9FF),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFEC8FB4),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 60,
              color: Color(0xFFEC8FB4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login to continue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C6BC0),
              ),
            ),
            const SizedBox(height: 24),
            _buildUsernameField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 12),
            _buildCheckbox(),
            const SizedBox(height: 18),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(
        label: 'Username',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration(
        label: 'Password',
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFEC8FB4),
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }

        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }

        return null;
      },
    );
  }

  Widget _buildCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptLogin,
          activeColor: const Color(0xFFEC8FB4),
          onChanged: (value) {
            setState(() => _acceptLogin = value ?? false);
          },
        ),
        const Expanded(
          child: Text(
            'I agree to login with this account',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC8FB4),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE4EC),
              Color(0xFFE3F2FD),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildLoginCard(),
          ),
        ),
      ),
    );
  }
}