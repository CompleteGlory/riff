// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/user_search_cubit.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/generated/l10n.dart';
import 'package:riff/core/utils/media_limits.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  /// Owned by the State, not created inside `build`.
  ///
  /// A `BlocProvider` created in `build` sits *below* this element, and
  /// `context.read` walks upward — so a State method reading it that way finds
  /// nothing and throws on the first keystroke. Holding it here and handing it
  /// down with `BlocProvider.value` gives both the State and the subtree the
  /// same instance.
  late final UserSearchCubit _userSearch = getIt<UserSearchCubit>();

  final List<SearchUser> _selected = [];
  bool _creating = false;

  File? _groupImage;
  bool _uploadingImage = false;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _userSearch.close();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGroupPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: kMaxImageDimension,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _groupImage = File(picked.path);
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });

    try {
      // The group does not exist yet, so this is the upload alone — but it
      // is still a network call with a payload to parse, which is the data
      // layer's job, not a widget's.
      final url = await getIt<ChatsListCubit>().uploadGroupPhoto(
        picked.path,
        picked.name,
      );
      if (url == null) throw StateError('group photo upload failed');
      setState(() {
        _uploadedImageUrl = url;
        _uploadingImage = false;
      });
    } catch (_) {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _search(String q) async {
    // Debounce, request and result-ordering live on the cubit — this was
    // the second copy of the same logic, and it did not even debounce.
    _userSearch.search(q);
  }


  void _toggle(SearchUser user) {
    setState(() {
      if (_selected.any((u) => u.id == user.id)) {
        _selected.removeWhere((u) => u.id == user.id);
      } else {
        _selected.add(user);
      }
    });
  }

  bool _isSelected(String id) => _selected.any((u) => u.id == id);

  Future<void> _create() async {
    final s = S.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.groupNameRequired)));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.groupMemberRequired)));
      return;
    }
    setState(() => _creating = true);
    try {
      // One call: the cubit creates the group and puts it at the top of its
      // own list, so the two halves cannot disagree.
      final conv = await context.read<ChatsListCubit>().createGroup(
            name: name,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            imageUrl: _uploadedImageUrl,
            memberIds: _selected.map((u) => u.id).toList(),
          );
      if (!mounted) return;
      if (conv != null) {
        Navigator.pop(context);
      } else {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.groupCreationError(''))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.groupCreationError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen's own search field, so its own cubit — a factory, not a
    // singleton, or the chat list's field and this one would clear each other.
    return BlocProvider<UserSearchCubit>.value(
      value: _userSearch,
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.newGroupTitle),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    s.createGroupBtn,
                    style: TextStyles.font15semiBold.copyWith(color: ColorManager.accent),
                  ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Group info ────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(children: [
            // Avatar / camera picker
            GestureDetector(
              onTap: _uploadingImage ? null : _pickGroupPhoto,
              child: Stack(
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                      image: _groupImage != null
                          ? DecorationImage(
                              image: FileImage(_groupImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _groupImage == null
                        ? Icon(Icons.camera_alt_outlined,
                            color: isDark ? ColorManager.normalGrey : ColorManager.darkGrey)
                        : null,
                  ),
                  if (_uploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(hintText: s.groupNameHint),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(hintText: s.groupDescriptionHint),
                ),
              ]),
            ),
          ]),
        ),

        // ── Selected member chips ─────────────────────────────────────
        if (_selected.isNotEmpty)
          SizedBox(
            height: 48.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: _selected.map((u) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Chip(
                    label: Text(u.username, style: TextStyles.font12semiBold),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => _toggle(u),
                    backgroundColor: ColorManager.accent.withValues(alpha: 0.15),
                  ),
                );
              }).toList(),
            ),
          ),

        // ── User search ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: s.searchUsersHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),
        BlocBuilder<UserSearchCubit, UserSearchState>(
          builder: (_, search) => search.isSearching
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: context.watch<UserSearchCubit>().state.results.length,
            itemBuilder: (_, i) {
              final user = context.watch<UserSearchCubit>().state.results[i];
              final selected = _isSelected(user.id);
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null
                      ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(user.username, style: TextStyles.font15semiBold),
                subtitle: Text(user.fullName,
                    style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey)),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded, color: ColorManager.accent)
                    : const Icon(Icons.circle_outlined, color: ColorManager.normalGrey),
                onTap: () => _toggle(user),
              );
            },
          ),
        ),
      ]),
    );
  }
}
