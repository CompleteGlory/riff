import 'package:flutter/material.dart';

/// A page route that combines a gentle slide-up with a fade-in.
/// Use this instead of [MaterialPageRoute] for a more polished feel.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            // Outgoing screen fades out and slides left slightly
            final fadeOut = Tween<double>(begin: 1.0, end: 0.94).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
            );

            // Incoming screen slides up from 4% below
            final slideIn = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            final fadeIn = CurvedAnimation(parent: animation, curve: Curves.easeOut);

            return FadeTransition(
              opacity: fadeOut,
              child: SlideTransition(
                position: slideIn,
                child: FadeTransition(
                  opacity: fadeIn,
                  child: child,
                ),
              ),
            );
          },
        );
}
