import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AppDatabase.instance.fetchProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.text = profile?.name ?? '';
      _goalController.text = profile?.goal ?? '';
      _apiKeyController.text = profile?.geminiApiKey ?? '';
      _photoPath = profile?.photoPath;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
    });
    final profile = ProfileEntry(
      name: _nameController.text.trim(),
      goal: _goalController.text.trim(),
      photoPath: _photoPath,
      geminiApiKey: _apiKeyController.text.trim().isEmpty
          ? null
          : _apiKeyController.text.trim(),
    );
    await AppDatabase.instance.saveProfile(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputCard(
                      label: 'Name',
                      hint: 'Your display name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _InputCard(
                      label: 'Main goal',
                      hint: 'Example: vacation savings, emergency fund',
                      controller: _goalController,
                    ),
                    const SizedBox(height: 16),
                    _InputCard(
                      label: 'Gemini API key',
                      hint: 'Paste your Gemini API key',
                      controller: _apiKeyController,
                      obscure: true,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141416),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF1D1D1F),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B6B6B),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE6E8ED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1D1D1F)),
            ),
          ),
        ),
      ],
    );
  }
}
