import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart';
import 'package:list_demo/data/dummy_generator.dart';

import '../../data/models/message_model.dart';

class CustomListView extends StatefulWidget {

  const CustomListView({super.key});

  @override
  State<CustomListView> createState() => _CustomListViewState();
}

class _CustomListViewState extends State<CustomListView> {
  late List<ChatMessage> messages;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  String? _floatingHeaderText;
  Timer? _hideHeaderTimer;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    messages = DummyData().generateDummyMessageData(count: 100);
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _hideHeaderTimer?.cancel();
    super.dispose();
  }

  void _handleScroll() {
    if (messages.isEmpty) return;

    final offset = _scrollController.offset;
    final itemIndex = (_scrollController.offset ~/ 60).clamp(0, messages.length - 1);
    final currentMessage = messages[itemIndex];
    final newHeaderText = _formatDate(currentMessage.timeStamp);

    if (_floatingHeaderText != newHeaderText) {
      setState(() {
        _floatingHeaderText = newHeaderText;
        _showFloatingHeader = true;
      });
      _hideHeaderTimer?.cancel();
      _hideHeaderTimer = Timer(const Duration(seconds: 2), () {
        setState(() => _showFloatingHeader = false);
      });
    }

    setState(() {
      _showScrollToBottom = _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 120;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Map<String, List<ChatMessage>> _groupMessagesByDate(List<ChatMessage> messages) {
    final Map<String, List<ChatMessage>> grouped = {};
    for (final message in messages) {
      final key = _formatDate(message.timeStamp);
      grouped.putIfAbsent(key, () => []).add(message);
    }
    return grouped;
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedMessages = _groupMessagesByDate(messages);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "Scrollable Positioned List",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            reverse: true,
            controller: _scrollController,
            slivers: [
              ...groupedMessages.entries.map((entry) {
                return SliverStickyHeader(
                  overlapsContent: false,
                  header: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.grey[200],
                    child: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final msg = entry.value[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(msg.text),
                            ),
                          ),
                        );
                      },
                      childCount: entry.value.length,
                    ),
                  ),
                );
              }).toList(),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
          // Floating Header
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showFloatingHeader ? 16 : -50,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showFloatingHeader ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _floatingHeaderText ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          // Scroll-to-bottom button
          if (_showScrollToBottom)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.blue,
                onPressed: _scrollToBottom,
                child: const Icon(Icons.arrow_downward),
              ),
            ),
        ],
      ),
    );
  }
}
