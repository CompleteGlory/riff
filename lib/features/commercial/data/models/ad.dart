import 'package:json_annotation/json_annotation.dart';

part 'ad.g.dart';

@JsonSerializable()
class AdStoreManager {
  final String id;

  @JsonKey(name: 'store_name')
  final String storeName;

  @JsonKey(name: 'store_logo')
  final String? storeLogo;

  AdStoreManager({
    required this.id,
    required this.storeName,
    this.storeLogo,
  });

  factory AdStoreManager.fromJson(Map<String, dynamic> json) =>
      _$AdStoreManagerFromJson(json);
  Map<String, dynamic> toJson() => _$AdStoreManagerToJson(this);
}

@JsonSerializable()
class Ad {
  final int id;
  final String? caption;
  final List<String>? media;

  @JsonKey(name: 'view_count')
  final int viewCount;

  @JsonKey(name: 'store_manager_id')
  final String storeManagerId;

  @JsonKey(name: 'storeManager')
  final AdStoreManager? storeManager;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Ad({
    required this.id,
    required this.viewCount,
    required this.storeManagerId,
    required this.createdAt,
    this.caption,
    this.media,
    this.storeManager,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => _$AdFromJson(json);
  Map<String, dynamic> toJson() => _$AdToJson(this);
}
