import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_shell.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  static const int _contentSteps = 3;

  int _step = 0;
  bool _saving = false;
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step < _contentSteps) {
      setState(() {
        _step += 1;
      });
      return;
    }
    _finish();
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step = 0;
      _pageIndex = 0;
    });
  }

  void _finish() {
    _persistAndGo();
  }

  Future<void> _persistAndGo() async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
    });
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
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
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'manage your',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'finances',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
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
                          onPressed: _goNext,
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
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Setup',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_pageIndex + 1}/$_contentSteps',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe to continue',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8F96),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              _StepIndicator(step: _pageIndex, totalSteps: _contentSteps),
              const SizedBox(height: 28),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  children: const [
                    _PocketFeatureStep(),
                    _MonthlySummaryStep(),
                    _AiInsightStep(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_pageIndex == _contentSteps - 1)
                Center(
                  child: TextButton(
                    onPressed: _saving ? null : _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1D1D1F),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Enter app',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index <= step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF141416) : Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        );
      }),
    );
  }
}

class _PocketFeatureStep extends StatelessWidget {
  const _PocketFeatureStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pocket system',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Separate balances like cards or accounts. Track each pocket clearly.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 18),
        const _PocketMockGrid(),
      ],
    );
  }
}

class _MonthlySummaryStep extends StatelessWidget {
  const _MonthlySummaryStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly summary',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Clean charts with category breakdowns every month.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 18),
        _MiniBadgeRow(
          badges: const ['Trends', 'Categories', 'Month view'],
        ),
        const SizedBox(height: 18),
        const _OnboardingChart(),
      ],
    );
  }
}

class _AiInsightStep extends StatelessWidget {
  const _AiInsightStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI feedback',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Smart insights on your history — spot overspending fast.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 22),
        _InsightExampleCard(
          title: 'Insight',
          body:
              'Dining spend jumped +18% this week. Consider setting a weekly cap.',
          footer: 'Suggestion · Category: Food',
        ),
        const SizedBox(height: 16),
        _TimelineItem(
          title: 'Spending patterns',
          subtitle: 'Find hidden habits',
        ),
        const SizedBox(height: 12),
        _TimelineItem(
          title: 'Actionable tips',
          subtitle: 'Suggestions tailored to you',
        ),
        const SizedBox(height: 12),
        _TimelineItem(
          title: 'Weekly nudges',
          subtitle: 'Stay on track',
        ),
      ],
    );
  }
}

class _CardStackMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 180,
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 12,
            child: _MiniCard(color: const Color(0xFFEFF7E8)),
          ),
          Positioned(
            top: 8,
            right: 0,
            child: _MiniCard(color: const Color(0xFFE2F0FF)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _MiniCard(color: const Color(0xFFFFF4E8)),
          ),
        ],
      ),
    );
  }
}

class _ChartMockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              _BarStub(height: 46, color: Color(0xFFBFFFE3)),
              SizedBox(width: 8),
              _BarStub(height: 30, color: Color(0xFFFFF4E8)),
              SizedBox(width: 8),
              _BarStub(height: 24, color: Color(0xFFE2F0FF)),
              SizedBox(width: 8),
              _BarStub(height: 38, color: Color(0xFFFFE7E7)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Food · Transport · Bills',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingChart extends StatelessWidget {
  const _OnboardingChart();

  @override
  Widget build(BuildContext context) {
    const values = [12, 18, 9, 22, 16, 26];
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    const highlight = 'Rp. 2.6M';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _OnboardingLineChartPainter(
            values: values,
            highlightValue: highlight,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 32, right: 8, bottom: 20),
            child: Column(
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels
                      .map(
                        (label) => Text(
                          label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingLineChartPainter extends CustomPainter {
  _OnboardingLineChartPainter({
    required this.values,
    required this.highlightValue,
  });

  final List<int> values;
  final String highlightValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF1B1C20);
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E4EA);

    final chartRect = Rect.fromLTWH(32, 8, size.width - 40, size.height - 32);
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    // Y-axis labels (mock numbers)
    final labels = ['Rp.3M', 'Rp.2M', 'Rp.1M', '0'];
    for (var i = 0; i < labels.length; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i - 6;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFF8C8F96)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y));
    }

    if (values.isEmpty) {
      return;
    }
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    final stepX =
        values.length > 1 ? chartRect.width / (values.length - 1) : 0;
    final points = List.generate(values.length, (index) {
      final value = values[index];
      final x = chartRect.left + stepX * index;
      final ratio = value / safeMax;
      final y = chartRect.bottom - (chartRect.height * ratio);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final next = points[i];
      final control = Offset((prev.dx + next.dx) / 2, prev.dy);
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }
    canvas.drawPath(path, paint);

    final focus = points.last;
    final dotPaint = Paint()..color = const Color(0xFF1B1C20);
    canvas.drawCircle(focus, 5, dotPaint);

    final labelRect = Rect.fromCenter(
      center: Offset(focus.dx, focus.dy - 26),
      width: 78,
      height: 22,
    );
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B1C20));
    final tp = TextPainter(
      text: TextSpan(
        text: highlightValue,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: labelRect.width);
    tp.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarStub extends StatelessWidget {
  const _BarStub({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _MiniBadgeRow extends StatelessWidget {
  const _MiniBadgeRow({required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges
          .map(
            (text) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE6E8ED)),
              ),
              child: Text(
                text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF1D1D1F),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PocketMockGrid extends StatelessWidget {
  const _PocketMockGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Total Balance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const Spacer(),
            Text(
              'Rp. 3.240.000',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _PocketMockCard(
                title: 'Daily',
                amount: 'Rp. 1.240.000',
                color: Color(0xFFFFF4E8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _PocketMockCard(
                title: 'Savings',
                amount: 'Rp. 2.000.000',
                color: Color(0xFFE2F0FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _PocketMockCard(
                title: 'Goals',
                amount: 'Rp. 460.000',
                color: Color(0xFFEFF7E8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: _PocketAddMock()),
          ],
        ),
      ],
    );
  }
}

class _PocketMockCard extends StatelessWidget {
  const _PocketMockCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                size: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PocketAddMock extends StatelessWidget {
  const _PocketAddMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline, size: 26),
            const SizedBox(height: 6),
            Text(
              'Add pocket',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightExampleCard extends StatelessWidget {
  const _InsightExampleCard({
    required this.title,
    required this.body,
    required this.footer,
  });

  final String title;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE6E8ED)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+18%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, size: 14, color: Color(0xFF6B6B6B)),
              const SizedBox(width: 6),
              Text(
                footer,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
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
          ),
        ),
      ],
    );
  }
}
