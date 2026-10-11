import 'package:flutter/material.dart';
import '../../app.dart';
import '../../services/pennypal_service.dart';
import '../../widgets/penny_widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantMarkdown extends StatelessWidget {
  final String text;
  const _AssistantMarkdown({required this.text});

  List<TextSpan> _inline(String value) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var last = 0;
    for (final match in pattern.allMatches(value)) {
      if (match.start > last) spans.add(TextSpan(text: value.substring(last, match.start)));
      final bold = match.group(1);
      final code = match.group(2);
      spans.add(TextSpan(
        text: bold ?? code ?? '',
        style: TextStyle(
          fontWeight: bold != null ? FontWeight.w800 : FontWeight.w700,
          fontFamily: code != null ? 'monospace' : null,
        ),
      ));
      last = match.end;
    }
    if (last < value.length) spans.add(TextSpan(text: value.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final rawLines = text.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];
    for (final raw in rawLines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 7));
        continue;
      }
      final clean = line.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      final heading = clean != line;
      final bullet = clean.startsWith('- ') || clean.startsWith('* ');
      final numbered = RegExp(r'^\d+[.)]\s+').hasMatch(clean);
      final display = bullet
          ? '• ${clean.substring(2)}'
          : numbered
              ? clean
              : clean;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: PennyPalTheme.ink,
                fontSize: heading ? 16 : 14,
                height: 1.45,
                fontWeight: heading ? FontWeight.w900 : FontWeight.w400,
              ),
              children: _inline(display),
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}


class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 2, bottom: 12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = .25 + (_controller.value * .75);
            return Opacity(opacity: opacity, child: child);
          },
          child: const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PennyPalTheme.sky,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantScreenState extends State<AssistantScreen> {
  final q = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, String>> chat = [];
  bool busy = false;

  Future<void> ask([String? preset]) async {
    final text = (preset ?? q.text).trim();
    if (text.isEmpty || busy || !mounted) return;

    setState(() {
      chat.add({'who': 'me', 'text': text});
      busy = true;
    });
    q.clear();

    try {
      final result = await PennyPalService.assistant(text);
      if (!mounted) return;
      setState(() {
        chat.add({
          'who': 'ai',
          'text': '${result['answer']}',
          'source': '${result['source'] ?? 'educational-fallback'}',
          'model': '${result['model'] ?? ''}',
        });
      });
      afterNextFrame((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          chat.add({
            'who': 'ai',
            'text': 'I could not respond right now. You can still use your budget, goals and transaction tools.',
            'source': 'assistant',
          });
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    q.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'PennyPal AI',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: PennyPalTheme.mint.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'AI Assistant',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  if (chat.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PennyPalTheme.navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: PennyPalTheme.mint, size: 28),
                          SizedBox(height: 14),
                          Text(
                            'A calmer way to think about money.',
                            style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Ask about budgets, saving, needs vs wants, or how to use your PennyPal data.',
                            style: TextStyle(color: Color(0xFFD5E0EF), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'How do I make a budget?',
                        'How can I save consistently?',
                        'What is a need vs a want?',
                      ].map((x) => ActionChip(label: Text(x), onPressed: () => ask(x))).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  ...chat.map(
                    (m) => Align(
                      alignment: m['who'] == 'me' ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: m['who'] == 'me' ? PennyPalTheme.navy : Colors.white,
                          border: Border.all(color: PennyPalTheme.line),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m['who'] == 'ai')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'PennyPal AI',
                                  style: const TextStyle(
                                    color: PennyPalTheme.mint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (m['who'] == 'ai')
                              _AssistantMarkdown(text: '${m['text']}')
                            else
                              Text(
                                '${m['text']}',
                                style: const TextStyle(color: Colors.white, height: 1.35),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (busy) const _ThinkingBubble(),
                ],
              ),
            ),
            // The keyboard can leave only a very small viewport on phones.
            // Keep the composer compact so it never overflows when the IME opens.
            Builder(
              builder: (context) {
                final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
                return SafeArea(
                  top: false,
                  bottom: !keyboardOpen,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, keyboardOpen ? 2 : 8, 12, keyboardOpen ? 2 : 12),
                    child: SizedBox(
                      height: keyboardOpen ? 52 : 58,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: q,
                              onSubmitted: (_) => ask(),
                              textInputAction: TextInputAction.send,
                              decoration: const InputDecoration(
                                hintText: 'Ask PennyPal...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: busy ? null : ask,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
}
