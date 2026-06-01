import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_banner.dart';
import '../widgets/member_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  bool _isSaving = false;
  String? _selectedAvatar;

  final List<String> _availableAvatars = List.generate(
    12,
    (index) => 'lib/assets/avatars/${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _usernameController = TextEditingController(
      text: user?.username.replaceAll('@', '') ?? '',
    );
    _selectedAvatar = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      _nameController.text.trim(),
      _usernameController.text.trim(),
      imagePath: _selectedAvatar,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      TopBanner.show(
        context,
        'Profile updated successfully!',
        backgroundColor: AppColors.success,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppDynColors.of(context);
    final user = context.read<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: MemberAvatar.getConsistentAvatarColor(user.id),
                        shape: BoxShape.circle,
                        image: _selectedAvatar != null
                            ? DecorationImage(
                                image: _selectedAvatar!.startsWith('http')
                                    ? NetworkImage(_selectedAvatar!)
                                          as ImageProvider
                                    : _selectedAvatar!.startsWith('lib/assets/')
                                    ? AssetImage(_selectedAvatar!)
                                          as ImageProvider
                                    : FileImage(File(_selectedAvatar!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedAvatar == null
                          ? Center(
                              child: Text(
                                user.initials,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Choose Avatar',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _availableAvatars.length +
                          1, // +1 for "Initials" option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Use Initials" option
                          final isSelected = _selectedAvatar == null;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: MemberAvatar.getConsistentAvatarColor(
                                  user.id,
                                ),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.success,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  user.initials,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final avatarPath = _availableAvatars[index - 1];
                        final isSelected = _selectedAvatar == avatarPath;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatar = avatarPath),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.success,
                                      width: 3,
                                    )
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
                  const SizedBox(height: 40),
                  Text(
                    'Full Name',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'John Doe',
                      hintStyle: GoogleFonts.inter(
                        color: theme.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: theme.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Username',
                    style: GoogleFonts.inter(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'username',
                      hintStyle: GoogleFonts.inter(
                        color: theme.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      filled: true,
                      fillColor: theme.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.contains(' ')) {
                        return 'Username cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
