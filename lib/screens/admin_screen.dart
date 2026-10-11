import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app.dart';
import '../services/pennypal_service.dart';
import '../widgets/penny_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> support = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        PennyPalService.adminUsers(),
        PennyPalService.adminSupport(),
      ]);
      if (!mounted) return;
      setState(() {
        users = results[0];
        support = results[1];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin data could not be loaded: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin centre', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                MotionReveal(
                  delay: const Duration(milliseconds: 40),
                  child: const GradientHeader(
                    eyebrow: 'PENNYPAL ADMIN',
                    title: 'Keep the learning experience healthy.',
                    subtitle: 'Manage students, support requests and learning content from one place.',
                  ),
                ),
                const SizedBox(height: 16),
                MotionReveal(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Students',
                          value: users.where((u) => '${u['Role'] ?? u['role'] ?? 'student'}'.toLowerCase() != 'admin').length,
                          icon: Icons.people_outline,
                          accent: PennyPalTheme.sky,
                          showMoney: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Support requests',
                          value: support.length,
                          icon: Icons.support_agent,
                          accent: PennyPalTheme.mint,
                          showMoney: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionTitle('Support queue'),
                    Text('${support.length} total', style: const TextStyle(color: PennyPalTheme.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                if (support.isEmpty)
                  const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No support requests',
                    message: 'Support requests will appear here when students contact support.',
                  )
                else
                  ...support.take(10).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MotionReveal(
                        delay: Duration(milliseconds: 220 + support.indexOf(item) * 50),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: PennyPalTheme.mint.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(Icons.support_agent, color: PennyPalTheme.mint),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['Subject'] ?? 'Support request'}',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['Message'] ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: PennyPalTheme.muted, height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PennyPalTheme.mint.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${item['Status'] ?? 'open'}',
                                  style: const TextStyle(color: PennyPalTheme.mint, fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                MotionReveal(
                  delay: const Duration(milliseconds: 360),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Learning content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      TextButton.icon(
                        onPressed: _addLesson,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add lesson'),
                      ),
                    ],
                  ),
                ),
                MotionReveal(
                  delay: const Duration(milliseconds: 410),
                  child: const AppCard(
                    child: Text(
                      'Create concise, beginner-friendly financial lessons and optionally attach a short video. Students can watch the lesson directly inside Money School.',
                      style: TextStyle(color: PennyPalTheme.muted, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _addLesson() async {
    final title = TextEditingController();
    final topic = TextEditingController();
    final body = TextEditingController();
    String difficulty = 'Beginner';
    XFile? video;
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialog) => AlertDialog(
          title: const Text('Create learning lesson', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: title, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Lesson title', hintText: 'e.g. Building your first budget')),
                  const SizedBox(height: 10),
                  TextField(controller: topic, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Topic', hintText: 'e.g. Budgeting basics')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    items: const ['Beginner', 'Intermediate', 'Advanced'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                    onChanged: uploading ? null : (x) => setDialog(() => difficulty = x ?? difficulty),
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: body,
                    minLines: 5,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(labelText: 'Lesson body', hintText: 'Explain the concept in a clear, student-friendly way.'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
                            if (picked != null && dialog.mounted) setDialog(() => video = picked);
                          },
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(video == null ? 'Attach lesson video (optional)' : 'Video selected: ${video!.name}'),
                  ),
                  if (video != null) ...[
                    const SizedBox(height: 6),
                    const Text('A short MP4/MOV lesson works well for mobile and web playback.', style: TextStyle(color: PennyPalTheme.muted, fontSize: 11)),
                  ],
                  if (uploading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 6),
                    const Text('Uploading lesson video…', style: TextStyle(color: PennyPalTheme.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: uploading ? null : () => Navigator.pop(dialog), child: const Text('Cancel')),
            FilledButton(
              onPressed: uploading
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialog).showSnackBar(const SnackBar(content: Text('Add a title and lesson body first.')));
                        return;
                      }
                      setDialog(() => uploading = true);
                      try {
                        await PennyPalService.adminAddLesson(
                          title: title.text,
                          topic: topic.text,
                          body: body.text,
                          difficulty: difficulty,
                          video: video,
                        );
                        if (!dialog.mounted) return;
                        Navigator.pop(dialog);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) load();
                        });
                      } catch (e) {
                        if (dialog.mounted) {
                          setDialog(() => uploading = false);
                          ScaffoldMessenger.of(dialog).showSnackBar(SnackBar(content: Text('Could not add lesson: $e')));
                        }
                      }
                    },
              child: const Text('Publish lesson'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    topic.dispose();
    body.dispose();
  }
}
