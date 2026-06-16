// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/new_user_onboarding/data/repos/suggested_users_repo.dart';
import 'package:riff/features/home/follow/data/repos/follow_repo.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:dio/dio.dart';

class NewUserOnboardingScreen extends StatefulWidget {
  const NewUserOnboardingScreen({super.key});

  @override
  State<NewUserOnboardingScreen> createState() =>
      _NewUserOnboardingScreenState();
}

class _NewUserOnboardingScreenState extends State<NewUserOnboardingScreen> {
  final PageController _page = PageController(keepPage: false);
  int _currentStep = 0; // 0, 1, 2

  // Step 1 — photo
  File? _photo;
  bool _uploadingPhoto = false;

  // Step 2 — contacts
  bool _contactsSynced = false;
  bool _syncingContacts = false;
  List<SearchUser> _contactMatches = [];

  // Step 3 — suggested users
  List<SearchUser> _suggested = [];
  bool _loadingSuggested = true;

  final Set<String> _followed = {};
  final Map<String, bool> _inProgress = {};

  final ProfileRepo _profileRepo = getIt<ProfileRepo>();
  final FollowRepo _followRepo = getIt<FollowRepo>();
  final SuggestedUsersRepo _suggestedRepo = getIt<SuggestedUsersRepo>();
  final Dio _dio = getIt<Dio>();

  @override
  void initState() {
    super.initState();
    _loadSuggested();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _loadSuggested() async {
    final result = await _suggestedRepo.getSuggested();
    result.when(
      success: (users) => setState(() {
        _suggested = users;
        _loadingSuggested = false;
      }),
      failure: (_) => setState(() => _loadingSuggested = false),
    );
  }

  // ── Step 1 actions ────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) setState(() => _photo = File(file.path));
  }

  Future<void> _uploadAndNext() async {
    if (_photo != null) {
      setState(() => _uploadingPhoto = true);
      await _profileRepo.uploadProfileImage(_photo!);
      setState(() => _uploadingPhoto = false);
    }
    _goTo(1);
  }

  // ── Step 2 actions ────────────────────────────────────────────────────────

