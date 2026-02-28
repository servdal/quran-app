import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/widgets/ayah_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PageViewScreen extends StatefulWidget {
  const PageViewScreen({
    super.key,
    this.initialPage = 1,
    this.initialSurahId,
    this.initialAyahNumber,
  });

  final int initialPage;
  final int? initialSurahId;
  final int? initialAyahNumber;

  @override
  State<PageViewScreen> createState() => _PageViewScreenState();
}

class _PageViewScreenState extends State<PageViewScreen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_currentPage - 604'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 604, 
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
                  final isInitialTargetPage = pageNumber == widget.initialPage;
                  return _QuranPageWidget(
                    pageNumber: pageNumber,
                    targetSurahId:
                        isInitialTargetPage ? widget.initialSurahId : null,
                    targetAyahNumber:
                        isInitialTargetPage ? widget.initialAyahNumber : null,
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                  });
                },
              ),
            ),
            _buildPageControls(),
          ],
        )
      ),
    );
  }

  Widget _buildPageControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text(' '),
            onPressed: _currentPage < 604
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text(' '),
            onPressed: _currentPage > 1
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
          ),
          
        ],
      ),
    );
  }
}

class _QuranPageWidget extends ConsumerStatefulWidget {
  const _QuranPageWidget({
    required this.pageNumber,
    this.targetSurahId,
    this.targetAyahNumber,
  });

  final int pageNumber;
  final int? targetSurahId;
  final int? targetAyahNumber;

  @override
  ConsumerState<_QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends ConsumerState<_QuranPageWidget> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _didAutoScroll = false;

  void _jumpToTargetAyahIfNeeded(List<Ayah> ayahs) {
    if (_didAutoScroll ||
        widget.targetSurahId == null ||
        widget.targetAyahNumber == null) {
      return;
    }

    final targetIndex = ayahs.indexWhere(
      (ayah) =>
          ayah.surahId == widget.targetSurahId &&
          ayah.number == widget.targetAyahNumber,
    );

    if (targetIndex < 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached || _didAutoScroll) {
        return;
      }

      _itemScrollController.jumpTo(
        index: targetIndex,
        alignment: 0.1,
      );
      _didAutoScroll = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageDataAsync = ref.watch(pageAyahsProvider(widget.pageNumber));

    return pageDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, stack) =>
              Center(child: Text('Gagal memuat halaman ${widget.pageNumber}')),
      data: (ayahs) {
        _jumpToTargetAyahIfNeeded(ayahs);

        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: ayahs.length,
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            final bool isFirstAyahInSurah = ayah.number == 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isFirstAyahInSurah)
                  _SurahHeader(surahName: ayah.surahName),
                AyahWidget(
                  ayah: ayah,
                  viewType: BookmarkViewType.page,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          surahName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
