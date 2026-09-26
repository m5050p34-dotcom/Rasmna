class PlatformEarningModel {
  final String id;
  final String? purchaseId;
  final String? photoId;
  final String? buyerId;
  final String? sellerId;
  final double photoPrice;
  final double commissionAmount;
  final double commissionRate;
  final DateTime createdAt;

  PlatformEarningModel({
    required this.id,
    this.purchaseId,
    this.photoId,
    this.buyerId,
    this.sellerId,
    required this.photoPrice,
    required this.commissionAmount,
    required this.commissionRate,
    required this.createdAt,
  });

  factory PlatformEarningModel.fromJson(Map<String, dynamic> json) {
    return PlatformEarningModel(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String?,
      photoId: json['photo_id'] as String?,
      buyerId: json['buyer_id'] as String?,
      sellerId: json['seller_id'] as String?,
      photoPrice: (json['photo_price'] as num?)?.toDouble() ?? 0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.05,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchase_id': purchaseId,
        'photo_id': photoId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'photo_price': photoPrice,
        'commission_amount': commissionAmount,
        'commission_rate': commissionRate,
        'created_at': createdAt.toIso8601String(),
      };
}

class PlatformStats {
  final double totalCommission;
  final int totalSales;
  final double totalVolume;
  final double todayCommission;
  final double weekCommission;
  final double monthCommission;

  PlatformStats({
    required this.totalCommission,
    required this.totalSales,
    required this.totalVolume,
    required this.todayCommission,
    required this.weekCommission,
    required this.monthCommission,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      todayCommission: (json['today_commission'] as num?)?.toDouble() ?? 0,
      weekCommission: (json['week_commission'] as num?)?.toDouble() ?? 0,
      monthCommission: (json['month_commission'] as num?)?.toDouble() ?? 0,
    );
  }
}
