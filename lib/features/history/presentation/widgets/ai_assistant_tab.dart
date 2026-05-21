import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';
import '../../../auth/presentation/bloc/auth_state.dart' show AuthStatus;
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../alerts/domain/entities/alert.dart';
import 'package:mbewu_smart/features/location/domain/entities/extension_officer.dart';
import 'package:mbewu_smart/features/location/domain/entities/agro_dealer.dart';

class AiAssistantTab extends StatefulWidget {
  final bool isChichewa;
  final DiagnosisResult? initialDiagnosis;
  final bool floatingMode;
  final VoidCallback? onClose;
  final String? pageContext;
  final String? initialPrompt;
  final ExtensionOfficer? initialNearestOfficer;
  final AgroDealer? initialNearestDealer;
  final String? initialLocationName;

  const AiAssistantTab({
    super.key,
    required this.isChichewa,
    this.initialDiagnosis,
    this.floatingMode = false,
    this.onClose,
    this.pageContext,
    this.initialPrompt,
    this.initialNearestOfficer,
    this.initialNearestDealer,
    this.initialLocationName,
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
  bool _didSendInitialPrompt = false;

  static const Duration _locationWaitTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _assistantService = di.sl<AiAssistantService>();
    _languageCode = widget.isChichewa ? 'ny' : 'en';
    final authState = context.read<AuthBloc>().state;
    _currentUserId = authState.user?.id;
    _currentUserName = authState.user?.fullName;
    _selectedDiagnosis = _resolveDiagnosisContext();
    _messages = _assistantService.loadHistory(
      _languageCode,
      userId: _currentUserId,
    );

    if (_messages.isEmpty) {
      final latestDiagnosis = _selectedDiagnosis;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didSendInitialPrompt) return;
      final prompt = widget.initialPrompt?.trim();
      if (prompt == null || prompt.isEmpty) return;
      _didSendInitialPrompt = true;
      _sendPrompt(prompt);
    });
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
        Expanded(child: _buildMessages()),
        _buildQuickActions(),
        _buildInputBar(),
      ],
    );

    if (!widget.floatingMode) {
      return chatColumn;
    }

    return Container(color: Colors.white, child: chatColumn);
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

  DiagnosisResult? _resolveDiagnosisContext() {
    if (widget.initialDiagnosis != null) {
      return widget.initialDiagnosis;
    }

    final diagnosisState = context.read<DiagnosisBloc>().state;
    if (diagnosisState is! DiagnosisHistoryLoaded) {
      return null;
    }

    final userHistory = diagnosisState.history
        .where((d) => _currentUserId == null || d.userId == _currentUserId)
        .toList();
    if (userHistory.isEmpty) {
      return null;
    }

    userHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return userHistory.first;
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
              alignment: Alignment.centerRight,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final message = _messages[index];
        final isUser = message.role == 'user';
        final isAssistant = !isUser;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isAssistant
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUser)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAssistant ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAssistant
                          ? AppTheme.primaryGreen
                          : AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isAssistant ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              if (isAssistant)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 8, top: 2),
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
            label: Text(
              widget.isChichewa ? 'Thandizo la Pafupi' : 'Nearby help',
            ),
            onPressed: _isLoading ? null : _sendNearbyHelp,
          ),
          ActionChip(
            label: Text(
              widget.isChichewa ? 'Agro-dealer wapafupi' : 'Nearby agro-dealer',
            ),
            onPressed: _isLoading ? null : _sendNearbyDealerHelp,
          ),
        ],
      ),
    );
  }

  Future<LocationState> _ensureFreshLocationState() async {
    final locationBloc = context.read<LocationBloc>();
    final current = locationBloc.state;
    if (current is LocationLoaded) {
      return current;
    }

    locationBloc.add(LocationGetCurrent());

    try {
      final next = await locationBloc.stream
          .firstWhere(
            (state) => state is LocationLoaded || state is LocationError,
          )
          .timeout(_locationWaitTimeout);
      return next;
    } catch (_) {
      return locationBloc.state;
    }
  }

  Future<void> _sendNearbyHelp() async {
    final locationState = await _ensureFreshLocationState();

    final prompt = widget.isChichewa
        ? 'Ndithandizeni ndi thandizo lapafupi potengera malo anga. Nditchulireni agro-dealer ndi afesa officer omwe ali pafupi, ma phone awo, ndi sitepe yoyamba yomwe ndichite tsopano.'
        : 'Using my current location, give me nearby support. List the nearest agro-dealer and extension officer, their phone numbers, and the first action I should take now.';

    final aiText = await _sendPrompt(
      prompt,
      forcedLocationState: locationState,
    );

    if (!mounted) return;

    if (aiText != null && aiText.isNotEmpty) {
      await _showAssistantResponseModal(aiText);
    }

    await _notifyNearbyHelpTargets(locationState);
  }

  Future<void> _sendNearbyDealerHelp() async {
    final locationState = await _ensureFreshLocationState();

    final prompt = widget.isChichewa
        ? 'Ndipezeni agro-dealer wapafupi pogwiritsa ntchito malo anga. Perekani dzina, dera, nambala ya foni, ndi mankhwala oyenera kutengera zotsatira zanga.'
        : 'Find the nearest agro-dealer using my current location. Provide name, district, phone number, and the most relevant remedy based on my latest diagnosis context.';

    final aiText = await _sendPrompt(
      prompt,
      forcedLocationState: locationState,
    );

    if (!mounted) return;

    if (aiText != null && aiText.isNotEmpty) {
      await _showAssistantResponseModal(aiText);
    }

    await _notifyNearbyHelpTargets(locationState);
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

  Future<String?> _sendPrompt(
    String text, {
    LocationState? forcedLocationState,
  }) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return null;

    final userMessage = AiChatMessage(
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
      languageCode: _languageCode,
      diagnosisId: _resolveDiagnosisContext()?.id,
    );

    setState(() {
      _messages = [..._messages, userMessage];
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    final locationState =
        forcedLocationState ?? context.read<LocationBloc>().state;

    final AgroDealer? nearestDealerParam = (locationState is LocationLoaded)
        ? locationState.nearestDealer
        : widget.initialNearestDealer;

    final ExtensionOfficer? nearestOfficerParam =
        (locationState is LocationLoaded)
        ? locationState.nearestOfficer
        : widget.initialNearestOfficer;

    final String? locationNameParam = (locationState is LocationLoaded)
        ? locationState.location.placeName
        : widget.initialLocationName;

    final aiText = await _assistantService.askQuestion(
      prompt: prompt,
      isChichewa: widget.isChichewa,
      history: _messages,
      diagnosis: _resolveDiagnosisContext(),
      userId: _currentUserId,
      nearestDealer: nearestDealerParam,
      nearestOfficer: nearestOfficerParam,
      locationName: locationNameParam,
      pageContext: widget.pageContext,
    );

    final assistantMessage = AiChatMessage(
      role: 'assistant',
      text: aiText,
      timestamp: DateTime.now(),
      languageCode: _languageCode,
      diagnosisId: _resolveDiagnosisContext()?.id,
    );

    if (!mounted) return aiText;

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
    return aiText;
  }

  Future<void> _notifyNearbyHelpTargets(LocationState locationState) async {
    final authState = context.read<AuthBloc>().state;
    final diagnosis = _resolveDiagnosisContext();

    final farmerName = authState.user?.fullName ?? 'Unknown Farmer';
    final farmerPhone = authState.user?.phoneNumber ?? 'Unknown';
    final locationText = locationState is LocationLoaded
        ? '${locationState.location.placeName ?? ''}${locationState.location.district != null ? ', ${locationState.location.district}' : ''}'
        : '';

    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      location: locationText,
      cropName: diagnosis == null
          ? 'Unknown'
          : (widget.isChichewa
                ? diagnosis.cropType.displayNameChichewa
                : diagnosis.cropType.displayName),
      diagnosisName: diagnosis == null
          ? 'Unknown'
          : (widget.isChichewa
                ? diagnosis.diagnosisNameChichewa
                : diagnosis.diagnosisName),
      confidence: diagnosis?.confidence ?? 0.0,
      timestamp: DateTime.now(),
      note: widget.isChichewa
          ? 'Farmer requested nearby help via AI assistant.'
          : 'Farmer requested nearby help via AI assistant.',
    );

    bool alertSent = false;
    bool reportSent = false;

    try {
      context.read<AlertsBloc>().add(AlertSent(alert));
      alertSent = true;
    } catch (_) {
      alertSent = false;
    }

    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        diagnosis != null) {
      try {
        final reportService = di.sl<ReportService>();
        await reportService.createReport(
          diagnosis: diagnosis,
          farmer: authState.user!,
          location: locationState is LocationLoaded
              ? locationState.location
              : null,
          nearestOfficer: locationState is LocationLoaded
              ? locationState.nearestOfficer
              : null,
        );
        reportSent = true;
      } catch (_) {
        reportSent = false;
      }
    }

    if (!mounted) return;

    final message = widget.isChichewa
        ? (reportSent
              ? 'Chidziwitso chatumizidwa kwa manager ndi afesa officer. Alert yasungidwa.'
              : (alertSent
                    ? 'Alert yasungidwa. Report sinatumizidwe pano.'
                    : 'Talephera kutumiza alert/report.'))
        : (reportSent
              ? 'Notification sent to manager and extension officer. Alert saved.'
              : (alertSent
                    ? 'Alert saved. Report could not be sent right now.'
                    : 'Failed to send alert/report.'));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAssistantResponseModal(String responseText) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    widget.isChichewa ? 'Yankho la AI' : 'AI Response',
                    style: AppTextStyles.headingSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(responseText, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.isChichewa ? 'Tsekani' : 'Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
