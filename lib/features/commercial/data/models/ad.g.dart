// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdStoreManager _$AdStoreManagerFromJson(Map<String, dynamic> json) =>
    AdStoreManager(
      id: json['id'] as String,
      storeName: json['store_name'] as String,
      storeLogo: json['store_logo'] as String?,
    );

Map<String, dynamic> _$AdStoreManagerToJson(AdStoreManager instance) =>
    <String, dynamic>{
      'id': instance.id,
      'store_name': instance.storeName,
      'store_logo': instance.storeLogo,
    };

Ad _$AdFromJson(Map<String, dynamic> json) => Ad(
  id: (json['id'] as num).toInt(),
  viewCount: (json['view_count'] as num).toInt(),
  storeManagerId: json['store_manager_id'] as String,
  createdAt: json['created_at'] as String,
  caption: json['caption'] as String?,
  link: json['link'] as String?,
  media: (json['media'] as List<dynamic>?)?.map((e) => e as String).toList(),
  storeManager: json['storeManager'] == null
      ? null
      : AdStoreManager.fromJson(json['storeManager'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdToJson(Ad instance) => <String, dynamic>{
  'id': instance.id,
  'caption': instance.caption,
  'link': instance.link,
  'media': instance.media,
  'view_count': instance.viewCount,
  'store_manager_id': instance.storeManagerId,
  'storeManager': instance.storeManager,
  'created_at': instance.createdAt,
};
