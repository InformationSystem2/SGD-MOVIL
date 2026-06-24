import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/document_models.dart';

class DocumentService extends ChangeNotifier {
  final ApiClient _apiClient;
  List<DocumentResponse> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  DocumentService(this._apiClient);

  List<DocumentResponse> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches general documents list from GET /api/documents
  Future<void> fetchDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/documents');
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      _documents = data.map((x) => DocumentResponse.fromJson(x)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads a file to the backend file server.
  /// Returns the relative URL path of the uploaded file on the server.
  Future<String> uploadFile(List<int> fileBytes, String filename) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.uploadMultipartFile(
        '/documents/upload-file',
        fileBytes: fileBytes,
        filename: filename,
      );
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      _isLoading = false;
      notifyListeners();
      return data['url'] as String;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Sends multiple files directly to the FastAPI AI microservice (OCR and Gemini analyzer)
  /// Returns the consolidated analysis structure containing raw_text, structured_data, etc.
  Future<Map<String, dynamic>> extractOcrFromMultipleFiles(List<List<int>> filesBytes, List<String> filenames) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fullUrl = '${ApiConfig.fastapiUrl}/ocr/extract-multiple';
      
      final response = await _apiClient.uploadMultipleFiles(
        fullUrl,
        filesBytes: filesBytes,
        filenames: filenames,
        fieldName: 'files',
      );
      
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Saves pre-computed OCR results to document_ocr_metadata via Spring Boot.
  Future<void> saveOcrResult(String documentId, Map<String, dynamic> ocrResult) async {
    try {
      await _apiClient.post('/documents/$documentId/ocr/result', body: ocrResult);
    } catch (e) {
      debugPrint('Error guardando OCR result: $e');
    }
  }

  /// Fetches stored OCR result from document_ocr_metadata.
  Future<Map<String, dynamic>?> getOcrResult(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId/ocr');
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('No hay OCR para el documento: $e');
      return null;
    }
  }

  /// Creates a document based on a clinical template.
  Future<DocumentResponse> createDocument(DocumentRequest dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/documents', body: dto.toJson());
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final newDoc = DocumentResponse.fromJson(data);
      _documents.insert(0, newDoc); // Add to local list at the beginning
      _isLoading = false;
      notifyListeners();
      return newDoc;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Creates an external document link for a patient.
  Future<DocumentResponse> createExternalDocument(ExternalDocumentRequest dto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/documents/external', body: dto.toJson());
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final newDoc = DocumentResponse.fromJson(data);
      _documents.insert(0, newDoc);
      _isLoading = false;
      notifyListeners();
      return newDoc;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Helper to get full file URL pointing to the active backend instance.
  String getFullFileUrl(String relativeUrl) {
    // Relative url typically starts with "/uploads/" or "uploads/"
    final cleanUrl = relativeUrl.startsWith('/') ? relativeUrl : '/$relativeUrl';
    // Remove the '/api' suffix from ApiConfig.baseUrl to get the server root URL
    final serverRoot = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverRoot$cleanUrl';
  }
}
