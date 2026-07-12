import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/home.dart';
import 'package:flutter_project/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _obscurePassword = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final isSuccess = await ApiService.login(username, password);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        _showSnackBar('Invalid username or password');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Login error: $e');
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    required Color primaryColor,
    required Color subtitleColor,
    required Color fillColor,
    required Color borderColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: subtitleColor,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: primaryColor,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFAF6EE);

    final cardColor = _isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;

    final textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF2D261E);

    final subtitleColor = _isDarkMode
        ? Colors.white60
        : const Color(0xFF6B5E4E);

    final primaryColor = _isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFD97706);

    final inputFillColor = _isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFFDFBF7);

    final borderColor = _isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFEFEBE3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            icon: Icon(
              _isDarkMode
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
              color: primaryColor,
            ),
            tooltip: _isDarkMode
                ? 'Switch to Warm Mode'
                : 'Switch to Dark Mode',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: 52,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SpeakFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Practice your presentation with confidence',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 38),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDarkMode
                              ? Colors.black.withValues(alpha: 0.22)
                              : const Color(0xFF7A7062)
                                  .withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your account to start practicing',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            color: textColor,
                          ),
                          onSubmitted: (_) {
                            FocusScope.of(context).requestFocus(
                              _passwordFocusNode,
                            );
                          },
                          decoration: _buildInputDecoration(
                            label: 'Username',
                            prefixIcon: Icons.person_outline_rounded,
                            primaryColor: primaryColor,
                            subtitleColor: subtitleColor,
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(
                            color: textColor,
                          ),
                          onSubmitted: (_) {
                            _handleLogin();
                          },
                          decoration: _buildInputDecoration(
                            label: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            primaryColor: primaryColor,
                            subtitleColor: subtitleColor,
                            fillColor: inputFillColor,
                            borderColor: borderColor,
                            suffixIcon: IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: subtitleColor,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor:
                                  primaryColor.withValues(alpha: 0.55),
                              foregroundColor: _isDarkMode
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        _isDarkMode
                                            ? const Color(0xFF0F172A)
                                            : Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login_rounded,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Improve your timing, pacing, and delivery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}