import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../app_shell.dart';
import 'sign_up_screen.dart';
import '../../core/widgets/top_banner.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const String _logoAssetPath = 'lib/assets/icon/tabz.png';
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        } else {
          TopBanner.show(
            context,
            authProvider.errorMessage ?? 'Sign In failed',
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
        width: double.infinity,
        height: double.infinity,
        color: theme.background,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  // Logo
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wordmark
                        Image.asset(
                          _logoAssetPath,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form Card
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
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
                              Text(
                                'Welcome back!',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please sign in to your account.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                              // Password
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
                                onFieldSubmitted: (_) => _signIn(),
                              ),
                              const SizedBox(height: 24),
                              // Sign In button
                              SizedBox(
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
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
                                            'Sign In',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
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
                              // Google Sign In Button
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () async {
                                          final success = await context
                                              .read<AuthProvider>()
                                              .signInWithGoogle();

                                          if (mounted) {
                                            if (success) {
                                              Navigator.of(
                                                context,
                                              ).pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AppShell(),
                                                ),
                                                (route) => false,
                                              );
                                            } else if (auth
                                                .hasGooglePendingSignUp) {
                                              // Show dialog for new users
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) => AlertDialog(
                                                  backgroundColor: theme.card,
                                                  title: Text(
                                                    'Account Not Found',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.textPrimary,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'You don\'t have an account yet. Please sign up first!',
                                                    style: GoogleFonts.inter(
                                                      color:
                                                          theme.textSecondary,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        context
                                                            .read<
                                                              AuthProvider
                                                            >()
                                                            .clearGoogleSignUpData();
                                                      },
                                                      child: Text(
                                                        'Cancel',
                                                        style: GoogleFonts.inter(
                                                          color: theme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const SignUpScreen(),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Sign Up',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              TopBanner.show(
                                                context,
                                                auth.errorMessage ??
                                                    'Google sign-in failed',
                                                    backgroundColor: AppColors.error,
                                              );
                                            }
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.cardBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign In with  ',
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
                                              style: TextStyle(color: Color(0xFF4285F4)),
                                            ),
                                            TextSpan(
                                              text: 'o',
                                              style: TextStyle(color: Color(0xFFEA4335)),
                                            ),
                                            TextSpan(
                                              text: 'o',
                                              style: TextStyle(color: Color(0xFFFABB05)),
                                            ),
                                            TextSpan(
                                              text: 'g',
                                              style: TextStyle(color: Color(0xFF4285F4)),
                                            ),
                                            TextSpan(
                                              text: 'l',
                                              style: TextStyle(color: Color(0xFF34A853)),
                                            ),
                                            TextSpan(
                                              text: 'e',
                                              style: TextStyle(color: Color(0xFFEA4335)),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: theme.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign Up',
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
        ),
      ),
    );
  }
}
