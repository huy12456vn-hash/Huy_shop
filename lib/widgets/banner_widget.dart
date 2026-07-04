import 'dart:async';

import 'package:flutter/material.dart';

class BannerWidget extends StatefulWidget {
  final List<String> images;
  final double height;

  const BannerWidget({
    super.key,
    required this.images,
    this.height = 160,
  });

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  static const double _borderRadius = 20;
  static const double _indicatorHeight = 6;
  static const double _indicatorActiveWidth = 18;
  static const double _indicatorInactiveWidth = 6;

  static const Duration _autoScrollDuration = Duration(seconds: 5);
  static const Duration _pageAnimationDuration = Duration(milliseconds: 500);
  static const Duration _indicatorAnimationDuration =
      Duration(milliseconds: 300);

  final PageController _pageController =
      PageController(viewportFraction: 1.0);

  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.images.length <= 1) return;

    _timer?.cancel();
    _timer = null;

    _timer = Timer.periodic(
      _autoScrollDuration,
      (_) {
        if (mounted) {
          _goToNextPage();
        }
      },
    );
  }

  void _goToNextPage() {
    if (!mounted || widget.images.length <= 1) return;

    final nextPage = (_currentIndex + 1) % widget.images.length;

    _pageController.animateToPage(
      nextPage,
      duration: _pageAnimationDuration,
      curve: Curves.easeInOut,
    ).catchError((error) {
      // Xử lý nếu animation thất bại
      debugPrint('Banner animation error: $error');
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Reset timer sau khi người dùng vuốt (đợi 1 giây)
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  Widget _buildIndicator() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.images.length,
          (index) {
            final isActive = index == _currentIndex;

            return AnimatedContainer(
              duration: _indicatorAnimationDuration,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive
                  ? _indicatorActiveWidth
                  : _indicatorInactiveWidth,
              height: _indicatorHeight,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white70
                    : Colors.white30,
                borderRadius:
                    BorderRadius.circular(_indicatorHeight / 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner(String image) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          image,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: _onPageChanged,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              return _buildBanner(widget.images[index]);
            },
          ),
          _buildIndicator(),
        ],
      ),
    );
  }
}