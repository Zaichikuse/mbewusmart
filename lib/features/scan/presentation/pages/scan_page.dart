import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/farmer_messages.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/domain/entities/extension_officer.dart';
import '../../../location/domain/entities/agro_dealer.dart';
import '../../../reports/data/services/report_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart'
    show AuthState, AuthStatus;
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../history/presentation/widgets/ai_assistant_tab.dart';
import '../../../history/presentation/pages/history_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  CropType _selectedCrop = CropType.maize;
  static const double confidenceThreshold = 0.70;
  late final ReportService _reportService = di.sl<ReportService>();

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(LocationGetCurrent());
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final isChichewa = settingsState is SettingsLoaded
        ? settingsState.languageCode == 'ny'
        : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'kupeza vuto la mbewu' : 'Scan Crop'),
      ),
      body: BlocListener<DiagnosisBloc, DiagnosisState>(
        listener: (context, state) {
          if (state is DiagnosisSuccess) {
            _showResultDialog(context, state, isChichewa);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCropSelector(isChichewa),
              const SizedBox(height: 16),
              Expanded(child: _buildScanArea(context, isChichewa)),
              const SizedBox(height: 16),
              _buildActionButtons(context, isChichewa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropSelector(bool isChichewa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChichewa ? 'Sankha Mbewo' : 'Select Crop',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: CropType.values.map((crop) {
            final isSelected = crop == _selectedCrop;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCrop = crop;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(crop.icon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        isChichewa
                            ? crop.displayNameChichewa
                            : crop.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScanArea(BuildContext context, bool isChichewa) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: BlocBuilder<DiagnosisBloc, DiagnosisState>(
        builder: (context, state) {
          if (state is DiagnosisAnalyzing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    isChichewa ? 'Kupima...' : 'Analyzing...',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isChichewa ? 'Tsimikizire' : 'Please wait',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: AppTheme.primaryGreen.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                isChichewa
                    ? 'Tchani chithunzi cha ${_selectedCrop.displayNameChichewa.toLowerCase()}'
                    : 'Take a photo of your ${_selectedCrop.displayName.toLowerCase()}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isChichewa
                    ? 'Chithunzi chiyambe pamenenso'
                    : 'The image should be clear and well-lit',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isChichewa) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Text(isChichewa ? 'Kamera' : 'Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(isChichewa ? 'Galasi' : 'Gallery'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Read bytes immediately — fixes Android content URI bug
        final imageBytes = await image.readAsBytes();

        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        context.read<LocationBloc>().add(LocationGetCurrent());
        final authState = context.read<AuthBloc>().state;

        context.read<DiagnosisBloc>().add(
          DiagnosisAnalyzeRequested(
            image.path,
            imageBytes: imageBytes,
            cropType: _selectedCrop,
            userId: authState.user?.id,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showResultDialog(
    BuildContext context,
    DiagnosisSuccess state,
    bool isChichewa,
  ) {
    final result = state.result;
    final locationState = context.read<LocationBloc>().state;
    final authState = context.read<AuthBloc>().state;

    String locationText = '';
    String? district;
    if (locationState is LocationLoaded) {
      locationText = locationState.location.placeName ?? '';
      district = locationState.location.district;
      if (locationText.isNotEmpty && district != null) {
        locationText += ', $district';
      } else if (district != null) {
        locationText = district;
      }
    }

    final bool isHighConfidence = result.confidence >= confidenceThreshold;
    ExtensionOfficer? nearestOfficer;
    AgroDealer? nearestDealer;

    if (locationState is LocationLoaded) {
      nearestOfficer = locationState.nearestOfficer;
      nearestDealer = locationState.nearestDealer;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confidence Badge
                  _buildConfidenceBadge(
                    result.confidence,
                    isHighConfidence,
                    isChichewa,
                  ),

                  const SizedBox(height: 16),

                  // Crop and Diagnosis Name
                  Row(
                    children: [
                      Text(
                        result.cropType.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isChichewa
                                  ? result.cropType.displayNameChichewa
                                  : result.cropType.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              result.diagnosisName,
                              style: AppTextStyles.headingMedium,
                            ),
                            Text(
                              result.diagnosisNameChichewa,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Type chip
                  _buildInfoChip(
                    isChichewa
                        ? result.type.displayNameChichewa
                        : result.type.displayName,
                    _getSeverityColor(result.severity),
                  ),

                  // HIGH CONFIDENCE: Show treatment info
                  if (isHighConfidence) ...[
                    const SizedBox(height: 20),

                    // Scientific Name
                    _buildDetailSection(
                      isChichewa ? 'Dzina la sayantifiki' : 'Scientific Name',
                      _resolveDetailText(result.scientificName, isChichewa),
                      isChichewa,
                      Icons.science,
                    ),

                    // Causing Factors
                    _buildDetailSection(
                      isChichewa ? 'Zoyambitsa' : 'Causing Factors',
                      _resolveDetailText(result.causingFactors, isChichewa),
                      isChichewa,
                      Icons.warning_amber,
                    ),

                    // Treatment
                    _buildDetailSection(
                      isChichewa ? 'Mankhwala' : 'Treatment',
                      _resolveDetailText(result.treatment, isChichewa),
                      isChichewa,
                      Icons.healing,
                    ),

                    // Pesticide/Remedy
                    _buildDetailSection(
                      isChichewa ? 'Mankhwala' : 'Pesticide/Remedy',
                      _resolveDetailText(result.pesticideRemedy, isChichewa),
                      isChichewa,
                      Icons.medication,
                    ),

                    // Prevention
                    _buildDetailSection(
                      isChichewa ? 'Kapeweredwe' : 'Prevention',
                      _resolveDetailText(result.prevention, isChichewa),
                      isChichewa,
                      Icons.shield,
                    ),
                  ] else ...[
                    // LOW CONFIDENCE: Warning message only
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warningAmber),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: AppTheme.warningAmber,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isChichewa
                                  ? 'Zotsatira sizikutsimikiza bwino. Funsani Afesa Officer kapena Agro Dealer kuti mupeze chithandizo.'
                                  : 'Results are uncertain. Contact an Extension Officer or Agro Dealer for proper assistance.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ============================================
                  // ALWAYS SHOW: Help section (both confidence levels)
                  // ============================================
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isChichewa ? 'Pezani Thandizo' : 'Get Help',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Extension Officer Card (always shown)
                  if (nearestOfficer != null)
                    () {
                      final officer = nearestOfficer!;
                      return _buildContactCard(
                        title: isChichewa
                            ? 'Afesa Officer (Thandizo Lapafupi)'
                            : 'Extension Officer (Nearby Help)',
                        name: officer.name,
                        phone: officer.phone,
                        latitude: officer.latitude,
                        longitude: officer.longitude,
                        icon: Icons.person,
                        color: AppTheme.accentOrange,
                        onCall: () => _makePhoneCall(officer.phone),
                        isChichewa: isChichewa,
                      );
                    }()
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentOrange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.accentOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isChichewa
                                  ? 'Tikupezani Afesa Officer wapafupi...'
                                  : 'Locating nearby Extension Officer...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Contact Extension Officer button (always shown)
                  _buildMessageActionButton(
                    label: isChichewa
                        ? 'Lankhulani ndi Afesa Officer'
                        : 'Contact Extension Officer',
                    icon: Icons.message,
                    color: AppTheme.accentOrange,
                    onTap: () => _contactExtensionOfficer(
                      context,
                      nearestOfficer,
                      isChichewa,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Agro Dealer Card (always shown)
                  if (nearestDealer != null)
                    () {
                      final dealer = nearestDealer!;
                      return _buildContactCard(
                        title: isChichewa ? 'Agro-Dealer' : 'Agro-Dealer',
                        name: dealer.name,
                        phone: dealer.phone,
                        latitude: dealer.latitude,
                        longitude: dealer.longitude,
                        icon: Icons.store,
                        color: AppTheme.primaryGreen,
                        onCall: () => _makePhoneCall(dealer.phone),
                        isChichewa: isChichewa,
                      );
                    }()
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isChichewa
                                  ? 'Tikupezani Agro Dealer wapafupi...'
                                  : 'Locating nearby Agro Dealer...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Contact Agro Dealer button (always shown)
                  _buildMessageActionButton(
                    label: isChichewa
                        ? 'Lankhulani ndi Agro Dealer'
                        : 'Contact Agro Dealer',
                    icon: Icons.message,
                    color: AppTheme.primaryGreen,
                    onTap: () =>
                        _contactAgroDealer(context, nearestDealer, isChichewa),
                  ),

                  // ============================================
                  // ALWAYS SHOW: Send Alert button (replaces Report to Manager)
                  // ============================================
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _sendAlert(
                          context,
                          result,
                          locationText,
                          authState,
                          isChichewa,
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: Text(
                        isChichewa
                            ? 'Tumizani Alert kwa Manager'
                            : 'Send Alert to Manager',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location
                  if (locationText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationText,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Timestamp
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(result.timestamp),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openAssistantForDiagnosis(
                          hostContext: dialogContext,
                          diagnosis: result,
                          isChichewa: isChichewa,
                          initialPrompt: _buildDefaultAssistantPrompt(
                            diagnosis: result,
                            isChichewa: isChichewa,
                          ),
                          nearestOfficer: nearestOfficer,
                          nearestDealer: nearestDealer,
                          locationName: locationText,
                        );
                      },
                      icon: const Icon(Icons.smart_toy),
                      label: Text(
                        isChichewa ? 'Funsani AI' : 'Ask AI Follow-up',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            context.read<DiagnosisBloc>().add(DiagnosisReset());
                          },
                          child: Text(isChichewa ? 'Yeselaninso' : 'Try Again'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    HistoryPage(initialDiagnosis: result),
                              ),
                            );
                          },
                          child: Text(isChichewa ? 'Mbiri' : 'History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfidenceBadge(
    double confidence,
    bool isHighConfidence,
    bool isChichewa,
  ) {
    final color = isHighConfidence
        ? AppTheme.healthyGreen
        : AppTheme.warningAmber;
    final confidencePercent = (confidence * 100).toStringAsFixed(0);

    String confidenceMessage;
    if (confidence >= 0.8) {
      confidenceMessage = FarmerMessages.getConfidenceHigh(isChichewa);
    } else if (confidence >= 0.7) {
      confidenceMessage = FarmerMessages.getConfidenceMedium(isChichewa);
    } else {
      confidenceMessage = FarmerMessages.getUncertainResult(isChichewa);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHighConfidence ? Icons.check_circle : Icons.warning,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$confidencePercent% ${isChichewa ? 'Kutsimikiza' : 'confidence'}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isHighConfidence
                      ? (isChichewa ? 'Yokwela' : 'HIGH')
                      : (isChichewa ? 'Yotsika' : 'LOW'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isHighConfidence) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningAmber),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.help_outline,
                  color: AppTheme.warningAmber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    confidenceMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isChichewa ? AppTheme.textDark : AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactCard({
    required String title,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required IconData icon,
    required Color color,
    required VoidCallback onCall,
    required bool isChichewa,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 4),
          Text(
            phone,
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(isChichewa ? 'Lowa fono' : 'Call Now'),
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(
                      latitude: latitude,
                      longitude: longitude,
                      label: name,
                    ),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: Text(isChichewa ? 'Mapu' : 'Directions'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _resolveDetailText(String? value, bool isChichewa) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return isChichewa ? 'Palibe' : 'Not available';
    }
    return text;
  }

  Widget _buildDetailSection(
    String title,
    String content,
    bool isChichewa,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(content, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openDirections({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label);
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&query=$encodedLabel&travelmode=driving',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _openAssistantForDiagnosis({
    required BuildContext hostContext,
    required DiagnosisResult diagnosis,
    required bool isChichewa,
    String? initialPrompt,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
    String? locationName,
  }) {
    // Ensure the app requests a fresh location before opening assistant.
    final locationBloc = context.read<LocationBloc>();
    if (locationBloc.state is! LocationLoaded) {
      locationBloc.add(LocationGetCurrent());
    }

    Navigator.pop(hostContext);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: AiAssistantTab(
                isChichewa: isChichewa,
                initialDiagnosis: diagnosis,
                initialPrompt: initialPrompt,
                floatingMode: true,
                pageContext: isChichewa
                    ? 'Zotsatira za kufufuza'
                    : 'Scan result',
                onClose: () => Navigator.of(sheetContext).pop(),
                initialNearestOfficer: nearestOfficer,
                initialNearestDealer: nearestDealer,
                initialLocationName: locationName,
              ),
            );
          },
        );
      },
    );
  }

  String _buildDefaultAssistantPrompt({
    required DiagnosisResult diagnosis,
    required bool isChichewa,
  }) {
    final diagnosisName = isChichewa
        ? diagnosis.diagnosisNameChichewa
        : diagnosis.diagnosisName;

    if (diagnosis.confidence >= confidenceThreshold) {
      return isChichewa
          ? 'Ndafotokozerani zotsatira za "$diagnosisName" ndipo mundiuze zomwe ndiyenera kuchita tsopano, kuphatikiza mankhwala ndi njira zopewera.'
          : 'Please explain this "$diagnosisName" result and tell me what I should do next, including treatment and prevention.';
    }

    return isChichewa
        ? 'Zotsatira za "$diagnosisName" sizikutsimikiza bwino. Ndithandizeni kumvetsa zomwe ndiyenera kuchita tsopano ndi ngati ndilankhule ndi thandizo lapafupi.'
        : 'This "$diagnosisName" result looks uncertain. Help me understand what to do next and whether I should contact nearby support.';
  }

  String _buildSupportPrompt({
    required String targetRole,
    required bool isChichewa,
    String? contactName,
  }) {
    switch (targetRole) {
      case 'extensionOfficer':
        return isChichewa
            ? 'Ndithandizeni kulankhula ndi Afesa Officer${contactName == null ? '' : ' $contactName'} pa zotsatira za scan yanga.'
            : 'Help me continue this scan with the nearby Extension Officer${contactName == null ? '' : ' $contactName'}.';
      case 'agroDealer':
        return isChichewa
            ? 'Ndithandizeni kupeza mankhwala oyenera ndi kulumikizana ndi agro-dealer${contactName == null ? '' : ' $contactName'}.'
            : 'Help me find the right remedy and connect with the nearby agro-dealer${contactName == null ? '' : ' $contactName'}.';
      case 'agricultureManager':
        return isChichewa
            ? 'Ndithandizeni kulemba report ya vuto ili kwa Agriculture Manager.'
            : 'Help me prepare a short report for the Agriculture Manager about this scan result.';
      default:
        return isChichewa
            ? 'Ndithandizeni ndi zotsatira za scan iyi.'
            : 'Help me with this scan result.';
    }
  }

  void _sendAlert(
    BuildContext context,
    DiagnosisResult result,
    String location,
    AuthState authState,
    bool isChichewa,
  ) {
    final farmerName =
        authState.status == AuthStatus.authenticated && authState.user != null
        ? authState.user!.fullName
        : 'Unknown Farmer';
    final farmerPhone =
        authState.status == AuthStatus.authenticated && authState.user != null
        ? authState.user!.phoneNumber
        : 'Unknown';

    // Get district separately from location
    final locationState = context.read<LocationBloc>().state;
    String district = '';
    if (locationState is LocationLoaded) {
      district = locationState.location.district ?? '';
    }

    // Pre-fill suggested note based on confidence
    final suggestedNote = result.confidence >= confidenceThreshold
        ? (isChichewa
              ? 'Pezani matenda ${result.diagnosisNameChichewa} pa ${result.cropType.displayNameChichewa}. Ndikufuna chithandizo.'
              : 'Detected ${result.diagnosisName} on ${result.cropType.displayName}. Requesting assistance.')
        : (isChichewa
              ? 'Zotsatira sizikutsimikiza bwino - ndikufuna kuwunikira.'
              : 'Results uncertain - requires professional review.');

    final notesController = TextEditingController(text: suggestedNote);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.send, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isChichewa ? 'Tumizani Alert' : 'Send Alert',
                  style: AppTextStyles.headingSmall,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isChichewa
                      ? 'Tsimikizirani zomwe Manager adzalandire:'
                      : 'Confirm what the Manager will receive:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                // Read-only preview
                _buildAlertPreviewRow(
                  Icons.person,
                  isChichewa ? 'Dzina' : 'Name',
                  farmerName,
                ),
                _buildAlertPreviewRow(
                  Icons.phone,
                  isChichewa ? 'Foni' : 'Phone',
                  farmerPhone,
                ),
                _buildAlertPreviewRow(
                  Icons.location_on,
                  isChichewa ? 'Malo' : 'Location',
                  location.isNotEmpty
                      ? location
                      : (isChichewa ? 'Sizidziwika' : 'Unknown'),
                ),
                if (district.isNotEmpty)
                  _buildAlertPreviewRow(
                    Icons.map,
                    isChichewa ? 'Boma' : 'District',
                    district,
                  ),
                _buildAlertPreviewRow(
                  Icons.local_florist,
                  isChichewa ? 'Mbewu' : 'Crop',
                  isChichewa
                      ? result.cropType.displayNameChichewa
                      : result.cropType.displayName,
                ),
                _buildAlertPreviewRow(
                  Icons.bug_report,
                  isChichewa ? 'Matenda' : 'Diagnosis',
                  isChichewa
                      ? result.diagnosisNameChichewa
                      : result.diagnosisName,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Editable notes field
                Text(
                  isChichewa
                      ? 'Mawu Anu (mukhoza kusintha):'
                      : 'Your Notes (editable):',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isChichewa
                        ? 'Lembani zambiri za vutoli...'
                        : 'Add more details about the issue...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Ayi' : 'Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final finalNote = notesController.text.trim().isEmpty
                    ? suggestedNote
                    : notesController.text.trim();

                final alert = Alert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  farmerName: farmerName,
                  farmerPhone: farmerPhone,
                  location: location,
                  district: district,
                  cropName: isChichewa
                      ? result.cropType.displayNameChichewa
                      : result.cropType.displayName,
                  diagnosisName: isChichewa
                      ? result.diagnosisNameChichewa
                      : result.diagnosisName,
                  confidence: result.confidence,
                  timestamp: DateTime.now(),
                  note: finalNote,
                  status: 'pending',
                );

                context.read<AlertsBloc>().add(AlertSent(alert));

                // Also notify extension officer (existing flow)
                final locationState = context.read<LocationBloc>().state;
                final ExtensionOfficer? notifyOfficer =
                    locationState is LocationLoaded
                    ? locationState.nearestOfficer
                    : null;
                _createReportAndNotify(
                  result: result,
                  isChichewa: isChichewa,
                  nearestOfficer: notifyOfficer,
                );

                Navigator.pop(dialogContext);

                // Show confirmation
                showDialog(
                  context: context,
                  builder: (confirmContext) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.healthyGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(isChichewa ? 'Yatumizidwa!' : 'Alert Sent!'),
                        ],
                      ),
                      content: Text(
                        isChichewa
                            ? 'Alert yanu yatumizidwa kwa Agriculture Manager. Mudzapatsidwa thandizo posachedwa.'
                            : 'Your alert has been sent to the Agriculture Manager. You will receive assistance soon.',
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: Text(isChichewa ? 'Uli' : 'OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.send),
              label: Text(isChichewa ? 'Tumiza' : 'Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Future<void> _createReportAndNotify({
    required DiagnosisResult result,
    required bool isChichewa,
    ExtensionOfficer? nearestOfficer,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChichewa
                ? 'Lowani kaye kuti muthe kutumiza lipoti.'
                : 'Please log in to send a report.',
          ),
        ),
      );
      return;
    }

    final locationState = context.read<LocationBloc>().state;
    final location = locationState is LocationLoaded
        ? locationState.location
        : null;

    try {
      await _reportService.createReport(
        diagnosis: result,
        farmer: authState.user!,
        location: location,
        nearestOfficer: nearestOfficer,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChichewa
                  ? 'lipoti latumizidwa kwa Manager ndi Afesa Officer.'
                  : 'Report sent to the Manager and Extension Officer.',
            ),
            backgroundColor: AppTheme.healthyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChichewa
                  ? 'Report sinatumizidwe. Yesaninso.'
                  : 'Report failed to send. Please try again.',
            ),
          ),
        );
      }
    }
  }

  void _contactExtensionOfficer(
    BuildContext context,
    ExtensionOfficer? officer,
    bool isChichewa,
  ) {
    if (officer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChichewa
                ? 'Palibe Afesa Officer wapezeka'
                : 'No Extension Officer found',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.accentOrange,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(officer.name, style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text(
                isChichewa ? 'Afesa Officer' : 'Extension Officer',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              if (officer.area != null) ...[
                const SizedBox(height: 4),
                Text(
                  officer.area!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _makePhoneCall(officer.phone);
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(isChichewa ? 'Lowa Fono' : 'Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _startMessageConversation(
                          context,
                          officer,
                          'extensionOfficer',
                          isChichewa,
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: Text(isChichewa ? 'Uthenga' : 'Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _contactAgroDealer(
    BuildContext context,
    AgroDealer? dealer,
    bool isChichewa,
  ) {
    if (dealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChichewa ? 'Palibe Agro Dealer wapezeka' : 'No Agro Dealer found',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryGreen,
                child: const Icon(Icons.store, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(dealer.name, style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text(
                isChichewa ? 'Agro-Dealer' : 'Agro-Dealer',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              if (dealer.area != null) ...[
                const SizedBox(height: 4),
                Text(
                  dealer.area!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _makePhoneCall(dealer.phone);
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(isChichewa ? 'Lowa Fono' : 'Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _startMessageConversation(
                          context,
                          dealer,
                          'agroDealer',
                          isChichewa,
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: Text(isChichewa ? 'Uthenga' : 'Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _startMessageConversation(
    BuildContext context,
    dynamic entity,
    String targetRole,
    bool isChichewa,
  ) {
    final diagnosisState = context.read<DiagnosisBloc>().state;
    final diagnosis = entity is DiagnosisResult
        ? entity
        : diagnosisState is DiagnosisSuccess
        ? diagnosisState.result
        : null;

    final contactName = switch (entity) {
      final ExtensionOfficer officer => officer.name,
      final AgroDealer dealer => dealer.name,
      _ => null,
    };

    if (diagnosis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChichewa
                ? 'Yambani ndi kuscan kuti AI ikuthandizeni bwino.'
                : 'Start with a scan result first so AI can help with context.',
          ),
        ),
      );
      return;
    }

    final locationState = context.read<LocationBloc>().state;
    String locationText = '';
    String? district;
    if (locationState is LocationLoaded) {
      locationText = locationState.location.placeName ?? '';
      district = locationState.location.district;
      if (locationText.isNotEmpty && district != null) {
        locationText += ', $district';
      } else if (district != null && locationText.isEmpty) {
        locationText = district;
      }
    }

    _openAssistantForDiagnosis(
      hostContext: context,
      diagnosis: diagnosis,
      isChichewa: isChichewa,
      initialPrompt: _buildSupportPrompt(
        targetRole: targetRole,
        isChichewa: isChichewa,
        contactName: contactName,
      ),
      nearestOfficer: locationState is LocationLoaded
          ? locationState.nearestOfficer
          : null,
      nearestDealer: locationState is LocationLoaded
          ? locationState.nearestDealer
          : null,
      locationName: locationText.isNotEmpty ? locationText : null,
    );
  }

  Color _getSeverityColor(dynamic severity) {
    switch (severity.toString()) {
      case 'Severity.low':
        return AppTheme.healthyGreen;
      case 'Severity.medium':
        return AppTheme.warningAmber;
      case 'Severity.high':
        return AppTheme.diseaseRed;
      default:
        return AppTheme.textLight;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
