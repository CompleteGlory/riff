// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added for Cubit access
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? _selectedMediaUrl; // Simulated media selection

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handlePost() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: ColorManager.primaryBlack,content: Text('Please enter content before posting.',style: TextStyles.font14Medium.copyWith(color: ColorManager.lighterGrey),)),
      );
      return;
    }

    // 1. Create the Request Model
    final requestModel = CreatePostRequestModel(
      content: content,
      // NOTE: Assuming your media list is a list of URLs or paths
      media: _selectedMediaUrl != null ? [_selectedMediaUrl!] : null,
    );

    // 2. Call the Cubit to initiate the post creation process
    context.read<CreatePostCubit>().createPost(requestModel);

    // 3. REMOVED SIMULATED SUCCESS/POP LOGIC: The AddPostListener now handles
    // showing the loading indicator, success message, and popping the screen.
  }

  void _selectMedia() {
    // NOTE: In a real app, this would open the image picker.
    // We simulate selecting a placeholder image for design purposes.
    setState(() {
      _selectedMediaUrl = 'assets/images/placeholder_riff.png';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s on your mind?',
              style: TextStyles.font28Bold.copyWith(
                color: ColorManager.primaryBlack,
              ),
            ),
            verticalSpace(20),
            // Content Input Field
            Container(
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.lighterGrey.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 10,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                style: TextStyles.font16Medium,
                decoration: InputDecoration(
                  hintText:
                      "Share your latest music riff, thoughts, or gear...",
                  hintStyle: TextStyles.font16Medium.copyWith(
                    color: ColorManager.normalGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
            ),

            verticalSpace(20),

            // Media Preview/Selection Area
            Text('Attach Media', style: TextStyles.font15semiBold),
            verticalSpace(10),

            Container(
              width: double.infinity,
              height: _selectedMediaUrl == null ? 80.h : 200.h,
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ColorManager.lighterGrey),
              ),
              child: _selectedMediaUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          // Use a placeholder network image URL if you don't have local assets
                          child: Image.network(
                            'https://placehold.co/600x200/5C6BC0/FFFFFF/png?text=Media+Attached',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedMediaUrl = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: ColorManager.primaryBlack.withOpacity(
                                  0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: ColorManager.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon:  Icon(
                              Icons.add_a_photo_outlined,
                              color: ColorManager.primaryBlack,
                            ),
                            iconSize: 30,
                            onPressed: _selectMedia,
                          ),
                          verticalSpace(4),
                          Text(
                            'Tap to add photo or video',
                            style: TextStyles.font14regular.copyWith(
                              color: ColorManager.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            verticalSpace(50),
            // Post Button
            AppButton(onPressed: (){
              _handlePost(); // Triggers the Cubit
            }, text: "Post", isWhite: false),
            // AddPostListener is now in the parent wrapper
          ],
        ),
      ),
    );
  }
}