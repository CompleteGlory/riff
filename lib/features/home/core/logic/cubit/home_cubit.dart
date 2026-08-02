import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/widgets/app_error_widget.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_wrapper.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_screen.dart';
import 'package:riff/features/home/reels/ui/reels_screen.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/features/home/search/UI/search_screen.dart';

class HomeCubit extends Cubit<HomeState> with ReconnectRefresh<HomeState> {
  final HomeRepo _homeRepo;

  HomeCubit(this._homeRepo) : super(const HomeState.initial()) {
    _loadUser();
    // If the profile tab fell back to the cached copy (or to an error), pick up
    // the real one as soon as there is a connection to fetch it over.
    refreshOnReconnect(_loadUser);
  }

  int currentIndex = 0;

  /// Shared scroll controller for the feed list.
  /// Held here so [changeScreen] can animate to top on re-tap without
  /// needing a new freezed state variant.
  final ScrollController feedScrollController = ScrollController();

  final List<String> titles = [
    'Feed',
    'Search',
    'Create Post',
    'Reels',
    'Profile',
  ];

  List<Widget> screens = [
    const FeedScreen(),
    const SearchScreen(),
    CreatePostWrapper(),
    const ReelsScreen(),
    const Center(child: CircularProgressIndicator()),
  ];

  /// The signed-in user's profile, or null while it is still loading (or if the
  /// fetch failed).
  ///
  /// `screens[4]` is where [_loadUser] parks it: a [ProfileScreen] on success,
  /// a spinner or an error widget otherwise. Anything that needs the profile
  /// goes through here rather than repeating that cast at the call site.
  UserProfile? get profile {
    final screen = screens[4];
    return screen is ProfileScreen ? screen.profile : null;
  }

  Future<void> _loadUser() async {
    final result = await _homeRepo.getMe();
    await result.when(
      success: (profile) async {
        // Cache profile image URL so comment sheet can use it for optimistic avatars
        if (profile.profileImageUrl != null) {
          SharedPrefHelper.setData(
            SharedPrefKeys.userProfileImage,
            profile.profileImageUrl!,
          );
        }
        // Scope the offline cache to this user before anything writes to it, so
        // a cold start that reaches the feed first can't file this session's
        // data under the previous account.
        OfflineCache.instance.useScope(profile.id);
        screens[4] = ProfileScreen(profile: profile);
        if (!isClosed) emit(HomeState.changeScreen(currentIndex));
        // Written after the emit, not before: the screen must never wait on a
        // disk write, and awaiting one here meant a cubit closed in between got
        // an emit-after-close.
        unawaited(
          OfflineCache.instance.writeMap(CacheKeys.myProfile, profile.toJson()),
        );
      },
      failure: (err) async {
        // The profile tab is mostly static information the user already gave
        // us — there is no reason for it to be an error page just because the
        // device is offline.
        final cached = await _cachedProfile();
        if (isClosed) return;
        screens[4] = cached != null
            ? ProfileScreen(profile: cached)
            : Center(
                child: AppErrorWidget(
                  message: err.message,
                  onRetry: _loadUser,
                ),
              );
        emit(HomeState.changeScreen(currentIndex));
      },
    );
  }

  Future<UserProfile?> _cachedProfile() async {
    final raw = await OfflineCache.instance.readMap(CacheKeys.myProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(raw);
    } catch (e) {
      debugPrint('HomeCubit: cached profile unreadable — $e');
      return null;
    }
  }

  /// Re-fetches the current user and rebuilds screens[4].
  /// Call this after a profile update to reflect changes without a restart.
  Future<void> refreshProfile() => _loadUser();

  void changeScreen(int index) {
    // Re-tapping the feed tab: scroll to top without refreshing.
    if (index == 0 && currentIndex == 0) {
      if (feedScrollController.hasClients) {
        feedScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    currentIndex = index;
    emit(HomeState.changeScreen(index));
  }

  @override
  Future<void> close() {
    feedScrollController.dispose();
    return super.close();
  }
}
