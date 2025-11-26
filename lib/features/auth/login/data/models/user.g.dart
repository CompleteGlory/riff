// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  password: json['password'] as String?,
  fullName: json['full_name'] as String,
  username: json['username'] as String,
  profilePicture: json['profile_picture'] as String?,
  bio: json['bio'] as String?,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  isActive: json['isActive'] as bool?,
  isVerified: json['isVerified'] as bool?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'password': instance.password,
  'full_name': instance.fullName,
  'username': instance.username,
  'profile_picture': instance.profilePicture,
  'bio': instance.bio,
  'roles': instance.roles,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'isActive': instance.isActive,
  'isVerified': instance.isVerified,
};
