// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mo_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoUserProfile _$MoUserProfileFromJson(Map<String, dynamic> json) =>
    MoUserProfile(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      password: json['password'] as String?,
      token: json['token'] as String?,
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool?,
      status: (json['status'] as num?)?.toInt(),
      lastOnline: (json['lastOnline'] as num?)?.toInt(),
      dateJoin: (json['dateJoin'] as num?)?.toInt(),
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$MoUserProfileToJson(MoUserProfile instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
      'token': instance.token,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'isVerified': instance.isVerified,
      'status': instance.status,
      'lastOnline': instance.lastOnline,
      'dateJoin': instance.dateJoin,
    };
