class CurrencyConversionModel {
  final String from;
  final String to;
  final double amount;
  final double convertedAmount;
  final double rate;
  final String date;

  CurrencyConversionModel({
    required this.from,
    required this.to,
    required this.amount,
    required this.convertedAmount,
    required this.rate,
    required this.date,
  });

  factory CurrencyConversionModel.fromJson(Map<String, dynamic> json) {
    return CurrencyConversionModel(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      convertedAmount: (json['converted_amount'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'amount': amount,
      'converted_amount': convertedAmount,
      'rate': rate,
      'date': date,
    };
  }
}
