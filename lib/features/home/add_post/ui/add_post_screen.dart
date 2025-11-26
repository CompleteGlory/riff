import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
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
        const SnackBar(content: Text('Please enter content before posting.')),
      );
      return;
    }

    // NOTE: This is where you would call your Cubit/Repo to create the post.
    // For now, we simulate success and pop the screen.
    
    print('Posting content: $content');
    if (_selectedMediaUrl != null) {
      print('With media: $_selectedMediaUrl');
    }

    // Show confirmation and close the screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post is being created!')),
    );
    Navigator.pop(context);
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
      backgroundColor: ColorManager.lightGrey,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        elevation: 0,
        title: Text(
          'Create New Riff',
          style: TextStyles.font18Semibold.copyWith(color: ColorManager.primaryBlack),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ColorManager.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: TextButton(
              onPressed: _handlePost,
              style: TextButton.styleFrom(
                backgroundColor: ColorManager.primaryBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              child: Text(
                'Post',
                style: TextStyles.font15semiBold.copyWith(color: ColorManager.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header (similar to PostItem)
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: ColorManager.lighterGrey,
                  child: Icon(Icons.person, color: ColorManager.white),
                ),
                horizontalSpace(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current User', style: TextStyles.font15semiBold),
                    Text('What\'s on your mind?',
                        style: TextStyles.font12regular
                            .copyWith(color: ColorManager.normalGrey)),
                  ],
                ),
              ],
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
                  hintText: "Share your latest music riff, thoughts, or gear...",
                  hintStyle: TextStyles.font16Medium.copyWith(color: ColorManager.normalGrey),
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
                            fit: BoxFit.cover
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: InkWell(
                            onTap: () => setState(() => _selectedMediaUrl = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: ColorManager.primaryBlack.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: ColorManager.white, size: 20),
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
                            icon: const Icon(Icons.add_a_photo_outlined, color: ColorManager.primaryBlack),
                            iconSize: 30,
                            onPressed: _selectMedia,
                          ),
                          verticalSpace(4),
                          Text(
                            'Tap to add photo or video',
                            style: TextStyles.font14regular.copyWith(color: ColorManager.primaryBlack),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}