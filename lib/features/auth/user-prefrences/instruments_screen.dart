import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/selected_chip.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/selection_card.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/step_indicator.dart';
import 'package:riff/features/auth/user-prefrences/genres_screen.dart';
import 'package:riff/generated/l10n.dart';

class InstrumentsScreen extends StatefulWidget {
  /// When provided, forwarded to GenresScreen so the two-step picker
  /// returns to the caller instead of pushing to signup.
  final void Function(List<String> instruments, List<String> genres)? onFinish;

  const InstrumentsScreen({super.key, this.onFinish});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  final Set<int> _selected = {};

  void _toggle(int i) => setState(() {
        _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
      });

  void _continue() => _goToGenres(
        _selected.isEmpty ? [] : _selected.map((i) => instruments[i].name).toList(),
      );

  void _goToGenres(List<String> selected) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => GenresScreen(
          instruments: selected,
          onFinish: widget.onFinish,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(24),

              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StepIndicator(current: 0, total: 2),
                  Text(
                    s.step1Of2,
                    style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _goToGenres([]),
                    child: Text(
                      s.skipBtn,
                      style: TextStyles.font14Medium.copyWith(
                        color: ColorManager.lightGrey,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(28),

              Text(S.of(context).whatDoYouPlay, style: TextStyles.font28Bold),
              verticalSpace(8),
              Text(
                s.selectInstruments,
                style: TextStyles.font16Medium.copyWith(
                  color: ColorManager.lightGrey,
                ),
              ),
              verticalSpace(24),

              if (_selected.isNotEmpty) ...[
                SelectedChip(count: _selected.length),
                verticalSpace(16),
              ],

              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: instruments.length,
                  itemBuilder: (_, i) => SelectionCard(
                    name: instruments[i].name,
                    image: instruments[i].image,
                    isSelected: _selected.contains(i),
                    onTap: () => _toggle(i),
                  ),
                ),
              ),
              verticalSpace(16),

              AppButton(
                onPressed: _selected.isEmpty ? () {} : _continue,
                text: s.continueBtn,
                isWhite: false,
              ),
              verticalSpace(16),
            ],
          ),
        ),
      ),
    );
  }
}