import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class LearningScreen extends StatefulWidget {
  /// Changes whenever the Learn tab is opened so admin-published lessons appear.
  final int refreshSignal;
  const LearningScreen({super.key, this.refreshSignal = 0});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  List<dynamic> lessons = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(LearningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal > 0 && widget.refreshSignal != oldWidget.refreshSignal) load();
  }

  Future<void> load() async {
    try {
      final x = await PennyPalService.lessons();
      if (mounted) setState(() => lessons = x);
    } catch (_) {
      // Keep the screen usable if the cloud is temporarily unavailable.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final list = lessons.where((x) => '${x['title']} ${x['topic']} ${x['body']}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money school', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            const GradientHeader(
              eyebrow: 'LEARN • APPLY • REPEAT',
              title: 'Financial basics, without the jargon.',
              subtitle: 'Short lessons designed for everyday student decisions.',
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search lessons'),
            ),
            const SizedBox(height: 16),
            if (loading)
              const LoadingCard()
            else if (list.isEmpty)
              EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No lessons found',
                message: query.trim().isEmpty ? 'Lessons could not be loaded. Pull down to try again.' : 'Try a different topic.',
              ),
            ...list.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MotionReveal(
                  delay: Duration(milliseconds: 70 + e.key * 55),
                  child: _LessonCard(index: e.key, x: e.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final int index;
  final dynamic x;
  const _LessonCard({required this.index, required this.x});

  @override
  Widget build(BuildContext context) {
    final video = '${x['video_url'] ?? ''}'.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('${x['title']}', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${x['topic']} • ${x['difficulty']}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if (video.isNotEmpty) ...[
                    _LessonVideo(url: video),
                    const SizedBox(height: 16),
                  ],
                  Text('${x['body']}', style: const TextStyle(height: 1.55)),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
        ),
      ),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: PennyPalTheme.mint.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
              child: Center(child: Text('${(index + 1).toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w900, color: PennyPalTheme.mint))),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${x['title']}', style: const TextStyle(fontWeight: FontWeight.w900))),
                      if (video.isNotEmpty) const Icon(Icons.play_circle_outline_rounded, color: PennyPalTheme.sky, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${x['topic']} • ${x['difficulty']}', style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('${x['body']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: PennyPalTheme.muted, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: PennyPalTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _LessonVideo extends StatefulWidget {
  final String url;
  const _LessonVideo({required this.url});
  @override
  State<_LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<_LessonVideo> {
  late final VideoPlayerController controller;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => failed = true);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Container(
        width: double.infinity,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: PennyPalTheme.canvas, borderRadius: BorderRadius.circular(16)),
        child: const Text('This lesson video could not be loaded.', style: TextStyle(color: PennyPalTheme.muted)),
      );
    }
    if (!controller.value.isInitialized) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio, child: VideoPlayer(controller)),
          Material(
            color: Colors.black26,
            shape: const CircleBorder(),
            child: IconButton(
              color: Colors.white,
              iconSize: 34,
              onPressed: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
              icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
