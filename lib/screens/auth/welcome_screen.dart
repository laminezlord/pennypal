import 'package:flutter/material.dart';

import '../../app.dart';
import '../../widgets/penny_widgets.dart';

/// Simple public landing page. The only primary decisions are Sign in and
/// Create account, so a first-time user can understand the app immediately.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PennyPalTheme.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: _LandingBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 98, 18, 42),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Reveal(child: _Hero()),
                      const SizedBox(height: 58),
                      _Reveal(
                        delay: const Duration(milliseconds: 140),
                        child: _SectionHeading(
                          eyebrow: 'HOW IT WORKS',
                          title: 'Record. Plan. Save. Learn.',
                          subtitle: 'Four simple tools to help students understand where their money goes.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final cards = const [
                            _StepCard('01', Icons.receipt_long_rounded, 'Record', 'Add income and expenses in a few taps.'),
                            _StepCard('02', Icons.account_balance_wallet_outlined, 'Plan', 'Set monthly budgets and category limits.'),
                            _StepCard('03', Icons.savings_outlined, 'Save', 'Create goals and track your progress.'),
                            _StepCard('04', Icons.school_outlined, 'Learn', 'Understand your spending with reports and guidance.'),
                          ];
                          final cardHeight = wide ? 188.0 : 170.0;
                          final children = List<Widget>.generate(
                            cards.length,
                            (i) => _Reveal(
                              delay: Duration(milliseconds: 220 + (i * 80)),
                              child: SizedBox(height: cardHeight, child: cards[i]),
                            ),
                          );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < children.length; i++) ...[
                                      Expanded(child: children[i]),
                                      if (i != children.length - 1) const SizedBox(width: 12),
                                    ],
                                  ],
                                )
                              : Column(
                                  children: [
                                    for (var i = 0; i < children.length; i++) ...[
                                      children[i],
                                      if (i != children.length - 1) const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 58),
                      _Reveal(delay: const Duration(milliseconds: 420), child: _Features()),
                      const SizedBox(height: 58),
                      _Reveal(delay: const Duration(milliseconds: 500), child: _BottomCta()),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'PennyPal • Student finance learning & expense management',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: PennyPalTheme.muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                decoration: BoxDecoration(
                  color: PennyPalTheme.canvas.withValues(alpha: .95),
                  border: const Border(bottom: BorderSide(color: PennyPalTheme.line)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A0B1F3A), blurRadius: 18, offset: Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: const _Header(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _Reveal({required this.child, this.delay = Duration.zero});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = curved;
    _offset = Tween<Offset>(begin: const Offset(0, .045), end: Offset.zero).animate(curved);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

class _LandingBackdrop extends StatefulWidget {
  const _LandingBackdrop();

  @override
  State<_LandingBackdrop> createState() => _LandingBackdropState();
}

class _LandingBackdropState extends State<_LandingBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PennyPalTheme.canvas,
                    PennyPalTheme.sky.withValues(alpha: .045 + (.018 * t)),
                    PennyPalTheme.mint.withValues(alpha: .035 + (.014 * (1 - t))),
                    PennyPalTheme.canvas,
                  ],
                  stops: const [0, .28, .62, 1],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: _BubbleField()),
                  Positioned(
                    top: -130 + (18 * t),
                    right: -90 - (14 * t),
                    child: Container(
                      width: 330,
                      height: 330,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PennyPalTheme.sky.withValues(alpha: .055 + (.018 * t)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 420 - (20 * t),
                    left: -150 + (16 * t),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PennyPalTheme.mint.withValues(alpha: .035 + (.012 * (1 - t))),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}


class _BubbleField extends StatefulWidget {
  const _BubbleField();
  @override
  State<_BubbleField> createState() => _BubbleFieldState();
}

class _BubbleFieldState extends State<_BubbleField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const bubbles = <Map<String, double>>[
    {'x': .10, 'y': .18, 's': 18, 'p': .00},
    {'x': .28, 'y': .34, 's': 10, 'p': .18},
    {'x': .52, 'y': .12, 's': 14, 'p': .36},
    {'x': .78, 'y': .28, 's': 22, 'p': .52},
    {'x': .88, 'y': .56, 's': 11, 'p': .70},
    {'x': .64, 'y': .74, 's': 16, 'p': .86},
    {'x': .34, 'y': .82, 's': 12, 'p': .24},
    {'x': .08, 'y': .66, 's': 20, 'p': .62},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: bubbles.map((b) {
                final phase = (_controller.value + b['p']!) % 1.0;
                final lift = Curves.easeInOut.transform((phase < .5 ? phase : 1 - phase) * 2);
                final dx = (b['x']! * constraints.maxWidth) + (10 * (lift - .5));
                final dy = (b['y']! * constraints.maxHeight) - (42 * lift);
                final opacity = .10 + (.12 * lift);
                final size = b['s']! + (4 * lift);
                return Positioned(
                  left: dx,
                  top: dy,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PennyPalTheme.sky, width: 1.2),
                        color: Colors.white.withValues(alpha: .30),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Row(
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PennyPalLogo(size: compact ? 34 : 40),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
              ),
              child: const Text('Sign in'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
              ),
              child: const Text('Create account'),
            ),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PennyPalTheme.sky.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'BUILT FOR STUDENTS',
                style: TextStyle(
                  color: PennyPalTheme.sky,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Make your money\nmake more sense.',
              style: TextStyle(
                color: PennyPalTheme.ink,
                fontSize: 44,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.6,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Track spending, plan a budget, build savings goals and learn better money habits — all in one simple app.',
              style: TextStyle(color: PennyPalTheme.muted, fontSize: 16, height: 1.55),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Get started'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ],
        );

        final preview = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PennyPalTheme.line),
            boxShadow: const [
              BoxShadow(color: Color(0x120B1F3A), blurRadius: 28, offset: Offset(0, 14)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [PennyPalTheme.navy, PennyPalTheme.navy2]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVAILABLE BALANCE', style: TextStyle(color: Color(0xFFBFD0E8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    SizedBox(height: 7),
                    Text('₦245,800.00', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: _MiniStat('Income', '₦320,000', PennyPalTheme.mint)),
                  SizedBox(width: 10),
                  Expanded(child: _MiniStat('Expenses', '₦74,200', PennyPalTheme.sky)),
                ],
              ),
              const SizedBox(height: 14),
              const AppCard(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, color: PennyPalTheme.sky),
                    SizedBox(width: 10),
                    Expanded(child: Text('Budget usage', style: TextStyle(fontWeight: FontWeight.w800))),
                    Text('42%', style: TextStyle(fontWeight: FontWeight.w900, color: PennyPalTheme.sky)),
                  ],
                ),
              ),
            ],
          ),
        );

        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: copy),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: preview),
                ],
              )
            : Column(
                children: [
                  copy,
                  const SizedBox(height: 28),
                  preview,
                ],
              );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            FittedBox(alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900))),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  const _SectionHeading({required this.eyebrow, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: const TextStyle(color: PennyPalTheme.sky, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.25)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: PennyPalTheme.ink, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -.7)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 14, height: 1.5)),
        ],
      );
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;
  const _StepCard(this.number, this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: PennyPalTheme.navy, borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Text(number, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 11, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: PennyPalTheme.ink, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, height: 1.45)),
          ],
        ),
      );
}

