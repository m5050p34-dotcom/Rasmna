class ProfileModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final int points;
  final int loginStreak;
  final DateTime? lastLoginDate;
  final bool isAdmin;
  final bool isBanned;
  final DateTime createdAt;

  // ═══════════════════════════════════════════════
  // ✅ جديد: حقول الآيقونة النشطة (متجر الآيقونات)
  // ═══════════════════════════════════════════════
  final String? activeIconId;
  final String? activeIconUrl;
  final DateTime? activeIconExpiresAt;

  ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.points,
    required this.loginStreak,
    this.lastLoginDate,
    required this.isAdmin,
    required this.isBanned,
    required this.createdAt,
    this.activeIconId,
    this.activeIconUrl,
    this.activeIconExpiresAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: (json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      points: (json['points'] ?? 0) as int,
      loginStreak: (json['login_streak'] ?? 0) as int,
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.parse(json['last_login_date'] as String)
          : null,
      isAdmin: (json['is_admin'] ?? false) as bool,
      isBanned: (json['is_banned'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      activeIconId: json['active_icon_id'] as String?,
      activeIconUrl: json['active_icon_url'] as String?,
      activeIconExpiresAt: json['active_icon_expires_at'] != null
          ? DateTime.tryParse(json['active_icon_expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
        'points': points,
        'login_streak': loginStreak,
        'last_login_date': lastLoginDate?.toIso8601String(),
        'is_admin': isAdmin,
        'is_banned': isBanned,
        'created_at': createdAt.toIso8601String(),
        'active_icon_id': activeIconId,
        'active_icon_url': activeIconUrl,
        'active_icon_expires_at': activeIconExpiresAt?.toIso8601String(),
      };

  ProfileModel copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    int? points,
    int? loginStreak,
    DateTime? lastLoginDate,
    bool? isAdmin,
    bool? isBanned,
    String? activeIconId,
    String? activeIconUrl,
    DateTime? activeIconExpiresAt,
    bool clearActiveIcon = false,
  }) {
    return ProfileModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      points: points ?? this.points,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
      // ✅ clearActiveIcon يسمح بإزالة الآيقونة صراحةً
      activeIconId: clearActiveIcon ? null : (activeIconId ?? this.activeIconId),
      activeIconUrl:
          clearActiveIcon ? null : (activeIconUrl ?? this.activeIconUrl),
      activeIconExpiresAt: clearActiveIcon
          ? null
          : (activeIconExpiresAt ?? this.activeIconExpiresAt),
    );
  }

  String get initial => username.isNotEmpty ? username[0].toUpperCase() : '?';

  bool get canClaimDailyReward {
    if (lastLoginDate == null) return true;
    final now = DateTime.now();
    final last = lastLoginDate!;
    return !(now.year == last.year &&
        now.month == last.month &&
        now.day == last.day);
  }

  int get nextRewardDay {
    if (loginStreak >= 7) return 1;
    return loginStreak + 1;
  }

  /// 🎁 نقاط المكافأة حسب اليوم الجديد (10 × يوم)
  int get nextRewardPoints => nextRewardDay * 10;

  // ═══════════════════════════════════════════════
  // ✅ جديد: getters الآيقونة النشطة
  // ═══════════════════════════════════════════════

  /// هل لدى المستخدم آيقونة فعّالة (غير منتهية)؟
  bool get hasActiveIcon {
    if (activeIconUrl == null || activeIconUrl!.isEmpty) return false;
    if (activeIconExpiresAt == null) return false;
    return activeIconExpiresAt!.isAfter(DateTime.now());
  }

  /// عدد الأيام المتبقية قبل انتهاء صلاحية الآيقونة (0 إذا منتهية)
  int get activeIconDaysRemaining {
    if (activeIconExpiresAt == null) return 0;
    final diff = activeIconExpiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// هل الآيقونة على وشك الانتهاء (أقل من 3 أيام)؟
  bool get isActiveIconExpiringSoon {
    if (!hasActiveIcon) return false;
    return activeIconDaysRemaining <= 3;
  }
}
