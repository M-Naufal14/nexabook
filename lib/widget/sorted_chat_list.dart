import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/firebase_sqlite_helper.dart';
import 'chat_list_tile.dart';

/// Widget daftar chat yang otomatis mengurutkan percakapan berdasarkan
/// timestamp pesan terbaru — percakapan paling aktif selalu di atas,
/// seperti WhatsApp / Telegram.
///
/// Setiap item dalam [chatItems] harus memiliki:
///   - 'chatRoomId'       : String
///   - 'currentUserEmail' : String
///   - 'otherUserName'    : String
///   - 'otherUserInitial' : String
class SortedChatList extends StatefulWidget {
  final List<Map<String, dynamic>> chatItems;

  const SortedChatList({super.key, required this.chatItems});

  @override
  State<SortedChatList> createState() => _SortedChatListState();
}

class _SortedChatListState extends State<SortedChatList> {
  /// Simpan timestamp terbaru setiap chat room (ms sejak epoch, 0 = belum ada pesan)
  final Map<String, int> _latestTimestamps = {};

  /// Subscriptions Firestore per chat room
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subscriptions = {};

  /// Daftar item yang sudah diurutkan
  List<Map<String, dynamic>> _sortedItems = [];

  @override
  void initState() {
    super.initState();
    _sortedItems = List.from(widget.chatItems);
    _subscribeToAll();
  }

  @override
  void didUpdateWidget(covariant SortedChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika daftar chat berubah (misalnya setelah load booking baru), refresh
    if (oldWidget.chatItems != widget.chatItems) {
      _cancelAll();
      _sortedItems = List.from(widget.chatItems);
      _subscribeToAll();
    }
  }

  void _subscribeToAll() {
    for (final item in widget.chatItems) {
      final chatRoomId = item['chatRoomId'] as String? ?? '';
      if (chatRoomId.isEmpty) continue;
      _latestTimestamps[chatRoomId] = 0;

      final stream =
          FirebaseSqliteHelper.instance.getLatestMessageStream(chatRoomId);

      _subscriptions[chatRoomId] = stream.listen((snapshot) {
        if (!mounted) return;
        if (snapshot.docs.isNotEmpty) {
          final ts =
              snapshot.docs.first.data()['timestamp'] as Timestamp?;
          if (ts != null) {
            setState(() {
              _latestTimestamps[chatRoomId] = ts.millisecondsSinceEpoch;
              // Urutkan ulang: timestamp terbesar (terbaru) ke atas
              _sortedItems.sort((a, b) {
                final aTime =
                    _latestTimestamps[a['chatRoomId'] as String? ?? ''] ?? 0;
                final bTime =
                    _latestTimestamps[b['chatRoomId'] as String? ?? ''] ?? 0;
                return bTime.compareTo(aTime);
              });
            });
          }
        }
      });
    }
  }

  void _cancelAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _latestTimestamps.clear();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada percakapan.\nBuat booking terlebih dahulu untuk mulai chat!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      itemCount: _sortedItems.length,
      itemBuilder: (context, index) {
        final item = _sortedItems[index];
        return ChatListTile(
          chatRoomId: item['chatRoomId'] as String? ?? '',
          currentUserEmail: item['currentUserEmail'] as String? ?? '',
          otherUserName: item['otherUserName'] as String? ?? '',
          otherUserInitial: item['otherUserInitial'] as String? ?? '',
        );
      },
    );
  }
}
