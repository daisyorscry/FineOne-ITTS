import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _segment = 'income';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedControl(
                value: _segment,
                onChanged: (value) => setState(() => _segment = value),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Save This Month',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _segment == 'income' ? 'Rp.1.852.000' : 'Rp.1.145.000',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1C20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Increase of 12% from last month',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8F96),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _SummaryChart(),
              const SizedBox(height: 18),
              Text(
                'Categories',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1C20),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isFirst = index == 0;
                    return _CategoryCard(
                      title: isFirst ? 'Salary' : 'Education',
                      date: isFirst ? 'Dec 8, 2022' : 'June 8, 2022',
                      amount: isFirst ? '+Rp.18,5 M' : '-Rp.165.000',
                      color: isFirst
                          ? const Color(0xFFBFFFE3)
                          : const Color(0xFFD7B6FF),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Income',
              selected: value == 'income',
              onTap: () => onChanged('income'),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Expenses',
              selected: value == 'expenses',
              onTap: () => onChanged('expenses'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B1C20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF1B1C20),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChart extends StatelessWidget {
  const _SummaryChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 170,
        child: CustomPaint(
          painter: _LineChartPainter(),
          child: Padding(
            padding: const EdgeInsets.only(left: 28, right: 8, bottom: 20),
            child: Column(
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('April'),
                    Text('May'),
                    Text('June'),
                    Text('July'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
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

    final chartRect = Rect.fromLTWH(28, 8, size.width - 36, size.height - 32);
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final points = [
      Offset(chartRect.left, chartRect.bottom - chartRect.height * 0.1),
      Offset(chartRect.left + chartRect.width * 0.25,
          chartRect.bottom - chartRect.height * 0.25),
      Offset(chartRect.left + chartRect.width * 0.5,
          chartRect.bottom - chartRect.height * 0.55),
      Offset(chartRect.left + chartRect.width * 0.75,
          chartRect.bottom - chartRect.height * 0.45),
      Offset(chartRect.right, chartRect.bottom - chartRect.height * 0.65),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final next = points[i];
      final control = Offset((prev.dx + next.dx) / 2, prev.dy);
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }

    canvas.drawPath(path, paint);

    final focus = points[2];
    final dotPaint = Paint()..color = const Color(0xFF1B1C20);
    canvas.drawCircle(focus, 5, dotPaint);

    final labelRect = Rect.fromCenter(
      center: Offset(focus.dx, focus.dy - 26),
      width: 64,
      height: 24,
    );
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1B1C20));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Rp20,000',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: labelRect.width);
    tp.paint(
      canvas,
      Offset(labelRect.left + 6, labelRect.top + 6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.date,
    required this.amount,
    required this.color,
  });

  final String title;
  final String date;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: Color(0xFF1B1C20),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B1C20),
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C20),
            ),
          ),
        ],
      ),
    );
  }
}
