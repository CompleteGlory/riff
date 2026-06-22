import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/features/home/search/logic/search_cubit.dart';
import 'package:riff/features/home/search/logic/search_state.dart';
import 'package:riff/generated/l10n.dart';
import 'package:riff/core/widgets/app_error_widget.dart';

// ─── Static filter data ──────────────────────────────────────────────────────

const _genres = [
  'Rock',
  'Jazz',
  'Classical',
  'Hip-Hop',
  'Electronic',
  'Gospel',
  'Pop',
  'Metal',
  'R&B',
  'Country',
];

const _instruments = [
  'Guitar',
  'Piano',
  'Drums',
  'Oud',
  'Percussions',
  'Bass',
  'Violin',
  'Harp',
  'Hang',
  'Saxophone',
  'DJ',
  'Singer',
  'Listener',
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<SearchCubit>()..loadDiscover(),
      child: const _SearchBody(),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _controller = TextEditingController();
  bool _showInstruments = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              isDark: isDark,
              onChanged: (q) {
                context.read<SearchCubit>().onQueryChanged(q);
                setState(() {}); // rebuild to show/hide clear button
              },
              onClear: () {
                _controller.clear();
                setState(() {});
                context.read<SearchCubit>().loadDiscover();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_controller.text.isNotEmpty) {
                    context.read<SearchCubit>().onQueryChanged(
                      _controller.text,
                    );
                  } else {
                    context.read<SearchCubit>().loadDiscover();
                  }
                },
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFC6FF00)
                    : Colors.black,
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    if (state is SearchLoading) {
                      return _buildShimmer(isDark);
                    }
                    if (state is SearchDiscoverLoaded) {
                      return _DiscoverView(
                        state: state,
                        isDark: isDark,
                        showInstruments: _showInstruments,
                        onTabChanged: (v) =>
                            setState(() => _showInstruments = v),
                      );
                    }
                    if (state is SearchResultsLoaded) {
                      return _ResultsView(state: state, isDark: isDark);
                    }
                    if (state is SearchError) {
                      return AppErrorWidget(
                        message: state.message,
                        onRetry: () => context.read<SearchCubit>().loadDiscover(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return _PostGridShimmer(isDark: isDark);
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 15,
                color: isDark ? Colors.white : ColorManager.black,
              ),
              decoration: InputDecoration(
                hintText: S.of(context).searchHint,
                hintStyle: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF555555)
                      : const Color(0xFFAAAAAA),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF666666)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─── Discover view ────────────────────────────────────────────────────────────

class _DiscoverView extends StatefulWidget {
  final SearchDiscoverLoaded state;
  final bool isDark;
  final bool showInstruments;
  final ValueChanged<bool> onTabChanged;

  const _DiscoverView({
    required this.state,
    required this.isDark,
    required this.showInstruments,
    required this.onTabChanged,
  });

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  late String? _activeGenre = widget.state.activeGenre;
  late String? _activeInstrument = widget.state.activeInstrument;

  @override
  void didUpdateWidget(covariant _DiscoverView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeGenre != widget.state.activeGenre ||
        oldWidget.state.activeInstrument != widget.state.activeInstrument) {
      _activeGenre = widget.state.activeGenre;
      _activeInstrument = widget.state.activeInstrument;
    }
  }

  void _applyFilter({String? genre, String? instrument}) {
    setState(() {
      _activeGenre = genre;
      _activeInstrument = instrument;
    });
    context.read<SearchCubit>().loadDiscover(
      genre: genre,
      instrument: instrument,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipBg = widget.isDark
        ? const Color(0xFF252525)
        : const Color(0xFFEFEFEF);
    final hasFilter = _activeGenre != null || _activeInstrument != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle + clear
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _TabToggle(
                label: S.of(context).genresFilter,
                active: !widget.showInstruments,
                isDark: widget.isDark,
                onTap: () => widget.onTabChanged(false),
              ),
              const SizedBox(width: 14),
              _TabToggle(
                label: S.of(context).instrumentsFilter,
                active: widget.showInstruments,
                isDark: widget.isDark,
                onTap: () => widget.onTabChanged(true),
              ),
              const Spacer(),
              if (hasFilter)
                GestureDetector(
                  onTap: () => _applyFilter(),
                  child: Text(
                    S.of(context).clearFilter,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      color: ColorManager.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.showInstruments
                ? _instruments.length
                : _genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final label = widget.showInstruments
                  ? _instruments[i]
                  : _genres[i];
              final isActive = widget.showInstruments
                  ? _activeInstrument == label
                  : _activeGenre == label;

              return GestureDetector(
                onTap: () {
                  if (isActive) {
                    _applyFilter();
                  } else if (widget.showInstruments) {
                    _applyFilter(instrument: label);
                  } else {
                    _applyFilter(genre: label);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? ColorManager.accent : chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? ColorManager.accent
                          : widget.isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? ColorManager.black
                          : widget.isDark
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF444444),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Grid or empty state
        Expanded(
          child: widget.state.isLoadingPosts
              ? _PostGridShimmer(isDark: widget.isDark)
              : widget.state.posts.isEmpty
              ? _EmptyDiscover(
                  isDark: widget.isDark,
                  genre: _activeGenre,
                  instrument: _activeInstrument,
                )
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  itemCount: widget.state.posts.length,
                  itemBuilder: (context, i) {
                    final post = widget.state.posts[i];
                    return _PostThumbnail(
                      post: post,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: post),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Results view ─────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final SearchResultsLoaded state;
  final bool isDark;

  const _ResultsView({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasUsers = state.users.isNotEmpty;
    final hasPosts = state.posts.isNotEmpty;

    if (!hasUsers && !hasPosts) {
      return _EmptySearch(isDark: isDark, query: state.query);
    }

    return CustomScrollView(
      slivers: [
        if (hasUsers) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(label: S.of(context).peopleSection, isDark: isDark),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _UserTile(
                user: state.users[i],
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UserProfileScreen(userId: state.users[i].id),
                  ),
                ),
              ),
              childCount: state.users.length,
            ),
          ),
        ],
        if (hasPosts) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(label: S.of(context).postsSection, isDark: isDark),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1.5,
              mainAxisSpacing: 1.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PostThumbnail(
                post: state.posts[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: state.posts[i]),
                  ),
                ),
              ),
              childCount: state.posts.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _TabToggle({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active
              ? (isDark ? Colors.white : ColorManager.black)
              : (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : ColorManager.black,
        ),
      ),
    );
  }
}

class _PostGridShimmer extends StatelessWidget {
  final bool isDark;

  const _PostGridShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8);

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: 18,
      itemBuilder: (_, __) => Container(color: color),
    );
  }
}

class _UserTile extends StatelessWidget {
  final SearchUser user;
  final bool isDark;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isDark,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEEEEEE),
              ),
              child: user.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        MediaUrl.resolveOrEmpty(user.profileImageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 24,
                          color: Color(0xFF888888),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 24,
                      color: Color(0xFF888888),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : ColorManager.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (user.isPrivate)
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: isDark
                    ? const Color(0xFF555555)
                    : const Color(0xFFAAAAAA),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostThumbnail extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;

  const _PostThumbnail({required this.post, required this.onTap});

  @override
  State<_PostThumbnail> createState() => _PostThumbnailState();
}

