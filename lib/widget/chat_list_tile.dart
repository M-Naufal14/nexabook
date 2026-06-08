import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/firebase_sqlite_helper.dart';
import '../page/vendor_chat_room_page.dart';

/// Widget tile untuk daftar chat yang menampilkan:
/// - Preview pesan terbaru secara real-time via Firestore Stream
/// - Timestamp pesan terbaru
/// - Badge titik hijau jika pesan terakhir dikirim oleh pihak lain (unread)
class ChatListTile extends StatelessWidget {
  final String chatRoomId;
  final String currentUserEmail;
  final String otherUserName;
  final String otherUserInitial;
  final Color avatarColor;

  const ChatListTile({
    super.key,
    required this.chatRoomId,
    required this.currentUserEmail,
    required this.otherUserName,
    required this.otherUserInitial,
    this.avatarColor = const Color(0xFF10B981),
  });

  Color _getCardBg(BuildContext context) => Theme.of(context).cardColor;
  Color _getTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0F172A);
  Color _getSubColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade400
          : Colors.grey.shade600;
  Color _getBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF334155)
          : Colors.grey.shade200;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    if (msgDay == today) return '$hour:$minute';
    final diff = today.difference(msgDay).inDays;
    if (diff == 1) return 'Kemarin';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseSqliteHelper.instance.getLatestMessageStream(chatRoomId),
      builder: (context, snapshot) {
        String previewText = 'Ketuk untuk memulai obrolan...';
        String timeStr = '';
        bool hasUnread = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data();
          previewText = data['text'] as String? ?? '';
          final senderEmail = (data['senderEmail'] as String? ?? '').toLowerCase();
          final Timestamp? ts = data['timestamp'] as Timestamp?;
          if (ts != null) timeStr = _formatTimestamp(ts.toDate());
          hasUnread = senderEmail != currentUserEmail.toLowerCase();
        }

        final cardBg = _getCardBg(context);
        final borderColor = hasUnread
            ? const Color(0xFF10B981).withValues(alpha: 0.5)
            : _getBorderColor(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: hasUnread ? 1.5 : 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03,
                ),
                blurRadius: 6,
              ),
            ],
          ),
          // Material + InkWell untuk ink splash yang benar di atas warna latar
          child: Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorChatRoomPage(
                      chatRoomId: chatRoomId,
                      currentUserEmail: currentUserEmail,
                      otherUserName: otherUserName,
                      otherUserInitial: otherUserInitial,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar dengan dot online
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: avatarColor.withValues(alpha: 0.15),
                          child: Text(
                            otherUserInitial,
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Konten teks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama + Waktu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  otherUserName,
                                  style: TextStyle(
                                    fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                                    color: _getTextColor(context),
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: hasUnread
                                      ? const Color(0xFF10B981)
                                      : Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Preview pesan + badge unread
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  previewText,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? _getTextColor(context)
                                        : _getSubColor(context),
                                    fontSize: 13,
                                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (hasUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
