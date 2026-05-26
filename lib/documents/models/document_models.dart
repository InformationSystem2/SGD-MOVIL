// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'document_models.g.dart';

@JsonEnum(alwaysCreate: true)
enum DocumentStatus {
  DRAFT,
  PENDING_REVIEW,
  REJECTED,
  FINALIZED
}

class CustomDateTimeConverter implements JsonConverter<DateTime, String> {
  const CustomDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    try {
      return DateFormat('yyyy-MM-dd').parse(json);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  String toJson(DateTime object) {
    return DateFormat('yyyy-MM-dd').format(object);
  }
}

class NullableDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(json);
    } catch (_) {
      return null;
    }
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return DateFormat('yyyy-MM-dd').format(object);
  }
}

Map<String, dynamic> _fromJsonClinicalContent(Map<dynamic, dynamic>? json) {
  if (json == null) return {};
  return Map<String, dynamic>.from(json);
}


@JsonSerializable()
@CustomDateTimeConverter()
@NullableDateTimeConverter()
class DocumentResponse extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientDocumentNumber;
  final String uploaderId;
  final String uploaderName;
  final String? templateId;
  final String? templateName;
  final DocumentStatus status;
  @JsonKey(fromJson: _fromJsonClinicalContent, defaultValue: {})
  final Map<String, dynamic> clinicalContent;
  
  @CustomDateTimeConverter()
  final DateTime issueDate;
  
  @NullableDateTimeConverter()
  final DateTime? expiryDate;
  
  final String? fileUrl;
  final bool isExternalSource;

  const DocumentResponse({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientDocumentNumber,
    required this.uploaderId,
    required this.uploaderName,
    this.templateId,
    this.templateName,
    required this.status,
    required this.clinicalContent,
    required this.issueDate,
    this.expiryDate,
    this.fileUrl,
    required this.isExternalSource,
  });

  factory DocumentResponse.fromJson(Map<String, dynamic> json) => _$DocumentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentResponseToJson(this);

  @override
  List<Object?> get props => [
        id,
        patientId,
        patientName,
        patientDocumentNumber,
        uploaderId,
        uploaderName,
        templateId,
        templateName,
        status,
        clinicalContent,
        issueDate,
        expiryDate,
        fileUrl,
        isExternalSource,
      ];
}

@JsonSerializable()
@CustomDateTimeConverter()
@NullableDateTimeConverter()
class DocumentRequest extends Equatable {
  final String patientId;
  final String templateId;
  @JsonKey(fromJson: _fromJsonClinicalContent, defaultValue: {})
  final Map<String, dynamic> clinicalContent;
  
  @CustomDateTimeConverter()
  final DateTime issueDate;
  
  @NullableDateTimeConverter()
  final DateTime? expiryDate;
  
  final String? fileUrl;
  final bool isExternalSource;

  const DocumentRequest({
    required this.patientId,
    required this.templateId,
    required this.clinicalContent,
    required this.issueDate,
    this.expiryDate,
    this.fileUrl,
    this.isExternalSource = false,
  });

  factory DocumentRequest.fromJson(Map<String, dynamic> json) => _$DocumentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentRequestToJson(this);

  @override
  List<Object?> get props => [
        patientId,
        templateId,
        clinicalContent,
        issueDate,
        expiryDate,
        fileUrl,
        isExternalSource,
      ];
}

@JsonSerializable()
@CustomDateTimeConverter()
class ExternalDocumentRequest extends Equatable {
  final String patientId;
  final String fileUrl;
  
  @CustomDateTimeConverter()
  final DateTime issueDate;
  
  final String? notes;

  const ExternalDocumentRequest({
    required this.patientId,
    required this.fileUrl,
    required this.issueDate,
    this.notes,
  });

  factory ExternalDocumentRequest.fromJson(Map<String, dynamic> json) => _$ExternalDocumentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ExternalDocumentRequestToJson(this);

  @override
  List<Object?> get props => [patientId, fileUrl, issueDate, notes];
}
