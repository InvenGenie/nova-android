import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Opens a bottom sheet that shows an AI-generated explanation.
///
/// Cache-first: a stored explanation (server + local) is shown immediately;
/// the student can press "Re-explain" to force a fresh AI answer.
/// This is the Android-exclusive explanation flow (SCRUM-527).
void showExplanationSheet({
  required BuildContext context,
  required ApiService api,
  required String username,
  required String title,
  required String kind,
  String? topic,
  String? subject,
  String? chapter,
  String? question,
  String? correctOption,
  String? class_,
  String? board,
  String? publication,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ExplanationSheetContent(
      api: api,
      username: username,
      title: title,
      kind: kind,
      topic: topic,
      subject: subject,
      chapter: chapter,
      question: question,
      correctOption: correctOption,
      class_: class_,
      board: board,
      publication: publication,
    ),
  );
}

class _ExplanationSheetContent extends StatefulWidget {
  final ApiService api;
  final String username;
  final String title;
  final String kind;
  final String? topic;
  final String? subject;
  final String? chapter;
  final String? question;
  final String? correctOption;
  final String? class_;
  final String? board;
  final String? publication;

  const _ExplanationSheetContent({
    required this.api,
    required this.username,
    required this.title,
    required this.kind,
    this.topic,
    this.subject,
    this.chapter,
    this.question,
    this.correctOption,
    this.class_,
    this.board,
    this.publication,
  });

  @override
  State<_ExplanationSheetContent> createState() => _ExplanationSheetContentState();
}

class _ExplanationSheetContentState extends State<_ExplanationSheetContent> {
  bool _loading = true;
  bool _fromCache = false;
  String _text = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(force: false);
  }

  Future<void> _load({required bool force}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.getExplanation(
        username: widget.username,
        kind: widget.kind,
        topic: widget.topic,
        subject: widget.subject,
        chapter: widget.chapter,
        question: widget.question,
        correctOption: widget.correctOption,
        class_: widget.class_,
        board: widget.board,
        publication: widget.publication,
        force: force,
      );
      if (mounted) {
        setState(() {
          _text = (res['explanation'] ?? '').toString();
          _fromCache = res['cached'] == true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fromCache && !_loading)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Saved explanation',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentMint,
                        fontWeight: FontWeight.w700)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey)),
                        )
                      : SingleChildScrollView(
                          controller: scroll,
                          child: Text(_text,
                              style: const TextStyle(fontSize: 15, height: 1.6)),
                        ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _load(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Re-explain (new answer)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
