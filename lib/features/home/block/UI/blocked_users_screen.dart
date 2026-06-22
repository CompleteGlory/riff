import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/block/logic/cubit/block_cubit.dart';
import 'package:riff/core/widgets/app_error_widget.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BlockCubit>().loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: BlocBuilder<BlockCubit, BlockState>(
        builder: (ctx, state) {
          if (state is BlockLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BlockError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<BlockCubit>().loadBlockedUsers(),
            );
          }
          if (state is BlockLoaded) {
            if (state.blockedUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_outlined, size: 48.r, color: ColorManager.lightGrey),
                    SizedBox(height: 12.h),
                    Text('No blocked users',
                        style: TextStyles.font16Medium.copyWith(color: ColorManager.normalGrey)),
                    SizedBox(height: 4.h),
                    Text("Users you block won't appear in your feed or searches.",
                        textAlign: TextAlign.center,
                        style: TextStyles.font12regular.copyWith(color: ColorManager.lightGrey)),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: state.blockedUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final user = state.blockedUsers[i];
                final img = user.profileImageUrl;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: ColorManager.lightBlack,
                    backgroundImage: img != null ? NetworkImage(img) : null,
                    child: img == null
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  title: Text(user.fullName, style: TextStyles.font15semiBold),
                  subtitle: Text('@${user.username}',
                      style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey)),
                  trailing: TextButton(
                    onPressed: () => _confirmUnblock(ctx, user.id, user.username),
                    child: Text('Unblock',
                        style: TextStyles.font12semiBold.copyWith(color: ColorManager.accent)),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _confirmUnblock(BuildContext ctx, String userId, String username) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Unblock user?'),
        content: Text('Are you sure you want to unblock @$username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<BlockCubit>().unblockUser(userId);
            },
            child: Text('Unblock',
                style: TextStyles.font14semiBold.copyWith(color: ColorManager.accent)),
          ),
        ],
      ),
    );
  }
}
