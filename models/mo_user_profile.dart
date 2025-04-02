import 'package:json_annotation/json_annotation.dart';

part "mo_user_profile.g.dart";

@JsonSerializable()
class MoUserProfile {
  @JsonKey(name: '_id')
  String? id;
  
  String? name, email, password, token, displayName, photoURL;
  bool? isVerified;
  int? status, lastOnline, dateJoin;
  
  MoUserProfile({
    this.id,
    this.name,
    this.password,
    this.token,
    this.email,
    this.isVerified,
    this.status,
    this.lastOnline,
    this.dateJoin,
    this.displayName,
    this.photoURL,
  });

  factory MoUserProfile.fromJson(Map<String, dynamic> json) => 
      _$MoUserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$MoUserProfileToJson(this);
}