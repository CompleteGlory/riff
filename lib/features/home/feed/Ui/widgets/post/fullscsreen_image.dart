// Fullscreen Image Viewer — supports single image or swipeable gallery
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_constants.dart';

class FullScreenImage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  /// Convenience constructor for a single image URL.
  FullScreenImage.single({super.key, required String imageUrl})
      : images = [imageUrl],
        initialIndex = 0;

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _resolve(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.apiBASEURL}$url';

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  _resolve(widget.images[i]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 48.h,
            right: 16.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Page indicator (only shown when > 1 image)
          if (total > 1)
            Positioned(
              bottom: 32.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  total,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: i == _currentIndex ? 18.w : 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),

          // Counter badge
          if (total > 1)
            Positioned(
              top: 52.h,
              left: 20.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_currentIndex + 1} / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
