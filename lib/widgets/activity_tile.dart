import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_database.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.item,
    required this.amountText,
    required this.dateText,
    this.onTap,
  });

  final TransactionEntry item;
  final String amountText;
  final String dateText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final background = isIncome ? const Color(0xFFD9FCEB) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: Color(0xFF1B1C20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1C20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C8F96),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}$amountText',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B1C20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8F96),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
