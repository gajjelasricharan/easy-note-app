// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/note_model.dart';
import '../utils/app_theme.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final notesAsync = ref.watch(filteredNotesProvider(user.uid));
    final isDark = ref.watch(darkModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            if (_isSearching) _buildSearchBar(user.uid),
            Expanded(
              child: notesAsync.when(
                data: (notes) => _buildNoteGrid(notes, user.uid),
                loading: () => _buildLoadingGrid(),
                error: (e, _) => _buildError(e.toString()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(user.uid),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'easy note',
                  style: GoogleFonts.fraunces(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  _getGreeting(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Search button
          IconButton(
            onPressed: () => setState(() => _isSearching = !_isSearching),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearching),
                size: 22,
              ),
            ),
          ),
          // Archive button
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchiveScreen()),
            ),
            icon: const Icon(Icons.archive_outlined, size: 22),
          ),
          // Settings
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SearchBarWidget(
        onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
        onClear: () {
          ref.read(searchQueryProvider.notifier).state = '';
        },
      ),
    );
  }

  Widget _buildNoteGrid(List<NoteModel> notes, String uid) {
    if (notes.isEmpty) return _buildEmptyState();

    // Separate pinned
    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (pinned.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                'PINNED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: pinned.length,
              itemBuilder: (ctx, i) => NoteCard(
                note: pinned[i],
                index: i,
              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(
                duration: const Duration(milliseconds: 300),
              ).slideY(begin: 0.1, end: 0),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                'OTHERS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: unpinned.length,
            itemBuilder: (ctx, i) => NoteCard(
              note: unpinned[i],
              index: i + (pinned.length),
            ).animate(
              delay: Duration(milliseconds: i * 40),
            ).fadeIn(
              duration: const Duration(milliseconds: 300),
            ).slideY(begin: 0.1, end: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.softTan,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.sticky_note_2_outlined,
              size: 36,
              color: AppTheme.mediumGray,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (_, i) => _buildShimmerCard(i),
      ),
    );
  }

  Widget _buildShimmerCard(int i) {
    final heights = [120.0, 160.0, 100.0, 180.0, 140.0, 110.0];
    return Container(
      height: heights[i % heights.length],
      decoration: BoxDecoration(
        color: AppTheme.softTan,
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 1200.ms,
      color: AppTheme.warmWhite.withOpacity(0.6),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.warmGray),
            const SizedBox(height: 12),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(String uid) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        onPressed: () => _createNewNote(uid),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New note',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _createNewNote(String uid) async {
    final notesService = ref.read(notesServiceProvider);
    final note = await notesService.createNote(uid);

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => NoteEditorScreen(noteId: note.id),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
