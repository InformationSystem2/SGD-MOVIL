import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../models/patient_models.dart';

class PatientService extends ChangeNotifier {
  final ApiClient _apiClient;
  List<PatientResponse> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  PatientService(this._apiClient);

  List<PatientResponse> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches all active patients from the API
  Future<void> fetchPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/module_users/patients');
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      _patients = data.map((x) => PatientResponse.fromJson(x)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new patient on the backend.
  Future<PatientResponse> createPatient(PatientCreateRequest dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/module_users/patients', body: dto.toJson());
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final newPatient = PatientResponse.fromJson(data);
      _patients.insert(0, newPatient); // Add to local cache
      _isLoading = false;
      notifyListeners();
      return newPatient;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing patient.
  Future<PatientResponse> updatePatient(String id, PatientUpdateRequest dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/module_users/patients/$id', body: dto.toJson());
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final updatedPatient = PatientResponse.fromJson(data);
      
      final index = _patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        _patients[index] = updatedPatient; // Replace in local cache
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedPatient;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a patient from the backend database.
  Future<void> deletePatient(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete('/module_users/patients/$id');
      _patients.removeWhere((p) => p.id == id); // Remove from local cache
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
