import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/points_service.dart';
import '../utils/constants.dart';

class PointsProvider extends ChangeNotifier {
  final _pointsService = PointsService();

  List<TransactionModel> _userTransactions = [];
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;

  List<TransactionModel> get userTransactions => _userTransactions;
  List<TransactionModel> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;

  Future<void> fetchUserTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userTransactions = await _pointsService.getUserTransactions(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllTransactions({
    String? filterType,
    String? filterUserId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _allTransactions = await _pointsService.getAllTransactions(
        filterType: filterType,
        filterUserId: filterUserId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addPoints({
    required String userId,
    required int amount,
    required String type,
    String? reason,
  }) async {
    return await _pointsService.addPoints(
      userId: userId,
      amount: amount,
      type: type,
      reason: reason,
    );
  }

  Future<int> setUserPoints({
    required String userId,
    required int newValue,
    String? reason,
  }) async {
    return await _pointsService.setUserPoints(
      userId: userId,
      newValue: newValue,
      reason: reason,
    );
  }

  Future<int> adminGrant({
    required String userId,
    required int amount,
    String? reason,
  }) async {
    return await addPoints(
      userId: userId,
      amount: amount,
      type: AppConstants.txAdminGrant,
      reason: reason ?? 'مكافأة إدارية',
    );
  }

  Future<int> adminDeduct({
    required String userId,
    required int amount,
    String? reason,
  }) async {
    return await addPoints(
      userId: userId,
      amount: -amount.abs(),
      type: AppConstants.txAdminDeduct,
      reason: reason ?? 'خصم إداري',
    );
  }

  // ═══════════════════════════════════════════════
  // 🎁 تحويل النقاط (هدية)
  // ═══════════════════════════════════════════════
  Future<TransferResult> transferPoints({
    required String recipientId,
    required int amount,
    String? message,
  }) async {
    final result = await _pointsService.transferPoints(
      recipientId: recipientId,
      amount: amount,
      message: message,
    );
    return result;
  }
}
