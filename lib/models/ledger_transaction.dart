import '../core/formatters.dart';

enum TransactionType { income, expense }

enum ExpenseCategory { food, transport, shopping, housing, other, income }

enum TransactionSource { manual, receipt }

class LedgerTransaction {
  const LedgerTransaction({
    this.id,
    required this.type,
    required this.amountCents,
    required this.category,
    required this.date,
    this.note,
    this.source = TransactionSource.manual,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final TransactionType type;
  final int amountCents;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final TransactionSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get signedCents =>
      type == TransactionType.income ? amountCents : -amountCents;

  LedgerTransaction copyWith({
    int? id,
    TransactionType? type,
    int? amountCents,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    TransactionSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LedgerTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    return <String, Object?>{
      if (includeId && id != null) 'id': id,
      'type': type.name,
      'amount_cents': amountCents,
      'category': category.name,
      'transaction_date': DateTools.databaseDate(date),
      'note': note,
      'source': source.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LedgerTransaction.fromMap(Map<String, Object?> map) {
    return LedgerTransaction(
      id: map['id']! as int,
      type: TransactionType.values.byName(map['type']! as String),
      amountCents: map['amount_cents']! as int,
      category: ExpenseCategory.values.byName(map['category']! as String),
      date: DateTools.parseDatabaseDate(map['transaction_date']! as String),
      note: map['note'] as String?,
      source: TransactionSource.values.byName(map['source']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }
}
