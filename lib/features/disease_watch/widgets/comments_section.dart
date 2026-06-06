import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/comment.dart';
import '../../reports/data/services/report_service.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import 'comment_input_bar.dart';
import 'comment_list_item.dart';

class CommentsSection extends StatefulWidget {
  final String reportId;

  const CommentsSection({super.key, required this.reportId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  late final ReportService _reportService = di.sl<ReportService>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _replyToName;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Color _avatarColor(String name) => avatarColor(name);

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState.user == null) return;

    final user = authState.user!;
    final comment = Comment(
      commentId: '',
      authorId: user.id,
      authorName: user.fullName,
      authorDistrict: user.district ?? '',
      text: text,
      timestamp: Timestamp.now(),
      replyToName: _replyToName,
    );

    await _reportService.addComment(widget.reportId, comment);

    if (!mounted) return;
    setState(() {
      _controller.clear();
      _replyToName = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final currentUser = context.select<AuthBloc, String?>((bloc) {
      return bloc.state.user?.fullName;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLoc?.translate('comments') ?? 'Comments',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: _reportService.getComments(widget.reportId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: GestureDetector(
                    onTap: () => setState(() {}),
                    child: Text(
                      appLoc?.translate('couldNotLoadComments') ??
                          'Could not load comments. Tap to retry.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                );
              }

              final comments = snapshot.data ?? const <Comment>[];
              if (comments.isEmpty) {
                return Center(
                  child: Text(
                    appLoc?.translate('beFirstToComment') ??
                        'Be the first to comment!',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              final currentUserId = context.read<AuthBloc>().state.user?.id;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentListItem(
                    comment: comment,
                    isLiked:
                        currentUserId != null &&
                        comment.likes.contains(currentUserId),
                    onLike: () {
                      if (currentUserId == null) return;
                      _reportService.toggleLike(
                        widget.reportId,
                        comment.commentId,
                        currentUserId,
                      );
                    },
                    onReply: () {
                      setState(() {
                        _replyToName = comment.authorName;
                        _controller.text = '@${comment.authorName} ';
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      });
                      _focusNode.requestFocus();
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        CommentInputBar(
          controller: _controller,
          focusNode: _focusNode,
          initials: _initials(currentUser ?? 'User'),
          avatarColor: _avatarColor(currentUser ?? 'User'),
          onSend: _sendComment,
        ),
      ],
    );
  }
}
