import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Opens a bottom sheet with a rich AI-generated explanation.
///
/// Features:
/// - Cache-first: stored explanation shown instantly; "Re-explain" forces a fresh AI answer.
/// - Markdown rendering via flutter_markdown — bold, headings, bullet lists all render correctly.
/// - Text-to-speech via flutter_tts — reads the explanation aloud; child can play/pause.
/// - Streaming word-reveal effect for a live "typewriter" feel.
/// This is the Android-exclusive explanation flow (SCRUM-527, SCRUM-547).
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
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
  State<_ExplanationSheetContent> createState() =>
      _ExplanationSheetContentState();
}

class _ExplanationSheetContentState extends State<_ExplanationSheetContent> {
  bool _loading = true;
  bool _fromCache = false;
  String _fullText = '';
  String _displayedText = '';
  String? _error;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  // Typewriter reveal
  Timer? _typeTimer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _load(force: false);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _load({required bool force}) async {
    _typeTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _displayedText = '';
      _charIndex = 0;
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
          _fullText = (res['explanation'] ?? '').toString();
          _fromCache = res['cached'] == true;
          _loading = false;
        });
        _startTypewriter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Oops! Nova couldn\'t load the explanation right now.\nCheck your internet and try again! 🌐';
          _loading = false;
        });
      }
    }
  }

  void _startTypewriter() {
    _charIndex = 0;
    _displayedText = '';
    _typeTimer = Timer.periodic(const Duration(milliseconds: 8), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_charIndex >= _fullText.length) {
        t.cancel();
        return;
      }
      final chunkEnd = (_charIndex + 4).clamp(0, _fullText.length);
      setState(() {
        _displayedText = _fullText.substring(0, chunkEnd);
        _charIndex = chunkEnd;
      });
    });
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      final textToSpeak = _fullText.replaceAll(RegExp(r'[#*_`~>]'), '').trim();
      if (textToSpeak.isEmpty) return;
      setState(() => _isSpeaking = true);
      await _tts.speak(textToSpeak);
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accentCyan]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Text('💡', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A0A3E))),
                  ),
                  // TTS button
                  if (!_loading && _error == null && _fullText.isNotEmpty)
                    IconButton(
                      onPressed: _toggleSpeech,
                      icon: Icon(
                        _isSpeaking
                            ? Icons.stop_circle_rounded
                            : Icons.volume_up_rounded,
                        color: _isSpeaking
                            ? AppTheme.accentOrange
                            : AppTheme.primary,
                        size: 28,
                      ),
                      tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Cache badge
            if (_fromCache && !_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⚡ Instant — saved explanation',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentMint,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito')),
                ),
              ),
            // TTS playing indicator
            if (_isSpeaking)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔊 ', style: TextStyle(fontSize: 14)),
                      Text(
                        'Nova is reading aloud...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentOrange,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Nova is thinking... 🤔',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('😕',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Markdown(
                          controller: scroll,
                          data: _displayedText,
                          selectable: true,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: Color(0xFF2D2D2D),
                              fontFamily: 'Nunito',
                            ),
                            h1: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A0A3E),
                              fontFamily: 'Nunito',
                            ),
                            h2: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A0A3E),
                              fontFamily: 'Nunito',
                            ),
                            h3: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontFamily: 'Nunito',
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A0A3E),
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF4A4A4A),
                            ),
                            listBullet: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: AppTheme.primary,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                    color: AppTheme.primary, width: 4),
                              ),
                            ),
                            code: const TextStyle(
                              fontFamily: 'monospace',
                              backgroundColor: Color(0xFFF5F5F5),
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
            ),
            // Bottom actions
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _load(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Ask Nova again ✨'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
