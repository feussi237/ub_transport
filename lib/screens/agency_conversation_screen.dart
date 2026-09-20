import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// Chat thread between the signed-in agency staff member and one passenger.
/// Unlike the passenger-side [MessagesScreen], the receiver id is already
/// known here (from the conversations list), so there's no agency lookup step.
class AgencyConversationScreen extends StatefulWidget {
  final int passengerId;
  final String passengerName;

  const AgencyConversationScreen({super.key, required this.passengerId, required this.passengerName});

  @override
  State<AgencyConversationScreen> createState() => _AgencyConversationScreenState();
}

class _AgencyConversationScreenState extends State<AgencyConversationScreen> {
  static const _pollInterval = Duration(seconds: 4);

  final _bodyController = TextEditingController();
  List<ApiMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final thread = await MessageService.instance.thread(widget.passengerId);
      if (!mounted) return;
      setState(() {
        _messages = thread;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!silent && mounted) setState(() => _error = e.message);
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      final sent = await MessageService.instance.send(receiverId: widget.passengerId, body: body);
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
      appBar: ScreenHeader(title: widget.passengerName, subtitle: 'Conversation'),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null && _messages.isEmpty)
                    ? StateMessage(icon: Icons.chat_bubble_outline, message: _error!)
                    : _messages.isEmpty
                        ? const StateMessage(icon: Icons.chat_bubble_outline, message: 'No messages yet.')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _MessageBubble(
                              message: _messages[index],
                              isMine: _messages[index].senderId == myId,
                            ),
                          ),
          ),
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
                      decoration: const InputDecoration(hintText: 'Reply to passenger…'),
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
                          ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
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
