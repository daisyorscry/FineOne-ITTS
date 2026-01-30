import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';

class InsightHistoryScreen extends StatefulWidget {
  const InsightHistoryScreen({super.key});

  @override
  State<InsightHistoryScreen> createState() => _InsightHistoryScreenState();
}

class _InsightHistoryScreenState extends State<InsightHistoryScreen> {
  bool _loading = true;
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final rows = await AppDatabase.instance.fetchInsightHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(
          'Insight History',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1C20),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Text(
                      'No insight history yet.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF8C8F96),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final content = (item['content'] as String?) ?? '';
                      final createdAt = DateTime.tryParse(
                        (item['created_at'] as String?) ?? '',
                      );
                      final periodStart = DateTime.tryParse(
                        (item['period_start'] as String?) ?? '',
                      );
                      final periodEnd = DateTime.tryParse(
                        (item['period_end'] as String?) ?? '',
                      );
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6E8ED)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                height: 1.5,
                                color: const Color(0xFF1B1C20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (periodStart != null && periodEnd != null)
                              Text(
                                'Data range: ${_formatDate(periodStart)} - ${_formatDate(periodEnd)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B6B6B),
                                ),
                              ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Generated: ${_formatDate(createdAt)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B6B6B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
