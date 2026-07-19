import 'package:flutter/material.dart';
import 'package:flutter_project/api_service.dart';
import 'package:flutter_project/decorative_background.dart';
import 'package:flutter_project/home.dart';
import 'package:flutter_project/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

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
      final isSuccess = await ApiService.login(
        username,
        password,
      );

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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color primary,
    required Color subtitle,
    required Color fill,
    required Color border,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: subtitle,
      ),
      prefixIcon: Icon(
        icon,
        color: primary,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, _) {
        final background = isDarkMode
            ? const Color(0xFF0B1220)
            : const Color(0xFFFFF9F1);

        final card = isDarkMode
            ? const Color(0xFF152238).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.94);

        final text = isDarkMode
            ? Colors.white
            : const Color(0xFF29231D);

        final subtitle = isDarkMode
            ? Colors.white60
            : const Color(0xFF74685A);

        final primary = isDarkMode
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF97316);

        final secondary = isDarkMode
            ? const Color(0xFF6366F1)
            : const Color(0xFFF59E0B);

        final inputFill = isDarkMode
            ? const Color(0xFF0F1A2C)
            : const Color(0xFFFFFCF8);

        final border = isDarkMode
            ? const Color(0xFF2C405D)
            : const Color(0xFFF1E5D6);

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(
                  right: 14,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: IconButton(
                  onPressed: ThemeController.toggleTheme,
                  icon: Icon(
                    isDarkMode
                        ? Icons.wb_sunny_outlined
                        : Icons.dark_mode_outlined,
                    color: primary,
                  ),
                  tooltip: isDarkMode
                      ? 'Switch to Warm Mode'
                      : 'Switch to Dark Mode',
                ),
              ),
            ],
          ),
          body: DecorativeBackground(
            isDarkMode: isDarkMode,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary,
                                secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_rounded,
                                size: 72,
                                color: Colors.white,
                              ),
                              Icon(
                                Icons.co_present_rounded,
                                size: 38,
                                color: primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: text,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Speak',
                              ),
                              TextSpan(
                                text: 'Flow',
                                style: TextStyle(
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Practice presentations.\n'
                          'Present with confidence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: subtitle,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDarkMode
                                      ? 0.22
                                      : 0.07,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight:
                                                FontWeight.w800,
                                            color: text,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Sign in to continue practicing',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: subtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller:
                                    _usernameController,
                                focusNode:
                                    _usernameFocusNode,
                                enabled: !_isLoading,
                                keyboardType:
                                    TextInputType.text,
                                textInputAction:
                                    TextInputAction.next,
                                style: TextStyle(
                                  color: text,
                                ),
                                onSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(
                                    _passwordFocusNode,
                                  );
                                },
                                decoration:
                                    _inputDecoration(
                                  label: 'Username',
                                  icon: Icons
                                      .person_outline_rounded,
                                  primary: primary,
                                  subtitle: subtitle,
                                  fill: inputFill,
                                  border: border,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller:
                                    _passwordController,
                                focusNode:
                                    _passwordFocusNode,
                                enabled: !_isLoading,
                                obscureText:
                                    _obscurePassword,
                                textInputAction:
                                    TextInputAction.done,
                                style: TextStyle(
                                  color: text,
                                ),
                                onSubmitted: (_) {
                                  _handleLogin();
                                },
                                decoration:
                                    _inputDecoration(
                                  label: 'Password',
                                  icon: Icons
                                      .lock_outline_rounded,
                                  primary: primary,
                                  subtitle: subtitle,
                                  fill: inputFill,
                                  border: border,
                                  suffix: IconButton(
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
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                      color: subtitle,
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                        primary,
                                    disabledBackgroundColor:
                                        primary.withValues(
                                      alpha: 0.55,
                                    ),
                                    foregroundColor:
                                        isDarkMode
                                            ? const Color(
                                                0xFF07111F,
                                              )
                                            : Colors.white,
                                    elevation: 0,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              isDarkMode
                                                  ? const Color(
                                                      0xFF07111F,
                                                    )
                                                  : Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Text(
                                              'Sign In',
                                              style:
                                                  TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight
                                                        .w800,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Icon(
                                              Icons
                                                  .arrow_forward_rounded,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              color: primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Improve timing, pacing, and delivery',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}