import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../styles/color_style.dart';
import '../../styles/button_style.dart';
import '../../styles/input_style.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Cache screen size calculations
  bool _isSmallScreen = false;
  bool _isInitialized = false;

  // Focus nodes for manual control
  final FocusNode _namaFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController!.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache screen size calculations once
    if (!_isInitialized) {
      final screenHeight = MediaQuery.of(context).size.height;
      _isSmallScreen = screenHeight < 700;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController?.dispose();

    // Dispose focus nodes
    _namaFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final result = await authProvider.register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Pendaftaran berhasil!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Pendaftaran gagal')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - FIXED
            _fadeAnimation != null
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: _buildHeader(),
                  )
                : _buildHeader(),

            // Form Section - EXPANDED
            Expanded(
              child: _slideAnimation != null && _fadeAnimation != null
                  ? SlideTransition(
                      position: _slideAnimation!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _buildFormContainer(),
                      ),
                    )
                  : _buildFormContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 16 : 24,
        vertical: _isSmallScreen ? 12 : 16,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: _isSmallScreen ? 50 : 60,
            height: _isSmallScreen ? 50 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/img/app_icon_1024x1024.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daftarkan Toko',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buat akun baru sekarang',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: _isSmallScreen ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: _isSmallScreen ? 24 : 32,
          right: _isSmallScreen ? 24 : 32,
          top: _isSmallScreen ? 24 : 32,
          bottom: _isSmallScreen
              ? 20
              : 32 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Fixed Header Section
              Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: _isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkgreen,
                ),
              ),
              SizedBox(height: _isSmallScreen ? 2 : 4),
              Text(
                'Lengkapi form di bawah untuk mendaftar',
                style: TextStyle(
                  fontSize: _isSmallScreen ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: _isSmallScreen ? 16 : 20),

              // Scrollable Form Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Field
                      TextFormField(
                        controller: _namaController,
                        focusNode: _namaFocusNode,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        style: AppInputStyle.inputStyle(),
                        cursorColor: AppColors.darkgreen,
                        decoration: AppInputStyle.modern(
                          label: 'Nama Toko',
                          icon: Icons.store_outlined,
                        ),
                        validator: _validateNama,
                        onTap: () {},
                      ),
                      SizedBox(height: _isSmallScreen ? 10 : 12),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        style: AppInputStyle.inputStyle(),
                        cursorColor: AppColors.darkgreen,
                        decoration: AppInputStyle.modern(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: _validateEmail,
                        onTap: () {
                          // Prevent auto-scroll when tapped
                        },
                      ),
                      SizedBox(height: _isSmallScreen ? 10 : 12),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        style: AppInputStyle.inputStyle(),
                        cursorColor: AppColors.darkgreen,
                        decoration: AppInputStyle.modern(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: _togglePasswordVisibility,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                        onTap: () {
                          // Prevent auto-scroll when tapped
                        },
                      ),
                      SizedBox(height: _isSmallScreen ? 10 : 12),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: _obscureConfirmPassword,
                        style: AppInputStyle.inputStyle(),
                        cursorColor: AppColors.darkgreen,
                        decoration: AppInputStyle.modern(
                          label: 'Konfirmasi Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: _toggleConfirmPasswordVisibility,
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                        onTap: () {
                          // Prevent auto-scroll when tapped
                        },
                      ),
                      SizedBox(height: _isSmallScreen ? 20 : 24),

                      // Register Button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: _isSmallScreen ? 45 : 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : _handleRegister,
                              style: AppButtonStyle.primary.copyWith(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontSize: _isSmallScreen ? 15 : 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: _isSmallScreen ? 10 : 12),

                      // Login Text
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Masuk Sekarang',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized validation methods
  String? _validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama toko tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama toko minimal 3 karakter';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email tidak valid';
    }
    if (value.length < 10) {
      return 'Email minimal 10 karakter';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _passwordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }
}
