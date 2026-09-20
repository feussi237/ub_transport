import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/agency_service.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// Conversation between the signed-in passenger and an agency, about a
/// specific trip. Resolves the agency's contact user lazily via
/// [AgencyService] so callers only need to know the agency id.
class MessagesScreen extends StatefulWidget {
  final int agencyId;
  final String agencyName;
  final int? tripId;

  const MessagesScreen({super.key, required this.agencyId, required this.agencyName, this.tripId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  int? _receiverId;
  List<ApiMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final agency = await AgencyService.instance.getAgency(widget.agencyId);
      if (agency.contactUserId == null) {
        setState(() {
          _error = 'This agency has no contact set up yet.';
          _loading = false;
        });
        return;
      }
      final thread = await MessageService.instance.thread(agency.contactUserId!, tripId: widget.tripId);
      if (!mounted) return;
      setState(() {
        _receiverId = agency.contactUserId;
        _messages = thread;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _receiverId == null) return;

    setState(() => _sending = true);
    try {
      final sent = await MessageService.instance.send(receiverId: _receiverId!, body: body, tripId: widget.tripId);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _bodyController.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.instance.currentUser?.id;

    return Scaffold(
      appBar: ScreenHeader(title: widget.agencyName, subtitle: 'Conversation'),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null && _messages.isEmpty)
                    ? StateMessage(icon: Icons.chat_bubble_outline, message: _error!)
                    : _messages.isEmpty
                        ? const StateMessage(icon: Icons.chat_bubble_outline, message: 'Say hello — ask about schedules, delays or anything else.')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _MessageBubble(
                              message: _messages[index],
                              isMine: _messages[index].senderId == myId,
                            ),
                          ),
          ),
          if (_receiverId != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bodyController,
                        style: AppTextStyles.body,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: 'Write a message…'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _sending ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ApiMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.darkOlive : AppColors.chipFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.body,
          style: TextStyle(color: isMine ? AppColors.white : AppColors.textPrimary, fontSize: 14),
        ),
      ),
    );
  }
}
