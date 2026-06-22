import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';

part 'profile_settings_state.dart';

class ProfileSettingsCubit extends Cubit<ProfileSettingsState> {
  final HomeRepo _repo;

  /// Original values — used to detect changes and skip no-op saves.
  late String _originalFullName;
  late String _originalUsername;
  late String _originalEmail;

  Timer? _debounce;

  ProfileSettingsCubit(this._repo)
      : super(const ProfileSettingsState(
          fullName: '',
          username: '',
          email: '',
          genres: [],
          instruments: [],
        ));

  // ── Initialise from an already-fetched profile ────────────────────────────

  void init(UserProfile profile) {
    _originalFullName = profile.fullName;
    _originalUsername = profile.username;
    _originalEmail = profile.email;
    emit(ProfileSettingsState(
      fullName: profile.fullName,
      username: profile.username,
      email: profile.email,
      genres: List<String>.from(profile.genres ?? []),
      instruments: List<String>.from(profile.instruments ?? []),
      usernameStatus: UsernameStatus.unchanged,
    ));
  }

  // ── Field change handlers ─────────────────────────────────────────────────

  void onFullNameChanged(String value) {
    emit(state.copyWith(
        fullName: value, clearSaveResult: true, clearError: true));
  }

  void onUsernameChanged(String value) {
    _debounce?.cancel();

    if (value == _originalUsername) {
      emit(state.copyWith(
        username: value,
        usernameStatus: UsernameStatus.unchanged,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      username: value,
      usernameStatus: UsernameStatus.checking,
      clearSaveResult: true,
      clearError: true,
    ));

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _checkUsername(value);
    });
  }

  Future<void> _checkUsername(String username) async {
    if (username.trim().isEmpty) {
      emit(state.copyWith(usernameStatus: UsernameStatus.idle));
      return;
    }
    final result = await _repo.checkUsername(username.trim());
    result.when(
      success: (available) {
        if (isClosed) return;
        emit(state.copyWith(
          usernameStatus:
              available ? UsernameStatus.available : UsernameStatus.taken,
        ));
      },
      failure: (_) {
        if (isClosed) return;
        emit(state.copyWith(usernameStatus: UsernameStatus.idle));
      },
    );
  }

  void onEmailChanged(String value) {
    emit(state.copyWith(email: value, clearSaveResult: true, clearError: true));
  }

  void toggleGenre(String genre) {
    final updated = List<String>.from(state.genres);
    if (updated.contains(genre)) {
      updated.remove(genre);
    } else {
      updated.add(genre);
    }
    emit(state.copyWith(genres: updated, clearSaveResult: true));
  }

  void toggleInstrument(String instrument) {
    final updated = List<String>.from(state.instruments);
    if (updated.contains(instrument)) {
      updated.remove(instrument);
    } else {
      updated.add(instrument);
    }
    emit(state.copyWith(instruments: updated, clearSaveResult: true));
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (state.usernameStatus == UsernameStatus.taken ||
        state.usernameStatus == UsernameStatus.checking) {
      return;
    }

    emit(state.copyWith(isSaving: true, clearSaveResult: true, clearError: true));

    final fullNameChanged = state.fullName.trim() != _originalFullName;
    final usernameChanged = state.username.trim() != _originalUsername;
    final emailChanged = state.email.trim() != _originalEmail;

    final result = await _repo.updateProfile(
      fullName: fullNameChanged ? state.fullName.trim() : null,
      username: usernameChanged ? state.username.trim() : null,
      email: emailChanged ? state.email.trim() : null,
      genres: state.genres,
      instruments: state.instruments,
    );

    result.when(
      success: (_) {
        if (isClosed) return;
        if (fullNameChanged) _originalFullName = state.fullName.trim();
        if (usernameChanged) _originalUsername = state.username.trim();
        if (emailChanged) _originalEmail = state.email.trim();
        emit(state.copyWith(
          isSaving: false,
          saveSuccess: true,
          usernameStatus: UsernameStatus.unchanged,
        ));
      },
      failure: (err) {
        if (isClosed) return;
        emit(state.copyWith(
          isSaving: false,
          saveSuccess: false,
          errorMessage: err.errors?.first.message ?? 'Unknown error',
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
