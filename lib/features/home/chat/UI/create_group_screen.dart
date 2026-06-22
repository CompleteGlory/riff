// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/generated/l10n.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final List<SearchUser> _selected = [];
  List<SearchUser> _searchResults = [];
  bool _searching = false;
  bool _creating = false;

  File? _groupImage;
  bool _uploadingImage = false;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGroupPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _groupImage = File(picked.path);
      _uploadingImage = true;
      _uploadedImageUrl = null;
    });

    try {
      final dio = getIt<Dio>();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final res = await dio.post(ApiConstants.chatGroupPhotoUpload, data: formData);
      final url = (res.data as Map<String, dynamic>)['url'] as String?;
      setState(() {
        _uploadedImageUrl = url;
        _uploadingImage = false;
      });
    } catch (_) {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await getIt<SearchRepo>().searchUsers(q);
      setState(() {
        _searchResults = res;
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
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
      final conv = await getIt<ChatRepo>().createGroupConversation(
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        imageUrl: _uploadedImageUrl,
        memberIds: _selected.map((u) => u.id).toList(),
      );
      context.read<ChatsListCubit>().prependConversation(conv);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.groupCreationError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        if (_searching) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (_, i) {
              final user = _searchResults[i];
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
