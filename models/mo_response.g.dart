// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mo_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoResponse _$MoResponseFromJson(Map<String, dynamic> json) => MoResponse(
  status: json['status'] as String?,
  success: json['success'] as bool?,
  message: json['message'] as String?,
  result: json['result'] as List<dynamic>?,
  res: json['res'] as List<dynamic>?,
  ttl: json['ttl'] as num?,
  createdAt: json['createdAt'] as num?,
);

Map<String, dynamic> _$MoResponseToJson(MoResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'success': instance.success,
      'ttl': instance.ttl,
      'createdAt': instance.createdAt,
      'result': instance.result,
      'res': instance.res,
    };
