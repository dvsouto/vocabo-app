import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_app/vocabo_app.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncEngineProvider.notifier).start());
  }

  /// The open bottom sheet on phones, so closing the modal from its own
  /// buttons also dismisses the sheet.
  NavigatorState? _sheetNavigator;

  void _closeWordDetail() {
    ref.read(showWordDetailModalProvider.notifier).state = false;
    ref.read(selectedWordProvider.notifier).state = null;
  }

  void _closeAddWord() {
    ref.read(addWordNotifierProvider.notifier).reset();
    ref.read(showAddWordModalProvider.notifier).state = false;
  }

  /// On phones the word detail and add word modals open as bottom sheets,
  /// driven by the same providers as the desktop overlays.
  Future<void> _openSheet(WidgetBuilder builder, VoidCallback onClosed) async {
    if (_sheetNavigator != null) return;
    _sheetNavigator = Navigator.of(context);
    await showVocaboModal<void>(context: context, builder: builder);
    _sheetNavigator = null;
    if (mounted) onClosed();
  }

  void _dismissSheet() {
    final navigator = _sheetNavigator;
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  void _listenForSheets() {
    ref.listen(showWordDetailModalProvider, (_, show) {
      if (!context.isCompact) return;
      final word = ref.read(selectedWordProvider);
      if (show && word != null) {
        _openSheet((_) => WordDetailModal(userVocabulary: word), () {
          if (ref.read(showWordDetailModalProvider)) _closeWordDetail();
        });
      } else if (!show) {
        _dismissSheet();
      }
    });
    ref.listen(showAddWordModalProvider, (_, show) {
      if (!context.isCompact) return;
      if (show) {
        final term = ref.read(addWordInitialTermProvider);
        _openSheet(
          (_) => AddWordModal(initialTerm: term.isNotEmpty ? term : null),
          () {
            if (ref.read(showAddWordModalProvider)) _closeAddWord();
          },
        );
      } else {
        _dismissSheet();
      }
    });
  }

  Widget _buildContent(DashboardSection section) {
    return switch (section) {
      DashboardSection.flashcards => const FlashcardsContent(),
      DashboardSection.progress => const ProgressContent(),
      DashboardSection.settings => const SettingsContent(),
      DashboardSection.library => const LibraryContent(),
    };
  }

  Widget _buildModalOverlay(VoidCallback onClose) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClose,
        mouseCursor: SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyReminderServiceProvider);
    final section = ref.watch(dashboardSectionProvider);
    final showAddWordModal = ref.watch(showAddWordModalProvider);
    final initialTerm = ref.watch(addWordInitialTermProvider);
    final showWordDetail = ref.watch(showWordDetailModalProvider);
    final selectedWord = ref.watch(selectedWordProvider);

    final compact = context.isCompact;
    _listenForSheets();
    ref.listen(rejectedOpProvider, (_, rejected) {
      if (rejected == null) return;
      ref.read(rejectedOpProvider.notifier).state = null;
      if (rejected.errorCode == 'plan_limit' ||
          rejected.errorCode == 'daily_lookups') {
        ref.read(upgradePromptProvider.notifier).state = const UpgradeReason(
          UpgradeTrigger.manual,
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.syncChangeRejected)));
    });
    void select(int i) => ref.read(dashboardSectionProvider.notifier).state =
        DashboardSection.values[i];

    return Scaffold(
      backgroundColor: VocaboColors.surface,
      bottomNavigationBar: compact
          ? DashboardBottomBar(selectedIndex: section.index, onNavTap: select)
          : null,
      floatingActionButton:
          compact &&
              section == DashboardSection.library &&
              !showAddWordModal &&
              !showWordDetail
          ? FloatingActionButton(
              tooltip: context.l10n.sidebarAddNewWord,
              onPressed: () {
                ref.read(addWordInitialTermProvider.notifier).state = '';
                ref.read(showAddWordModalProvider.notifier).state = true;
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          if (compact) ...[
            SafeArea(bottom: false, child: _buildContent(section)),
            const SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(VocaboSpacing.md),
                  child: SyncIndicator(showLabel: true),
                ),
              ),
            ),
          ] else
            Row(
              children: [
                DashboardSidebar(
                  selectedIndex: section.index,
                  onNavTap: select,
                ),
                Expanded(child: _buildContent(section)),
              ],
            ),

          // Word detail modal overlay (phones use a bottom sheet)
          if (!compact && showWordDetail && selectedWord != null) ...[
            _buildModalOverlay(_closeWordDetail),
            WordDetailModal(userVocabulary: selectedWord),
          ],

          // Add word modal overlay (phones use a bottom sheet)
          if (!compact && showAddWordModal) ...[
            _buildModalOverlay(_closeAddWord),
            AddWordModal(
              initialTerm: initialTerm.isNotEmpty ? initialTerm : null,
            ),
          ],
        ],
      ),
    );
  }
}
