// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/generated/l10n.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Conversation conversation;
  const GroupDetailsScreen({super.key, required this.conversation});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late Conversation _conv;
  bool _uploadingPhoto = false;
  String? _myId;
  File? _localImage; // shown immediately before server confirms

  @override
  void initState() {
    super.initState();
    _conv = widget.conversation;
    _loadMyId();
  }

  Future<void> _loadMyId() async {
    final id = await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    if (mounted) setState(() => _myId = id);
  }

  bool get _isAdmin =>
      _myId != null &&
      _conv.participants.any((p) => p.userId == _myId && p.role == 'admin');

  Future<void> _showEditSheet() async {
    final updated = await showModalBottomSheet<Conversation>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => _EditGroupSheet(
        conversationId: _conv.id,
        initialName: _conv.name ?? '',
        initialDescription: _conv.description ?? '',
      ),
    );

    if (updated != null && mounted) {
      setState(() => _conv = updated);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _localImage = File(picked.path);
      _uploadingPhoto = true;
    });

    try {
      final dio = getIt<Dio>();

      // 1. Upload to Cloudinary via our endpoint
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      final uploadRes = await dio.post(ApiConstants.chatGroupPhotoUpload, data: formData);
      final url = (uploadRes.data as Map<String, dynamic>)['url'] as String?;

      if (url == null) throw Exception('No URL returned');

      // 2. Patch the conversation
      final updated = await getIt<ChatRepo>().updateGroup(
        _conv.id,
        imageUrl: url,
      );

      if (mounted) {
        setState(() {
          _conv = updated;
          _localImage = null;
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localImage = null;
          _uploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedUrl = _conv.imageUrl != null ? MediaUrl.resolve(_conv.imageUrl) : null;

    final adminParticipants = _conv.participants.where((p) => p.role == 'admin').toList();
    final memberParticipants = _conv.participants.where((p) => p.role != 'admin').toList();
    final allSorted = [...adminParticipants, ...memberParticipants];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.groupDetailsTitle),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditSheet,
            ),
        ],
      ),
      body: ListView(
        children: [
          // ── Group image ─────────────────────────────────────────────
          SizedBox(height: 24.h),
          Center(
            child: GestureDetector(
              onTap: _isAdmin && !_uploadingPhoto ? _pickAndUpload : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52.r,
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    backgroundImage: _localImage != null
                        ? FileImage(_localImage!) as ImageProvider
                        : resolvedUrl != null
                            ? CachedNetworkImageProvider(resolvedUrl)
                            : null,
                    child: (_localImage == null && resolvedUrl == null)
                        ? Icon(Icons.group_rounded,
                            size: 40.r,
                            color: isDark ? ColorManager.normalGrey : ColorManager.darkGrey)
                        : null,
                  ),
                  // Loading overlay
                  if (_uploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  // Camera badge (only for admins, not uploading)
                  if (_isAdmin && !_uploadingPhoto)
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: ColorManager.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF121212) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 14.r, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // ── Group name ──────────────────────────────────────────────
          SizedBox(height: 12.h),
          Center(
            child: Text(
              _conv.name ?? '',
              style: TextStyles.font18SemiBold,
              textAlign: TextAlign.center,
            ),
          ),

          // ── Description ─────────────────────────────────────────────
          if (_conv.description != null && _conv.description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _conv.description!,
                  style: TextStyles.font12regular
                      .copyWith(color: ColorManager.normalGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 8.h),
            Center(
              child: Text(
                s.groupNoDescription,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.normalGrey),
              ),
            ),
          ],

          SizedBox(height: 24.h),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

          // ── Members ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              '${s.groupMembersSection} (${allSorted.length})',
              style: TextStyles.font13SemiBold
                  .copyWith(color: ColorManager.normalGrey),
            ),
          ),
          ...allSorted.map((p) => _MemberTile(participant: p)),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

// ── Edit group bottom sheet ──────────────────────────────────────────────────
// Owns its own TextEditingControllers so they are disposed with the widget,
// not while the dismiss animation is still running (which caused the crash).
class _EditGroupSheet extends StatefulWidget {
  final String conversationId;
  final String initialName;
  final String initialDescription;

  const _EditGroupSheet({
    required this.conversationId,
    required this.initialName,
    required this.initialDescription,
  });

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await getIt<ChatRepo>().updateGroup(
        widget.conversationId,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(s.newGroupTitle, style: TextStyles.font18SemiBold),
          SizedBox(height: 16.h),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: s.groupNameHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.groupDescriptionHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.saveChangesBtn),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChatParticipant participant;
  const _MemberTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAdmin = participant.role == 'admin';
    final imageUrl = participant.profileImageUrl != null
        ? MediaUrl.resolve(participant.profileImageUrl)
        : null;
    final name = participant.username ?? participant.fullName ?? '';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      leading: CircleAvatar(
        radius: 22.r,
        backgroundImage:
            imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
        child: imageUrl == null
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(name, style: TextStyles.font15semiBold),
      subtitle: participant.fullName != null && participant.fullName != name
          ? Text(participant.fullName!,
              style: TextStyles.font12regular
                  .copyWith(color: ColorManager.normalGrey))
          : null,
      trailing: isAdmin
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorManager.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                s.groupAdminBadge,
                style: TextStyles.font12semiBold
                    .copyWith(color: ColorManager.accent),
              ),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: participant.userId),
        ),
      ),
    );
  }
}
