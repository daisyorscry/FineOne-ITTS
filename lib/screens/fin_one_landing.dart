import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'setup_wizard.dart';

class FinOneLanding extends StatelessWidget {
  const FinOneLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/welcome_screen.png',
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Easy ways to',
                          style: GoogleFonts.bakbakOne(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1D1D1F),
                            letterSpacing: 0.96,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'manage your',
                          style: GoogleFonts.bakbakOne(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1D1D1F),
                            letterSpacing: 0.96,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'finances',
                          style: GoogleFonts.bakbakOne(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1D1D1F),
                            letterSpacing: 0.96,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 32,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SetupWizard(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141416),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
