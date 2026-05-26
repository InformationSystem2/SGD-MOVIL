// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentResponse _$DocumentResponseFromJson(Map<String, dynamic> json) =>
    DocumentResponse(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      patientDocumentNumber: json['patientDocumentNumber'] as String?,
      uploaderId: json['uploaderId'] as String,
      uploaderName: json['uploaderName'] as String,
      templateId: json['templateId'] as String?,
      templateName: json['templateName'] as String?,
      status: $enumDecode(_$DocumentStatusEnumMap, json['status']),
      clinicalContent: json['clinicalContent'] == null
          ? {}
          : _fromJsonClinicalContent(json['clinicalContent'] as Map?),
      issueDate: const CustomDateTimeConverter().fromJson(
        json['issueDate'] as String,
      ),
      expiryDate: const NullableDateTimeConverter().fromJson(
        json['expiryDate'] as String?,
      ),
      fileUrl: json['fileUrl'] as String?,
      isExternalSource: json['isExternalSource'] as bool,
    );

Map<String, dynamic> _$DocumentResponseToJson(
  DocumentResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'patientId': instance.patientId,
  'patientName': instance.patientName,
  'patientDocumentNumber': instance.patientDocumentNumber,
  'uploaderId': instance.uploaderId,
  'uploaderName': instance.uploaderName,
  'templateId': instance.templateId,
  'templateName': instance.templateName,
  'status': _$DocumentStatusEnumMap[instance.status]!,
  'clinicalContent': instance.clinicalContent,
  'issueDate': const CustomDateTimeConverter().toJson(instance.issueDate),
  'expiryDate': const NullableDateTimeConverter().toJson(instance.expiryDate),
  'fileUrl': instance.fileUrl,
  'isExternalSource': instance.isExternalSource,
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.DRAFT: 'DRAFT',
  DocumentStatus.PENDING_REVIEW: 'PENDING_REVIEW',
  DocumentStatus.REJECTED: 'REJECTED',
  DocumentStatus.FINALIZED: 'FINALIZED',
};

DocumentRequest _$DocumentRequestFromJson(Map<String, dynamic> json) =>
    DocumentRequest(
      patientId: json['patientId'] as String,
      templateId: json['templateId'] as String,
      clinicalContent: json['clinicalContent'] == null
          ? {}
          : _fromJsonClinicalContent(json['clinicalContent'] as Map?),
      issueDate: const CustomDateTimeConverter().fromJson(
        json['issueDate'] as String,
      ),
      expiryDate: const NullableDateTimeConverter().fromJson(
        json['expiryDate'] as String?,
      ),
      fileUrl: json['fileUrl'] as String?,
      isExternalSource: json['isExternalSource'] as bool? ?? false,
    );

Map<String, dynamic> _$DocumentRequestToJson(
  DocumentRequest instance,
) => <String, dynamic>{
  'patientId': instance.patientId,
  'templateId': instance.templateId,
  'clinicalContent': instance.clinicalContent,
  'issueDate': const CustomDateTimeConverter().toJson(instance.issueDate),
  'expiryDate': const NullableDateTimeConverter().toJson(instance.expiryDate),
  'fileUrl': instance.fileUrl,
  'isExternalSource': instance.isExternalSource,
};

ExternalDocumentRequest _$ExternalDocumentRequestFromJson(
  Map<String, dynamic> json,
) => ExternalDocumentRequest(
  patientId: json['patientId'] as String,
  fileUrl: json['fileUrl'] as String,
  issueDate: const CustomDateTimeConverter().fromJson(
    json['issueDate'] as String,
  ),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ExternalDocumentRequestToJson(
  ExternalDocumentRequest instance,
) => <String, dynamic>{
  'patientId': instance.patientId,
  'fileUrl': instance.fileUrl,
  'issueDate': const CustomDateTimeConverter().toJson(instance.issueDate),
  'notes': instance.notes,
};