class _PostThumbnailState extends State<_PostThumbnail> {
  VideoPlayerController? _controller;
  bool _thumbReady = false;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }


  @override
  void initState() {
    super.initState();
    final media = (widget.post.media ?? []).where((m) => m.isNotEmpty).toList();
    final effectiveMedia = media.isNotEmpty
        ? media
        : (widget.post.originalPost?.media ?? [])
              .where((m) => m.isNotEmpty)
              .toList();
    final firstMedia = effectiveMedia.isNotEmpty ? effectiveMedia.first : null;
    if (firstMedia != null && _isVideo(firstMedia)) {
      _loadThumb(MediaUrl.resolveOrEmpty(firstMedia));
    }
  }

  Future<void> _loadThumb(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      await c.seekTo(Duration.zero);
      if (mounted) {
        setState(() {
          _controller = c;
          _thumbReady = true;
        });
      } else {
        c.dispose();
      }
    } catch (_) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = (widget.post.media ?? []).where((m) => m.isNotEmpty).toList();
    final effectiveMedia = media.isNotEmpty
        ? media
        : (widget.post.originalPost?.media ?? [])
              .where((m) => m.isNotEmpty)
              .toList();
    final firstMedia = effectiveMedia.isNotEmpty ? effectiveMedia.first : null;
    final displayText = widget.post.content?.isNotEmpty == true
        ? widget.post.content!
        : (widget.post.originalPost?.content ?? '');

    Widget thumbnail;
    if (firstMedia == null) {
      thumbnail = Container(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        padding: EdgeInsets.all(6.r),
        child: Center(
          child: Text(
            displayText,
            style: TextStyles.font12Medium.copyWith(
              color: isDark ? const Color(0xFF888888) : ColorManager.darkGrey,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_isVideo(firstMedia)) {
      thumbnail = Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF1A1A1A)),
          if (_thumbReady && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
              size: 28,
            ),
          ),
        ],
      );
    } else {
      thumbnail = Image.network(
        MediaUrl.resolveOrEmpty(firstMedia),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: isDark
                    ? const Color(0xFF252525)
                    : const Color(0xFFE8E8E8),
              ),
        errorBuilder: (_, __, ___) => Container(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF888888),
            size: 20,
          ),
        ),
      );
    }

    final viewsCount = widget.post.viewsCount ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(fit: StackFit.expand, children: [
        thumbnail,
        if (viewsCount > 0)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 9, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    _fmtCount(viewsCount),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'GeneralSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyDiscover extends StatelessWidget {
  final bool isDark;
  final String? genre;
  final String? instrument;

  const _EmptyDiscover({required this.isDark, this.genre, this.instrument});

  @override
  Widget build(BuildContext context) {
    final hasFilter = genre != null || instrument != null;
    final filterLabel = genre ?? instrument ?? '';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
            ),
            child: Icon(
              hasFilter ? Icons.music_off_rounded : Icons.explore_outlined,
              size: 36,
              color: isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilter
                ? S.of(context).noPostsInCategory(filterLabel)
                : S.of(context).nothingToDiscoverYet,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : ColorManager.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              hasFilter
                  ? S.of(context).beFirstToPostInCategory
                  : S.of(context).followMorePeople,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF666666)
                    : const Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  final String query;

  const _EmptySearch({required this.isDark, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).noResultsForQuery(query),
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : ColorManager.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).tryDifferentName,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              height: 1.5,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

