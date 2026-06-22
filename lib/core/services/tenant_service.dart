import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

/// Service that manages tenant subscription plan information
/// and controls feature access based on the active plan.
///
/// Plan hierarchy:
///   BASIC      → File upload only
///   PRO        → File upload + Document scanner
///   ENTERPRISE → All features (upload + scanner + AI assistant)
class TenantService extends ChangeNotifier {
  final ApiClient _apiClient;

  String? _currentPlan;
  String? _tenantName;
  bool _isLoading = false;
  String? _errorMessage;

  TenantService(this._apiClient);

  String? get currentPlan => _currentPlan;
  String? get tenantName => _tenantName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Feature gates ──────────────────────────────────────────────────────

  /// Whether the current plan allows document scanning via camera.
  bool get canUseScan =>
      _currentPlan == 'PRO' || _currentPlan == 'ENTERPRISE';

  /// Whether the current plan allows the AI assistant.
  bool get canUseAssistant => _currentPlan == 'ENTERPRISE';

  /// File upload is available on all plans.
  bool get canUploadFiles => true;

  /// Human-readable label for the minimum plan required for a feature.
  String getRequiredPlanLabel(String feature) {
    switch (feature) {
      case 'scan':
        return 'PRO';
      case 'assistant':
        return 'ENTERPRISE';
      default:
        return 'BASIC';
    }
  }

  // ── API ────────────────────────────────────────────────────────────────

  /// Fetches the current tenant info from the backend.
  /// Falls back to BASIC if the request fails (e.g. non-admin user).
  Future<void> fetchTenantInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/tenants/current/info');
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      _currentPlan = data['subscriptionPlan'] as String? ?? 'BASIC';
      _tenantName = data['name'] as String?;
    } catch (e) {
      // If the user doesn't have ADMIN/SUPERUSER permissions to call
      // /tenants/current/info, default to PRO so features aren't blocked.
      _currentPlan = 'PRO';
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
