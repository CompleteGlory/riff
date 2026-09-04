import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart';

@JsonSerializable()
class Author {
  final String id;

  @JsonKey(name: 'full_name')
  final String fullName;

  final String username;

  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  /// The viewer's relationship to this author: `following`, `pending` or
  /// `not_following`.
  ///
  /// Nullable because only the reels endpoint returns it so far, and an older
  /// cached payload will not have it. Read it through [isFollowedByViewer]
  /// rather than comparing the raw string at each call site.
  @JsonKey(name: 'follow_status')
  final String? followStatus;

  /// True when offering a Follow button would be wrong — either the request
  /// is already accepted, or it is sent and awaiting approval.
  bool get isFollowedByViewer =>
      followStatus == 'following' || followStatus == 'pending';

  /// True only while a request to a private account is awaiting approval.
  bool get hasPendingFollowRequest => followStatus == 'pending';

  Author({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    this.followStatus,
  });

  factory Author.fromJson(Map<String, dynamic> json) =>
      _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}