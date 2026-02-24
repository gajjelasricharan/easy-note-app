// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 20),
              if (_error != null) _buildError(),
              const SizedBox(height: 12),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildGoogleButton(),
              const SizedBox(height: 32),
              _buildToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'easy note',
          style: GoogleFonts.fraunces(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
            letterSpacing: -1.5,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Welcome back' : 'Create your account',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            color: AppTheme.mediumGray,
          ),
        ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        if (!_isLogin) ...[
          _buildTextField(
            controller: _nameCtrl,
            label: 'Full name',
            icon: Icons.person_outline_rounded,
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 14),
        ],
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _passwordCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          suffix: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AppTheme.warmGray,
            ),
          ),
        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: AppTheme.warmGray, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.warmGray),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.warmWhite,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.ink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isLogin ? 'Sign in' : 'Create account',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.softTan)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.warmGray),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.softTan)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: AppTheme.softTan, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata_rounded, size: 28),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isLogin = !_isLogin;
          _error = null;
        }),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mediumGray),
            children: [
              TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
              TextSpan(
                text: _isLogin ? 'Sign up' : 'Sign in',
                style: const TextStyle(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          setState(() {
            _error = 'Please enter your name';
            _isLoading = false;
          });
          return;
        }
        await authService.signUpWithEmail(email, password, name);
      }
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('wrong-password') || error.contains('user-not-found')) {
      return 'Invalid email or password';
    }
    if (error.contains('email-already-in-use')) {
      return 'Email already registered';
    }
    if (error.contains('weak-password')) {
      return 'Password must be at least 6 characters';
    }
    if (error.contains('network-request-failed')) {
      return 'No internet connection';
    }
    return 'Something went wrong. Please try again.';
  }
}
