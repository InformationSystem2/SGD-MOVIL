// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientResponse _$PatientResponseFromJson(Map<String, dynamic> json) =>
    PatientResponse(
      id: json['id'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      birthDate: PatientResponse._parseDate(json['birthDate'] as String?),
    );

Map<String, dynamic> _$PatientResponseToJson(PatientResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'documentType': instance.documentType,
      'documentNumber': instance.documentNumber,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'address': instance.address,
      'gender': instance.gender,
      'birthDate': PatientResponse._formatDate(instance.birthDate),
    };

PatientCreateRequest _$PatientCreateRequestFromJson(
  Map<String, dynamic> json,
) => PatientCreateRequest(
  documentType: json['documentType'] as String,
  documentNumber: json['documentNumber'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  gender: json['gender'] as String?,
  birthDate: const CustomDateTimeConverter().fromJson(
    json['birthDate'] as String,
  ),
);

Map<String, dynamic> _$PatientCreateRequestToJson(
  PatientCreateRequest instance,
) => <String, dynamic>{
  'documentType': instance.documentType,
  'documentNumber': instance.documentNumber,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'phone': instance.phone,
  'address': instance.address,
  'gender': instance.gender,
  'birthDate': const CustomDateTimeConverter().toJson(instance.birthDate),
};

PatientUpdateRequest _$PatientUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PatientUpdateRequest(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  documentType: json['documentType'] as String,
  documentNumber: json['documentNumber'] as String,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  gender: json['gender'] as String?,
  birthDate: const CustomDateTimeConverter().fromJson(
    json['birthDate'] as String,
  ),
);

Map<String, dynamic> _$PatientUpdateRequestToJson(
  PatientUpdateRequest instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'documentType': instance.documentType,
  'documentNumber': instance.documentNumber,
  'phone': instance.phone,
  'address': instance.address,
  'gender': instance.gender,
  'birthDate': const CustomDateTimeConverter().toJson(instance.birthDate),
};
