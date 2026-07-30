import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';

/// `UserProfile` is what `HomeRepo.getMe()` parses `GET /api/users/me` into,
/// and its `phoneVerified` flag is the single input deciding whether account
/// settings shows the "confirm your phone number" entry.
void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'u1',
        'full_name': 'Magd Kamal',
        'username': 'magdkamal',
        'email': 'magd@example.com',
      };

  test('reads phone_number and phone_verified from the response', () {
    final profile = UserProfile.fromJson({
      ...baseJson(),
      'phone_number': '201068866005',
      'phone_verified': true,
    });

    expect(profile.phoneNumber, '201068866005');
    expect(profile.phoneVerified, isTrue);
  });

  test('treats phone_verified false as unverified', () {
    final profile = UserProfile.fromJson({
      ...baseJson(),
      'phone_number': '201068866005',
      'phone_verified': false,
    });

    expect(profile.phoneVerified, isFalse);
  });

  test('defaults phoneVerified to true when the key is absent', () {
    // A client running against an API that predates these fields must not
    // conclude every user is unverified and nag all of them — absent means
    // "unknown", and unknown must stay quiet.
    final profile = UserProfile.fromJson(baseJson());

    expect(profile.phoneVerified, isTrue);
    expect(profile.phoneNumber, isNull);
  });

  test('handles a null phone_number on an unverified account', () {
    // The real shape for a user who has never submitted a number: the column
    // is null while the flag is false.
    final profile = UserProfile.fromJson({
      ...baseJson(),
      'phone_number': null,
      'phone_verified': false,
    });

    expect(profile.phoneNumber, isNull);
    expect(profile.phoneVerified, isFalse);
  });

  test('leaves the existing fields untouched', () {
    final profile = UserProfile.fromJson({
      ...baseJson(),
      'bio': 'guitarist',
      'followersCount': 12,
      'followingCount': 7,
      'genres': ['rock'],
    });

    expect(profile.id, 'u1');
    expect(profile.username, 'magdkamal');
    expect(profile.bio, 'guitarist');
    expect(profile.followersCount, 12);
    expect(profile.followingCount, 7);
    expect(profile.genres, ['rock']);
  });
}
