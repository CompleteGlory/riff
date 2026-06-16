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

class InstrumentsScreen extends StatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  final Set<int> _selected = {};

  void _toggle(int i) => setState(() {
        _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
      });

  void _continue() {
  if (_selected.isEmpty) return;
  final selectedInstruments = _selected.map((i) => instruments[i].name).toList();
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, a, __) => GenresScreen(instruments: selectedInstruments),
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
                    'Step 1 of 2',
                    style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
                ],
              ),
              verticalSpace(28),

              Text('What do you play?', style: TextStyles.font28Bold),
              verticalSpace(8),
              Text(
                'Select the instruments you play.\nPick as many as you like.',
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
                onPressed: _continue,
                text: 'Continue',
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