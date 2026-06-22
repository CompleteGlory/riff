part of 'profile_settings_cubit.dart';

enum UsernameStatus { idle, checking, available, taken, unchanged }

class ProfileSettingsState {
  final String fullName;
  final String username;
  final String email;
  final List<String> genres;
  final List<String> instruments;
  final UsernameStatus usernameStatus;
  final bool isSaving;
  final bool? saveSuccess; // null = not attempted, true = ok, false = failed
  final String? errorMessage;

  const ProfileSettingsState({
    required this.fullName,
    required this.username,
    required this.email,
    required this.genres,
    this.instruments = const [],
    this.usernameStatus = UsernameStatus.idle,
    this.isSaving = false,
    this.saveSuccess,
    this.errorMessage,
  });

  ProfileSettingsState copyWith({
    String? fullName,
    String? username,
    String? email,
    List<String>? genres,
    List<String>? instruments,
    UsernameStatus? usernameStatus,
    bool? isSaving,
    bool? saveSuccess,
    String? errorMessage,
    bool clearSaveResult = false,
    bool clearError = false,
  }) =>
      ProfileSettingsState(
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        email: email ?? this.email,
        genres: genres ?? this.genres,
        instruments: instruments ?? this.instruments,
        usernameStatus: usernameStatus ?? this.usernameStatus,
        isSaving: isSaving ?? this.isSaving,
        saveSuccess: clearSaveResult ? null : (saveSuccess ?? this.saveSuccess),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}
