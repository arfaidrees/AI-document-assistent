import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/ask_response.dart';
import '../models/chat_message.dart';
import '../models/document_entry.dart';
import '../models/document_info.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/document_header.dart';
import '../widgets/typing_indicator.dart';

class DocumentAssistantScreen extends StatefulWidget {
  const DocumentAssistantScreen({super.key});

  @override
  State<DocumentAssistantScreen> createState() =>
      _DocumentAssistantScreenState();
}

class _DocumentAssistantScreenState extends State<DocumentAssistantScreen> {
  late final ApiService _apiService;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<SourceChunk> _latestSources = [];
  final List<DocumentEntry> _documents = [];

  DocumentInfo? _documentInfo;
  bool _uploading = false;
  bool _sending = false;
  String? _statusText;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: 'http://localhost:8000');
    _messages.add(
      ChatMessage(
        role: ChatRole.system,
        text: 'Upload a PDF to start asking questions about it.',
      ),
    );
    _loadDocuments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    debugPrint('[Screen] documents refresh started');
    try {
      final documents = await _apiService.fetchDocuments();
      if (!mounted) return;
      setState(() {
        _documents
          ..clear()
          ..addAll(documents);
      });
      debugPrint('[Screen] documents refresh completed (${documents.length})');
    } catch (_) {
      // Keep the UI usable even if the document list fetch fails.
      debugPrint('[Screen] documents refresh failed');
    }
  }

  Future<void> _pickAndUploadPdf() async {
    debugPrint('[Screen] upload button pressed');
    setState(() {
      _errorText = null;
      _statusText = null;
    });

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result.isEmpty) {
      debugPrint('[Screen] upload canceled or no file selected');
      return;
    }

    final file = result.single;
    debugPrint('[Screen] upload started: ${file.name}');
    setState(() {
      _uploading = true;
      _statusText = 'Uploading and processing document...';
    });

    try {
      final info = await _apiService.uploadPdf(file);
      debugPrint('[Screen] upload completed: ${info.filename}');
      setState(() {
        _documentInfo = info;
        _uploading = false;
        _statusText = 'Loaded ${info.filename}';
        _latestSources.clear();
      });
      await _loadDocuments();
      _scrollToBottom();
    } on ApiException catch (e) {
      setState(() {
        _uploading = false;
        _errorText = e.message;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _errorText = 'Upload failed: $e';
      });
    }
  }

  Future<void> _clearSession() async {
    if (_uploading || _sending) return;

    debugPrint('[Screen] clear action triggered');
    setState(() {
      _errorText = null;
      _statusText = 'Clearing session...';
    });

    try {
      debugPrint('[Screen] clear action issuing API request');
      await _apiService.clearSession();
      setState(() {
        _documentInfo = null;
        _statusText = null;
        _latestSources.clear();
        _documents.clear();
        _messages
          ..clear()
          ..add(
            ChatMessage(
              role: ChatRole.system,
              text: 'Upload a PDF to start asking questions about it.',
            ),
          );
      });
      _controller.clear();
      _scrollToBottom();
    } on ApiException catch (e) {
      setState(() {
        _errorText = e.message;
        _statusText = null;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Clear failed: $e';
        _statusText = null;
      });
    }
  }

  Future<void> _confirmAndClearSession() async {
    if (_uploading || _sending) return;

    await _clearSession();
  }

  Future<void> _sendQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending || _uploading) return;
    if (_documentInfo == null) {
      setState(() {
        _errorText = 'Please upload a PDF first.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _sending = true;
      _messages.add(ChatMessage(role: ChatRole.user, text: question));
      _messages.add(ChatMessage(role: ChatRole.assistant, text: ''));
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final response = await _apiService.askQuestion(question);
      setState(() {
        _latestSources
          ..clear()
          ..addAll(response.sources);
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            text: response.answer,
          ),
        );
        _sending = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _latestSources.clear();
        _messages.removeLast();
        _messages.add(ChatMessage(role: ChatRole.assistant, text: e.message));
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _latestSources.clear();
        _messages.removeLast();
        _messages.add(
          ChatMessage(role: ChatRole.assistant, text: 'Request failed: $e'),
        );
        _sending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument = _documentInfo != null;
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF111111), Color(0xFF050505)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const _AmbientGlow(
              top: -80,
              left: -60,
              size: 240,
              color: Color(0xFFFFFFFF),
              opacity: 0.08,
            ),
            const _AmbientGlow(
              top: 120,
              right: -40,
              size: 220,
              color: Color(0xFFFFFFFF),
              opacity: 0.05,
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: DocumentHeader(
                      documentInfo: _documentInfo,
                      isUploading: _uploading,
                      statusText: _statusText,
                      onUploadPressed: _pickAndUploadPdf,
                      onClearPressed: _confirmAndClearSession,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Document',
                            value: hasDocument
                                ? _documentInfo!.filename
                                : 'No PDF loaded',
                            icon: Icons.description_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Ready',
                            value: hasDocument ? 'Ask questions now' : 'Upload first',
                            icon: Icons.auto_awesome_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_documents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                      child: _DocumentListPreview(documents: _documents),
                    ),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: _ErrorBanner(message: _errorText!),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final content = _ChatPanel(
                            scrollController: _scrollController,
                            messages: _messages,
                            sending: _sending,
                            hasDocument: hasDocument,
                            latestSources: _latestSources,
                            buildEmptyState: () => _buildEmptyState(context),
                          );

                          if (!isWide) {
                            return content;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: content),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 340,
                                child: _SidebarPanel(
                                  documentInfo: _documentInfo,
                                  latestSources: _latestSources,
                                  documents: _documents,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  _ComposerBar(
                    controller: _controller,
                    onSend: _sendQuestion,
                    sending: _sending,
                    uploading: _uploading,
                    hasDocument: hasDocument,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'AI Document Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Upload a PDF to start asking questions.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'The assistant reads the document, retrieves the most relevant passages, and answers only from the uploaded PDFs.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _FeaturePill(text: 'PDF upload'),
                  _FeaturePill(text: 'Semantic retrieval'),
                  _FeaturePill(text: 'Source citations'),
                  _FeaturePill(text: 'Chat history'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.scrollController,
    required this.messages,
    required this.sending,
    required this.hasDocument,
    required this.latestSources,
    required this.buildEmptyState,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool sending;
  final bool hasDocument;
  final List<SourceChunk> latestSources;
  final Widget Function() buildEmptyState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          itemCount: messages.length + (sending ? 1 : 0) + (hasDocument ? 0 : 1),
          itemBuilder: (context, index) {
            if (!hasDocument && index == 0) {
              return buildEmptyState();
            }

            final adjustedIndex = hasDocument ? index : index - 1;
            if (sending && adjustedIndex == messages.length) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: TypingIndicator(),
              );
            }

            final message = messages[adjustedIndex];
            if (message.role == ChatRole.system) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return ChatBubble(
              message: message,
              sources: message.role == ChatRole.assistant && latestSources.isNotEmpty
                  ? latestSources
                      .map(
                        (source) =>
                            '${source.filename}${source.page != null ? ' • page ${source.page}' : ''}',
                      )
                      .toList()
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.onSend,
    required this.sending,
    required this.uploading,
    required this.hasDocument,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final bool uploading;
  final bool hasDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: hasDocument && !uploading && !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hasDocument
                      ? 'Ask a question about the document...'
                      : 'Upload a PDF first',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: uploading || sending ? null : onSend,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded),
                        SizedBox(width: 6),
                        Text('Send'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.documentInfo,
    required this.latestSources,
    required this.documents,
  });

  final DocumentInfo? documentInfo;
  final List<SourceChunk> latestSources;
  final List<DocumentEntry> documents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Context',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MiniInfoTile(
                    label: 'Document',
                    value: documentInfo?.filename ?? 'No PDF loaded',
                  ),
                  const SizedBox(height: 10),
                  _MiniInfoTile(
                    label: 'Pages',
                    value: documentInfo?.pages.toString() ?? '0',
                  ),
                  const SizedBox(height: 10),
                  _MiniInfoTile(
                    label: 'Chunks',
                    value: documentInfo?.chunks.toString() ?? '0',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Uploaded Files',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (documents.isEmpty)
                    Text(
                      'No files uploaded yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                    )
                  else
                    ...documents.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(
                            doc.page == null
                                ? doc.filename
                                : '${doc.filename} • page ${doc.page}',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Latest Sources',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (latestSources.isEmpty)
                    Text(
                      'Sources from the latest answer will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                    )
                  else
                    ...latestSources.map(
                      (source) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chunk ${source.chunk + 1}',
                                style: const TextStyle(
                                  color: Color(0xFFB9F7E9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                source.text,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentListPreview extends StatelessWidget {
  const _DocumentListPreview({required this.documents});

  final List<DocumentEntry> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: documents
            .map(
              (doc) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  doc.page == null ? doc.filename : '${doc.filename} • p${doc.page}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