class _Features extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 3 : 1;
            final items = [
              _Feature(Icons.receipt_long_rounded, 'Expense tracking', 'Record and manage everyday transactions.'),
              _Feature(Icons.pie_chart_outline_rounded, 'Budgets & alerts', 'Set limits and monitor your spending.'),
              _Feature(Icons.savings_outlined, 'Savings goals', 'Set targets and follow your progress.'),
              _Feature(Icons.insights_rounded, 'Reports & trends', 'See category and monthly spending patterns.'),
              _Feature(Icons.school_outlined, 'Financial learning', 'Learn practical money concepts for students.'),
              _Feature(Icons.auto_awesome_rounded, 'PennyPal Assistant', 'Ask budgeting and spending questions.'),
            ].asMap().entries.map((entry) => MotionReveal(
              delay: Duration(milliseconds: 80 + entry.key * 65),
              duration: const Duration(milliseconds: 480),
              offset: 12,
              beginScale: .985,
              child: entry.value,
            )).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Everything important, without the clutter.', style: TextStyle(color: PennyPalTheme.ink, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: columns == 1 ? 148 : 124,
                  children: items,
                ),
              ],
            );
          },
        ),
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Feature(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PennyPalTheme.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PennyPalTheme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: PennyPalTheme.sky.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: PennyPalTheme.sky, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: PennyPalTheme.ink, fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: PennyPalTheme.muted, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BottomCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [PennyPalTheme.navy, PennyPalTheme.navy2]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 650;
            final content = Column(
              crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                const Text('Ready to start?', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                const Text('Create your account and start with a clearer view of your money.', style: TextStyle(color: Color(0xFFD5E0EF), fontSize: 14, height: 1.45)),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: wide ? WrapAlignment.start : WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: FilledButton.styleFrom(backgroundColor: PennyPalTheme.sky, foregroundColor: Colors.white),
                  child: const Text('Create account'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x557FA9E8))),
                  child: const Text('Sign in'),
                ),
              ],
            );
            return wide
                ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: content), const SizedBox(width: 24), actions])
                : Column(children: [content, const SizedBox(height: 18), actions]);
          },
        ),
      );
}
