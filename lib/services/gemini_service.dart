import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({required this.apiKey});

  final String apiKey;

  Future<String> generateMonthlyInsight({
    required String monthLabel,
    required Map<String, int> incomeByCategory,
    required Map<String, int> expenseByCategory,
    required int totalIncome,
    required int totalExpense,
    required int transactionCount,
  }) async {
    final prompt = _buildPrompt(
      monthLabel: monthLabel,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: transactionCount,
    );

    final model = GenerativeModel(
      model: 'gemini-3-pro-preview',
      apiKey: apiKey,
    );

    final response = await model.generateContent([Content.text(prompt)]);

    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty response');
    }
    return text;
  }

  String _buildPrompt({
    required String monthLabel,
    required Map<String, int> incomeByCategory,
    required Map<String, int> expenseByCategory,
    required int totalIncome,
    required int totalExpense,
    required int transactionCount,
  }) {
    return '''
You are a personal finance assistant. Provide concise monthly insights in 4-6 bullet points.
Focus on spending patterns, anomalies, and actionable tips. Keep it under 120 words.

Month: $monthLabel
Total income: $totalIncome
Total expense: $totalExpense
Transactions: $transactionCount

Income by category (amounts): ${_mapToText(incomeByCategory)}
Expense by category (amounts): ${_mapToText(expenseByCategory)}

Return only bullets, no headings.
''';
  }

  String _mapToText(Map<String, int> map) {
    if (map.isEmpty) {
      return 'none';
    }
    return map.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
}
