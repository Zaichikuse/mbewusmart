import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';

class AiAssistantTab extends StatefulWidget {
  final bool isChichewa;
  final DiagnosisResult? initialDiagnosis;
  final bool floatingMode;
  final VoidCallback? onClose;
  final String? pageContext;

  const AiAssistantTab({
    super.key,
    required this.isChichewa,
    this.initialDiagnosis,
    this.floatingMode = false,
    this.onClose,
    this.pageContext,
  });

  @override
  State<AiAssistantTab> createState() => _AiAssistantTabState();
}

class _AiAssistantTabState extends State<AiAssistantTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiAssistantService _assistantService;

  List<AiChatMessage> _messages = [];
  DiagnosisResult? _selectedDiagnosis;
  bool _isLoading = false;
  late final String _languageCode;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _assistantService = di.sl<AiAssistantService>();
    _languageCode = widget.isChichewa ? 'ny' : 'en';
    final authState = context.read<AuthBloc>().state;
    _currentUserId = authState.user?.id;
    _currentUserName = authState.user?.fullName;
    _selectedDiagnosis = widget.initialDiagnosis;
    _messages = _assistantService.loadHistory(
      _languageCode,
      userId: _currentUserId,
    );

    if (_messages.isEmpty) {
      final diagnosisState = context.read<DiagnosisBloc>().state;
      final latestDiagnosis = diagnosisState is DiagnosisHistoryLoaded
          ? diagnosisState.history
                .where((d) =>
                    _currentUserId == null || d.userId == _currentUserId)
                .cast<DiagnosisResult?>()
                .firstWhere((d) => d != null, orElse: () => null)
          : null;

      _messages = [
        AiChatMessage(
          role: 'assistant',
          text: _assistantService.buildPersonalizedGreeting(
            isChichewa: widget.isChichewa,
            userName: _currentUserName,
            previousMessages: 0,
            latestDiagnosisName: latestDiagnosis == null
                ? null
                : (widget.isChichewa
                      ? latestDiagnosis.diagnosisNameChichewa
                      : latestDiagnosis.diagnosisName),
          ),
          timestamp: DateTime.now(),
          languageCode: _languageCode,
          diagnosisId: latestDiagnosis?.id,
        ),
      ];
    }

    if (context.read<LocationBloc>().state is! LocationLoaded) {
      context.read<LocationBloc>().add(LocationGetCurrent());
    }

    if (context.read<DiagnosisBloc>().state is! DiagnosisHistoryLoaded) {
      context.read<DiagnosisBloc>().add(
        DiagnosisHistoryRequested(userId: _currentUserId),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatColumn = Column(
      children: [
        _buildHeader(),
        _buildDiagnosisPicker(),
        Expanded(child: _buildMessages()),
        _buildQuickActions(),
        _buildInputBar(),
      ],
    );

    if (!widget.floatingMode) {
      return chatColumn;
    }

    return Container(
      color: Colors.white,
      child: chatColumn,
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: widget.floatingMode
          ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
          : const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _assistantService.getLocalizedHeading(widget.isChichewa),
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isChichewa
                      ? 'Funsani za zotsatira, chithandizo, kapena thandizo lapafupi.'
                      : 'Ask about results, treatment, or nearby support.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (widget.floatingMode)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
              tooltip: widget.isChichewa ? 'Tsekani' : 'Close',
            ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisPicker() {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is! DiagnosisHistoryLoaded || state.history.isEmpty) {
          return const SizedBox.shrink();
        }

        final history = state.history;
        _selectedDiagnosis ??= widget.initialDiagnosis ?? history.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDiagnosis?.id,
            decoration: InputDecoration(
              labelText: widget.isChichewa
                  ? 'Sankhani zotsatira'
                  : 'Select diagnosis context',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: history
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(
                      widget.isChichewa
                          ? d.diagnosisNameChichewa
                          : d.diagnosisName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedDiagnosis = history.firstWhere((d) => d.id == id);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.isChichewa
                ? 'Palibe mafunso pano. Yambani ndi kufunsa AI za zotsatira zanu.'
                : 'No questions yet. Start by asking AI about your scan results.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final message = _messages[index];
        final isUser = message.role == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            label: Text(widget.isChichewa ? 'Pafupi thandizo' : 'Nearby help'),
            onPressed: () => _sendPrompt(
              widget.isChichewa
                  ? 'Ndithandizeni kupeza thandizo lapafupi'
                  : 'Help me locate nearby support',
            ),
          ),
          ActionChip(
            label: Text(
              widget.isChichewa ? 'Agro-dealer pafupi' : 'Nearby agro-dealer',
            ),
            onPressed: () => _sendPrompt(
              widget.isChichewa
                  ? 'Kodi pali agro-dealer wapafupi?'
                  : 'Is there a nearby agro-dealer?',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: widget.isChichewa
                      ? 'Funsani AI funso lotsatira...'
                      : 'Ask AI a follow-up question...',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _sendPrompt(_controller.text),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading
                  ? null
                  : () => _sendPrompt(_controller.text),
              icon: const Icon(Icons.send),
              color: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPrompt(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    final userMessage = AiChatMessage(
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
      languageCode: _languageCode,
      diagnosisId: _selectedDiagnosis?.id,
    );

    setState(() {
      _messages = [..._messages, userMessage];
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    final locationState = context.read<LocationBloc>().state;

    final aiText = await _assistantService.askQuestion(
      prompt: prompt,
      isChichewa: widget.isChichewa,
      history: _messages,
      diagnosis: _selectedDiagnosis,
      nearestDealer: locationState is LocationLoaded
          ? locationState.nearestDealer
          : null,
      nearestOfficer: locationState is LocationLoaded
          ? locationState.nearestOfficer
          : null,
      locationName: locationState is LocationLoaded
          ? locationState.location.placeName
          : null,
      pageContext: widget.pageContext,
    );

    final assistantMessage = AiChatMessage(
      role: 'assistant',
      text: aiText,
      timestamp: DateTime.now(),
      languageCode: _languageCode,
      diagnosisId: _selectedDiagnosis?.id,
    );

    if (!mounted) return;

    setState(() {
      _messages = [..._messages, assistantMessage];
      _isLoading = false;
    });

    await _assistantService.saveHistory(
      _messages,
      _languageCode,
      userId: _currentUserId,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
