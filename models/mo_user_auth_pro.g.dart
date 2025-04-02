// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mo_user_auth_pro.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoUserAuthPro _$MoUserAuthProFromJson(Map<String, dynamic> json) =>
    MoUserAuthPro(
      provider: json['provider'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      id: json['id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool?,
    );

Map<String, dynamic> _$MoUserAuthProToJson(MoUserAuthPro instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'isVerified': instance.isVerified,
    };
