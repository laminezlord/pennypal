import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../app.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: padding, child: child));
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: PennyPalTheme.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(subtitle!, style: const TextStyle(color: PennyPalTheme.muted, height: 1.35)),
            ],
          ])),
          if (trailing != null) trailing!,
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PennyPalTheme.ink)),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ]);
}

class MoneyText extends StatelessWidget {
  final num amount;
  final double size;
  final Color? color;
  const MoneyText(this.amount, {super.key, this.size = 26, this.color});
  @override
  Widget build(BuildContext context) => Text(
        '₦${amount.toStringAsFixed(2)}',
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color ?? PennyPalTheme.ink),
      );
}

class GradientHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const GradientHeader({super.key, required this.eyebrow, required this.title, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [PennyPalTheme.navy, PennyPalTheme.navy2]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x180B1F3A), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow, style: const TextStyle(color: Color(0xFFBFD0E8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
            if (subtitle != null) ...[const SizedBox(height: 5), Text(subtitle!, style: const TextStyle(color: Color(0xFFD5E0EF)))],
          ])),
          if (trailing != null) trailing!,
        ]),
      );
}

class StatTile extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color accent;
  final bool showMoney;
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.accent = PennyPalTheme.sky, this.showMoney = true});
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent, size: 20)),
          const SizedBox(height: 13),
          Text(label, style: const TextStyle(color: PennyPalTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => Text(
                showMoney ? money(animatedValue) : animatedValue.round().toString(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PennyPalTheme.ink),
              ),
            ),
          ),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String actionLabel;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.actionLabel = 'Get started'});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: PennyPalTheme.sky.withValues(alpha: .09), shape: BoxShape.circle), child: Icon(icon, color: PennyPalTheme.sky, size: 28)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: PennyPalTheme.muted, height: 1.4)),
          if (action != null) ...[const SizedBox(height: 14), FilledButton(onPressed: action, child: Text(actionLabel))],
        ]),
      );
}

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});
  @override
  Widget build(BuildContext context) => const AppCard(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
}

final NumberFormat _moneyFormat = NumberFormat('#,##0.00');

String money(num value) => value < 0 ? '-₦${_moneyFormat.format(value.abs())}' : '₦${_moneyFormat.format(value)}';

/// Runs [callback] after the current frame and makes sure that frame happens.
///
/// A bare addPostFrameCallback waits for the next frame, and an idle Flutter
/// web app does not draw one until the user interacts again. That left lists
/// visibly stale after saving, editing or deleting records.
void afterNextFrame(FrameCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback(callback);
  WidgetsBinding.instance.scheduleFrame();
}

/// Reusable entrance motion for PennyPal's content screens.
/// Keeps movement subtle and consistent: fade + upward lift + tiny scale.
class MotionReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final double beginScale;

  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = 18,
    this.beginScale = .985,
  });

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total)..forward();
    final start = widget.delay.inMilliseconds / total.inMilliseconds;
    final end = 1.0;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: widget.beginScale, end: 1).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(scale: _scale, child: widget.child),
        ),
      );
}

/// Small tactile feedback for important cards and action tiles.
class MotionPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const MotionPress({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<MotionPress> createState() => _MotionPressState();
}

class _MotionPressState extends State<MotionPress> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: pressed ? .975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: widget.child,
        ),
      );
}
