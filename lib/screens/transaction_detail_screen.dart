import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.entry});

  final TransactionEntry entry;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final GlobalKey _shareKey = GlobalKey();

  TransactionEntry get entry => widget.entry;

  String _formatRupiah(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString().split('');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${isNegative ? '-' : ''}Rp.${buffer.toString()}';
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
    final month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  Future<void> _shareImage() async {
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return;
    }
    final bytes = byteData.buffer.asUint8List();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/finone-receipt.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == 'income';
    final badgeColor = isIncome
        ? const Color(0xFFD9FCEB)
        : const Color(0xFFFFE7E7);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _shareKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B1C20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B1C20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.method ?? 'Metode tidak diisi',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8C8F96),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${isIncome ? '+' : '-'}${_formatRupiah(entry.amount)}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B1C20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Tanggal',
                              value: _formatDate(entry.date),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Metode',
                              value: entry.method ?? '-',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Catatan',
                              value: entry.notes?.isNotEmpty == true
                                  ? entry.notes!
                                  : '-',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Kategori',
                              value: entry.category,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _shareImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text('Share Receipt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8C8F96)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1C20),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8C8F96)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1C20),
          ),
        ),
      ],
    );
  }
}
