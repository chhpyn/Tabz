import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
 
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../app_shell.dart';
import '../../core/widgets/top_banner.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedAvatar;
  late AnimationController _animCtrl;
  bool _isGoogleSignUp = false;
  
  final List<String> _availableAvatars = List.generate(
    12, 
    (index) => 'lib/assets/avatars/${index + 1}.png'
  );

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animCtrl.forward();

    // Check if we're coming from Google sign-in
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.hasGooglePendingSignUp) {
        setState(() {
          _isGoogleSignUp = true;
          _nameController.text = auth.tempGoogleName ?? '';
          _emailController.text = auth.tempGoogleEmail ?? '';
          // Pre-fill username from email
          if (auth.tempGoogleEmail != null) {
            _usernameController.text = auth.tempGoogleEmail!
                .split('@')[0]
                .toLowerCase();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      late final bool success;

      if (_isGoogleSignUp) {
        // Sign up with Google credentials
        success = await authProvider.signUpWithGoogle(
          _nameController.text.trim(),
          _usernameController.text.trim(),
          _selectedAvatar,
        );
      } else {
        // Regular email/password sign up
        success = await authProvider.signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
          _selectedAvatar,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        } else {
          TopBanner.show(
            context,
            authProvider.errorMessage ?? 'Sign Up failed',
            backgroundColor: AppColors.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = AppDynColors.of(context);

    return Scaffold(
      body: Container(
        color: theme.background,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Back Button & Heading
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.background,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_isGoogleSignUp) {
                        context.read<AuthProvider>().clearGoogleSignUpData();
                      }
                      Navigator.pop(context);
                    },
                  ),
                  centerTitle: false,
                  elevation: 0,
                ),
                // Form Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.cardBorder),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Avatar Upload ──
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.inter(
                                      color: theme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Join and start splitting your expenses with friends!',
                                    style: GoogleFonts.inter(
                                      color: theme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 60,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _availableAvatars.length,
                                      itemBuilder: (context, index) {
                                        final avatarPath = _availableAvatars[index];
                                        final isSelected = _selectedAvatar == avatarPath;
                                        return GestureDetector(
                                          onTap: () => setState(() => _selectedAvatar = avatarPath),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: isSelected
                                                  ? Border.all(color: AppColors.primary, width: 3)
                                                  : null,
                                              image: DecorationImage(
                                                image: AssetImage(avatarPath),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_selectedAvatar != null)
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedAvatar = null),
                                      child: Text(
                                        'Remove Avatar',
                                        style: GoogleFonts.inter(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: theme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  v != null && v.trim().length >= 2
                                  ? null
                                  : 'Enter your full name',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: theme.textPrimary),
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'e.g. user_name',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '@',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter a username';
                                }
                                final clean = v.trim().replaceAll('@', '');
                                if (clean.length < 3) {
                                  return 'At least 3 characters';
                                }
                                if (!RegExp(
                                  r'^[a-zA-Z0-9_]+$',
                                ).hasMatch(clean)) {
                                  return 'Only letters, numbers, and underscores';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isGoogleSignUp,
                              style: TextStyle(color: theme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) => v != null && v.contains('@')
                                  ? null
                                  : 'Enter a valid email',
                            ),
                            const SizedBox(height: 14),
                            if (!_isGoogleSignUp)
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) => v != null && v.length >= 6
                                    ? null
                                    : 'Min 6 characters',
                              ),
                            if (!_isGoogleSignUp) const SizedBox(height: 24),
                            if (_isGoogleSignUp)
                              Center(
                                child: Text(
                                  'Signing up with Google',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            if (_isGoogleSignUp) const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            // ── Google Sign Up ──
                            if (!auth.hasGooglePendingSignUp)
                              Column(
                                children: [
                                  const SizedBox(height: 20),
                                  // Divider with text
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: theme.cardBorder,
                                          thickness: 2,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'or',
                                          style: GoogleFonts.inter(
                                            color: theme.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: theme.cardBorder,
                                          thickness: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Google Sign Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () async {
                                              final success = await context
                                                  .read<AuthProvider>()
                                                  .signInWithGoogle();

                                              if (mounted && success) {
                                                Navigator.of(
                                                  context,
                                                ).pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const AppShell(),
                                                  ),
                                                  (route) => false,
                                                );
                                              } else if (mounted &&
                                                  auth.hasGooglePendingSignUp) {
                                                // Refresh the screen to show Google data
                                                setState(() {});
                                              } else if (mounted && !success) {
                                                TopBanner.show(
                                                  context,
                                                  auth.errorMessage ??
                                                      'Google Sign Up failed',
                                                  backgroundColor: AppColors.error,
                                                );
                                              }
                                            },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: theme.cardBorder,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign Up with  ',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textPrimary,
                                            ),
                                          ),
                                          // Google wordmark in brand colors
                                          RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text: 'G',
                                                  style: TextStyle(
                                                    color: Color(0xFF4285F4),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'o',
                                                  style: TextStyle(
                                                    color: Color(0xFFEA4335),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'o',
                                                  style: TextStyle(
                                                    color: Color(0xFFFABB05),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'g',
                                                  style: TextStyle(
                                                    color: Color(0xFF4285F4),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'l',
                                                  style: TextStyle(
                                                    color: Color(0xFF34A853),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'e',
                                                  style: TextStyle(
                                                    color: Color(0xFFEA4335),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Sign In Link
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: theme.textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
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
