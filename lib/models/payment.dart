import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Payment method enum (cash only for now)
enum PaymentMethod {
  cash,
  gcash,
}

/// Payment model
@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'payment_method') @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
    @JsonKey(name: 'amount_tendered') required double amountTendered,
    @JsonKey(name: 'change_amount') required double changeAmount,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(false) @JsonKey(includeToJson: false) bool isSynced,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}
