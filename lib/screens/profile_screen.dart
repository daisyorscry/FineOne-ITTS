import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import 'profile_edit_screen.dart';
import 'setup_wizard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _name = '';
  String _goal = '';
  String? _photoPath;
  String? _geminiApiKey;
  late final AnimationController _bounceController;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AppDatabase.instance.fetchProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _name = profile?.name ?? '';
      _goal = profile?.goal ?? '';
      _photoPath = profile?.photoPath;
      _geminiApiKey = profile?.geminiApiKey;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
    if (updated == true) {
      _loadProfile();
    }
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) {
      return;
    }
    final profile = ProfileEntry(
      name: _name,
      goal: _goal,
      photoPath: file.path,
    );
    await AppDatabase.instance.saveProfile(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _photoPath = file.path;
    });
  }

  Future<void> _logoutAndReset() async {
    await AppDatabase.instance.clearAllData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOpened', false);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupWizard()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
        actions: const [],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_geminiApiKey == null ||
                              _geminiApiKey!.trim().isEmpty) ...[
                            AnimatedBuilder(
                              animation: _bounce,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _bounce.value,
                                  child: child,
                                );
                              },
                              child: _ApiKeyBanner(onTap: _openEdit),
                            ),
                            const SizedBox(height: 18),
                          ],
                          InkWell(
                            onTap: _openCamera,
                            borderRadius: BorderRadius.circular(80),
                            child: _ProfileAvatar(
                              photoPath: _photoPath,
                              size: 120,
                              iconSize: 56,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _name.trim().isEmpty ? 'Your name' : _name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D1D1F),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: _openEdit,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F8),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE6E8ED),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _GoalBadge(
                            text: _goal.trim().isEmpty ? 'Main goal' : _goal,
                            fontSize: 13,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: TextButton.icon(
                        onPressed: _logoutAndReset,
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          'Log out',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.photoPath,
    this.size = 96,
    this.iconSize = 48,
  });

  final String? photoPath;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE6E8ED)),
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(photoPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto
          ? null
          : Icon(
              Icons.person_rounded,
              size: iconSize,
              color: const Color(0xFF1D1D1F),
            ),
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({
    required this.text,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D1D1F),
        ),
      ),
    );
  }
}

class _ApiKeyBanner extends StatelessWidget {
  const _ApiKeyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD7A8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'Add your Gemini API key',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Edit profile',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1F),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