  Future<void> _syncContacts() async {
    if (_syncingContacts) return;
    setState(() => _syncingContacts = true);

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _syncingContacts = false);
      return;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final phones = contacts
        .expand((c) => c.phones)
        .map((p) => p.number.replaceAll(RegExp(r'\s|-|\(|\)'), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    if (phones.isNotEmpty) {
      try {
        final resp = await _dio.post(
          '${ApiConstants.apiBASEURL}${ApiConstants.findContacts}',
          data: {'phone_numbers': phones},
        );
        final list = (resp.data as List? ?? [])
            .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _contactMatches = list);
      } catch (_) {}
    }

    setState(() {
      _contactsSynced = true;
      _syncingContacts = false;
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goTo(int step) {
    setState(() => _currentStep = step);
    _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _toggleFollow(SearchUser user) async {
    if (_inProgress[user.id] == true) return;
    setState(() => _inProgress[user.id] = true);
    if (_followed.contains(user.id)) {
      await _followRepo.unfollowUser(user.id);
      _followed.remove(user.id);
    } else {
      await _followRepo.followUser(user.id);
      _followed.add(user.id);
    }
    setState(() => _inProgress[user.id] = false);
  }

  void _finish() =>
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (r) => false);

  String _resolve(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.apiBASEURL}$url';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Step bar
            _StepBar(current: _currentStep, isDark: isDark),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  if (_currentStep != index) {
                    setState(() => _currentStep = index);
                  }
                },
                children: [
                  // ── Step 1: Photo ──
                  _PhotoStep(
                    isDark: isDark,
                    photo: _photo,
                    uploading: _uploadingPhoto,
                    onPick: _pickPhoto,
                    onNext: _uploadAndNext,
                    onSkip: () => _goTo(1),
                  ),
                  // ── Step 2: Contacts ──
                  _ContactsStep(
                    isDark: isDark,
                    synced: _contactsSynced,
                    syncing: _syncingContacts,
                    matches: _contactMatches,
                    followed: _followed,
                    inProgress: _inProgress,
                    onSync: _syncContacts,
                    onToggleFollow: _toggleFollow,
                    onNext: () => _goTo(2),
                    resolveUrl: _resolve,
                  ),
                  // ── Step 3: Suggested ──
                  _SuggestStep(
                    isDark: isDark,
                    users: _suggested,
                    loading: _loadingSuggested,
                    followed: _followed,
                    inProgress: _inProgress,
                    onToggleFollow: _toggleFollow,
                    onFinish: _finish,
                    resolveUrl: _resolve,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step bar
// ══════════════════════════════════════════════════════════════════════════════

class _StepBar extends StatelessWidget {
  final int current;
  final bool isDark;

  const _StepBar({required this.current, required this.isDark});

  static const _labels = ['Photo', 'Contacts', 'Follow'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 12.h),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final passed = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                color: passed
                    ? ColorManager.accent
                    : (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE0E0E0)),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final done = stepIndex < current;
          final active = stepIndex == current;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? ColorManager.accent
                      : active
                      ? ColorManager.accent.withOpacity(0.15)
                      : (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0)),
                  border: Border.all(
                    color: (done || active)
                        ? ColorManager.accent
                        : (isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFDDDDDD)),
                    width: active ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? Icon(Icons.check_rounded, size: 16.r, color: Colors.black)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? ColorManager.accent
                              : (isDark
                                    ? const Color(0xFF555555)
                                    : const Color(0xFFAAAAAA)),
                        ),
                      ),
              ),
              SizedBox(height: 4.h),
              Text(
                _labels[stepIndex],
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 11,
                  fontWeight: active || done
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: active || done
                      ? (isDark ? Colors.white : ColorManager.black)
                      : (isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFAAAAAA)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 1 — Profile photo
// ══════════════════════════════════════════════════════════════════════════════

class _PhotoStep extends StatelessWidget {
  final bool isDark;
  final File? photo;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PhotoStep({
    required this.isDark,
    required this.photo,
    required this.uploading,
    required this.onPick,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          verticalSpace(28),
          Text('Add a profile photo', style: TextStyles.font28Bold),
          verticalSpace(6),
          Text(
            'Help your friends recognise you.\nYou can always change this later.',
            style: TextStyles.font16Medium.copyWith(
              color: ColorManager.lightGrey,
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(44),
          GestureDetector(
            onTap: onPick,
            child: Stack(
              children: [
                Container(
                  width: 130.r,
                  height: 130.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF0F0F0),
                    border: Border.all(
                      color: ColorManager.accent.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: photo != null
                      ? ClipOval(child: Image.file(photo!, fit: BoxFit.cover))
                      : Icon(
                          Icons.person_outline_rounded,
                          size: 56.r,
                          color: isDark
                              ? const Color(0xFF555555)
                              : const Color(0xFFBBBBBB),
                        ),
                ),
                Positioned(
                  bottom: 4.r,
                  right: 4.r,
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: ColorManager.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16.r,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          verticalSpace(12),
          TextButton(
            onPressed: onPick,
            child: Text(
              photo != null ? 'Change photo' : 'Choose from gallery',
              style: TextStyles.font14Medium.copyWith(
                color: ColorManager.accent,
              ),
            ),
          ),
          verticalSpace(36),
          AppButton(
            text: uploading
                ? 'Saving…'
                : (photo != null ? 'Save & Continue' : 'Continue'),
            isWhite: false,
            onPressed: () {
              if (!uploading) onNext();
            },
          ),
          verticalSpace(12),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip for now',
              style: TextStyles.font14Medium.copyWith(
                color: ColorManager.normalGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 2 — Sync contacts
// ══════════════════════════════════════════════════════════════════════════════

class _ContactsStep extends StatelessWidget {
  final bool isDark;
  final bool synced;
  final bool syncing;
  final List<SearchUser> matches;
  final Set<String> followed;
  final Map<String, bool> inProgress;
  final VoidCallback onSync;
  final void Function(SearchUser) onToggleFollow;
  final VoidCallback onNext;
  final String Function(String) resolveUrl;

  const _ContactsStep({
    required this.isDark,
    required this.synced,
    required this.syncing,
    required this.matches,
    required this.followed,
    required this.inProgress,
    required this.onSync,
    required this.onToggleFollow,
    required this.onNext,
    required this.resolveUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find your contacts', style: TextStyles.font28Bold),
              verticalSpace(6),
              Text(
                'See which of your contacts are already on Riff.',
                style: TextStyles.font16Medium.copyWith(
                  color: ColorManager.lightGrey,
                ),
              ),
              verticalSpace(20),
            ],
          ),
        ),

        if (!synced) ...[
          // Sync prompt card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GestureDetector(
              onTap: syncing ? null : onSync,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52.r,
                      height: 52.r,
                      decoration: BoxDecoration(
                        color: ColorManager.accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contacts_rounded,
                        color: ColorManager.accent,
                        size: 26.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync Contacts',
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'We\'ll match your contacts with Riff users.',
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 13,
                              color: const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    syncing
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorManager.accent,
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.r,
                            color: isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFFAAAAAA),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (matches.isEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: ColorManager.accent,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Contacts synced — none of your contacts are on Riff yet.',
                    style: TextStyles.font14Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: matches.length,
              itemBuilder: (_, i) => _UserTile(
                user: matches[i],
                isDark: isDark,
                isFollowed: followed.contains(matches[i].id),
                inProgress: inProgress[matches[i].id] == true,
                onToggle: () => onToggleFollow(matches[i]),
                resolveUrl: resolveUrl,
              ),
            ),
          ),
        ],

        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
          child: AppButton(
            text: synced ? 'Continue' : 'Skip',
            isWhite: false,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step 3 — Suggested users
// ══════════════════════════════════════════════════════════════════════════════

class _SuggestStep extends StatelessWidget {
  final bool isDark;
  final List<SearchUser> users;
  final bool loading;
  final Set<String> followed;
  final Map<String, bool> inProgress;
  final void Function(SearchUser) onToggleFollow;
  final VoidCallback onFinish;
  final String Function(String) resolveUrl;

  const _SuggestStep({
    required this.isDark,
    required this.users,
    required this.loading,
    required this.followed,
    required this.inProgress,
    required this.onToggleFollow,
    required this.onFinish,
    required this.resolveUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('People you might like', style: TextStyles.font28Bold),
              verticalSpace(6),
              Text(
                'Follow artists and musicians to fill your feed.',
                style: TextStyles.font16Medium.copyWith(
                  color: ColorManager.lightGrey,
                ),
              ),
              verticalSpace(20),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
              ? Center(
                  child: Text(
                    'No suggestions yet',
                    style: TextStyles.font16Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _UserTile(
                    user: users[i],
                    isDark: isDark,
                    isFollowed: followed.contains(users[i].id),
                    inProgress: inProgress[users[i].id] == true,
                    onToggle: () => onToggleFollow(users[i]),
                    resolveUrl: resolveUrl,
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
          child: AppButton(
            text: followed.isEmpty ? 'Skip' : 'Get Started  🎵',
            isWhite: false,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared user tile
// ══════════════════════════════════════════════════════════════════════════════

class _UserTile extends StatelessWidget {
  final SearchUser user;
  final bool isDark;
  final bool isFollowed;
  final bool inProgress;
  final VoidCallback onToggle;
  final String Function(String) resolveUrl;

  const _UserTile({
    required this.user,
    required this.isDark,
    required this.isFollowed,
    required this.inProgress,
    required this.onToggle,
    required this.resolveUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            ),
            child: user.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      resolveUrl(user.profileImageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 22,
                        color: Color(0xFF888888),
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 22, color: Color(0xFF888888)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : ColorManager.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: inProgress ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isFollowed ? Colors.transparent : ColorManager.accent,
                borderRadius: BorderRadius.circular(20.r),
                border: isFollowed
                    ? Border.all(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFDDDDDD),
                      )
                    : null,
              ),
              child: inProgress
                  ? SizedBox(
                      width: 13.r,
                      height: 13.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isFollowed
                            ? ColorManager.normalGrey
                            : Colors.black,
                      ),
                    )
                  : Text(
                      isFollowed ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFollowed
                            ? (isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFF666666))
                            : Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
