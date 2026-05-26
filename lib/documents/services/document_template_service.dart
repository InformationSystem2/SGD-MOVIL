import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../models/document_template_models.dart';

class DocumentTemplateService extends ChangeNotifier {
  final ApiClient _apiClient;
  List<DocumentTemplateResponse> _templates = [];
  bool _isLoading = false;
  String? _errorMessage;

  DocumentTemplateService(this._apiClient);

  List<DocumentTemplateResponse> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches active templates from the backend API
  Future<void> fetchTemplates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/documents/templates');
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      _templates = data.map((x) => DocumentTemplateResponse.fromJson(x)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get template by ID
  DocumentTemplateResponse? getById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
