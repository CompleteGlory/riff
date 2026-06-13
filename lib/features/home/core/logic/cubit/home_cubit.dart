import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_wrapper.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_screen.dart';
import 'package:riff/features/home/reels/ui/reels_screen.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/features/home/search/UI/search_screen.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepo _homeRepo;

  HomeCubit(this._homeRepo) : super(const HomeState.initial()) {
    _loadUser();
  }

  int currentIndex = 0;

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

  Future<void> _loadUser() async {
    final result = await _homeRepo.getMe();
    result.when(
      success: (profile) {
        // Cache profile image URL so comment sheet can use it for optimistic avatars
        if (profile.profileImageUrl != null) {
          SharedPrefHelper.setData(
            SharedPrefKeys.userProfileImage,
            profile.profileImageUrl!,
          );
        }
        screens[4] = ProfileScreen(profile: profile);
        emit(HomeState.changeScreen(currentIndex));
      },
      failure: (_) {
        // Keep spinner — user can retry by navigating away and back
      },
    );
  }

  void changeScreen(int index) {
    currentIndex = index;
    emit(HomeState.changeScreen(index));
  }
}
