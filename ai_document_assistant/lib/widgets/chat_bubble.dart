import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.sources});

  final ChatMessage message;
  final List<String>? sources;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser
        ? const Color(0xFF66E3C4)
        : const Color(0xFF132540);
    final textColor = isUser ? Colors.black : Colors.white;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isUser
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              message.text.isEmpty ? 'Thinking...' : message.text,
              style: TextStyle(
                color: textColor,
                height: 1.45,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isUser && sources != null && sources!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sources!
                    .map(
                      (source) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          source,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
