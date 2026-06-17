// instruments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/selected_chip.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/selection_card.dart';
import 'package:riff/features/auth/user-prefrences/UI/widgets/step_indicator.dart';
import 'package:riff/features/auth/user-prefrences/data/models/genre.dart';
import 'package:riff/features/auth/user-prefrences/data/models/instrument.dart';
import 'package:riff/generated/l10n.dart';

final List<InstrumentModel> instruments = [
  InstrumentModel(name: 'Guitar', image: 'assets/images/electric-guitar.png'),
  InstrumentModel(name: 'Piano', image: 'assets/images/piano.png'),
  InstrumentModel(name: 'Drums', image: 'assets/images/drum.png'),
  InstrumentModel(name: 'Oud', image: 'assets/images/saz.png'),
  InstrumentModel(name: 'Percussions', image: 'assets/images/dholak.png'),
  InstrumentModel(name: 'Bass', image: 'assets/images/electric-guitar (1).png'),
  InstrumentModel(name: 'Violin', image: 'assets/images/violin.png'),
  InstrumentModel(name: 'Harp', image: 'assets/images/harp.png'),
  InstrumentModel(name: 'Hang', image: 'assets/images/hang.png'),
  InstrumentModel(name: 'Saxophone', image: 'assets/images/saxophone.png'),
  InstrumentModel(name: 'DJ', image: 'assets/images/saxophone.png'),
  InstrumentModel(
    name: 'Sound Engineer',
    image: 'assets/images/sound-mixer.png',
  ),
  InstrumentModel(name: 'Singer', image: 'assets/images/microphone.png'),
  InstrumentModel(name: 'Listener', image: 'assets/images/headphones.png'),
];

final List<GenreModel> genres = [
  GenreModel(name: 'Rock', image: 'assets/images/rock-and-roll.png'),
  GenreModel(name: 'Jazz', image: 'assets/images/jazz.png'),
  GenreModel(name: 'Classical', image: 'assets/images/conductor.png'),
  GenreModel(name: 'Hip-Hop', image: 'assets/images/poster.png'),
  GenreModel(name: 'Electronic', image: 'assets/images/techno.png'),
  GenreModel(name: 'Gospel', image: 'assets/images/choir.png'),
  GenreModel(name: 'Pop', image: 'assets/images/kpop.png'),
  GenreModel(name: 'Metal', image: 'assets/images/rock.png'),
];

class GenresScreen extends StatefulWidget {
  final List<String> instruments;

  const GenresScreen({super.key, required this.instruments});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  final Set<int> _selected = {};

  void _toggle(int i) => setState(() {
    _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
  });

  void _finish() {
    if (_selected.isEmpty) return;
    final selectedGenres = _selected.map((i) => genres[i].name).toList();
    context.pushNamed(
      Routes.signup,
      arguments: {'instruments': widget.instruments, 'genres': selectedGenres},
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: ColorManager.lighterGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16.r,
                        color: ColorManager.primaryBlack,
                      ),
                    ),
                  ),
                  StepIndicator(current: 1, total: 2),
                  Text(
                    s.step2Of2,
                    style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
                ],
              ),
              verticalSpace(28),

              Text(S.of(context).whatDoYouListenTo, style: TextStyles.font28Bold),
              verticalSpace(8),
              Text(
                s.selectGenres,
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
                  itemCount: genres.length,
                  itemBuilder: (_, i) => SelectionCard(
                    name: genres[i].name,
                    image: genres[i].image,
                    isSelected: _selected.contains(i),
                    onTap: () => _toggle(i),
                  ),
                ),
              ),
              verticalSpace(16),

              AppButton(
                onPressed: _finish,
                text: s.getStarted,
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
