import 'package:flutter/material.dart';
import 'dart:async';

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String sender;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
    required this.sender,
  });
}

class ChatMessageView extends StatefulWidget {
  final List<Message> messages;
  final Function(String)? onMessageTap;

  const ChatMessageView({
    Key? key,
    required this.messages,
    this.onMessageTap,
  }) : super(key: key);

  @override
  State<ChatMessageView> createState() => _ChatMessageViewState();
}

class _ChatMessageViewState extends State<ChatMessageView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _floatingHeaderController;
  late AnimationController _scrollToBottomController;
  late Animation<double> _floatingHeaderAnimation;
  late Animation<double> _scrollToBottomAnimation;

  Timer? _hideHeaderTimer;
  String _currentFloatingDate = '';
  bool _showScrollToBottom = false;
  bool _showFloatingHeader = false;

  // Grouped messages by date
  Map<String, List<Message>> _groupedMessages = {};
  List<String> _dateKeys = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _groupMessagesByDate();
    _setupScrollListener();
  }

  void _initializeControllers() {
    _scrollController = ScrollController();

    _floatingHeaderController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollToBottomController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingHeaderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingHeaderController,
      curve: Curves.easeInOut,
    ));

    _scrollToBottomAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollToBottomController,
      curve: Curves.easeInOut,
    ));
  }

  void _groupMessagesByDate() {
    _groupedMessages.clear();
    _dateKeys.clear();

    for (var message in widget.messages) {
      final dateKey = _formatDateKey(message.timestamp);

      if (!_groupedMessages.containsKey(dateKey)) {
        _groupedMessages[dateKey] = [];
        _dateKeys.add(dateKey);
      }

      _groupedMessages[dateKey]!.add(message);
    }

    // Sort messages within each group by timestamp (newest first for reversed list)
    _groupedMessages.forEach((key, messages) {
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });

    // Sort date keys reverse chronologically (newest dates first)
    _dateKeys.sort((a, b) {
      final dateA = _parseDateKey(a);
      final dateB = _parseDateKey(b);
      return dateB.compareTo(dateA);
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      _handleScrollToBottomVisibility();
      _handleFloatingHeader();
    });
  }

  void _handleScrollToBottomVisibility() {
    if (!_scrollController.hasClients) return;

    // In reversed list: position 0 = latest messages, higher values = older messages
    // Show button when user scrolls away from latest messages (position > 160)
    final hasScrolledAwayFromLatest = _scrollController.position.pixels > 160;

    final shouldShow = hasScrolledAwayFromLatest;

    if (shouldShow != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });

      if (shouldShow) {
        _scrollToBottomController.forward();
      } else {
        _scrollToBottomController.reverse();
      }
    }
  }

  void _handleFloatingHeader() {
    if (!_scrollController.hasClients || _dateKeys.isEmpty) return;

    final scrollOffset = _scrollController.position.pixels;

    // Don't show floating header when overscrolling at top
    if (scrollOffset <= 0) {
      if (_showFloatingHeader) {
        _floatingHeaderController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showFloatingHeader = false;
            });
          }
        });
      }
      return;
    }

    // Determine current visible date based on scroll position
    String? currentDate = _getCurrentVisibleDate(scrollOffset);

    if (currentDate != null && currentDate != _currentFloatingDate) {
      setState(() {
        _currentFloatingDate = currentDate;
        _showFloatingHeader = true;
      });

      _floatingHeaderController.forward();
      _resetHideTimer();
    }
  }

  String? _getCurrentVisibleDate(double scrollOffset) {
    if (_dateKeys.isEmpty || scrollOffset <= 0) return null;

    // In reversed list: calculate from top (newest dates first)
    double currentOffset = 0;

    for (String dateKey in _dateKeys) {
      final messagesInGroup = _groupedMessages[dateKey]!.length;
      final headerHeight = 60.0;
      final messagesHeight = messagesInGroup * 80.0;
      final groupHeight = headerHeight + messagesHeight;

      if (scrollOffset >= currentOffset && scrollOffset < currentOffset + groupHeight) {
        return dateKey;
      }

      currentOffset += groupHeight;
    }

    // Return oldest date if scrolled past all groups
    return _dateKeys.isNotEmpty ? _dateKeys.last : null;
  }

  void _resetHideTimer() {
    _hideHeaderTimer?.cancel();
    _hideHeaderTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _floatingHeaderController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showFloatingHeader = false;
            });
          }
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // In reversed list: scroll to position 0 to show latest messages
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  DateTime _parseDateKey(String dateKey) {
    final now = DateTime.now();

    switch (dateKey) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Yesterday':
        return DateTime(now.year, now.month, now.day - 1);
      default:
        final parts = dateKey.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMessageList(),
          _buildFloatingHeader(),
          _buildScrollToBottomButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      reverse: true, // Start from bottom - shows latest messages first
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
        ..._dateKeys.map((dateKey) => _buildDateGroup(dateKey)),
      ],
    );
  }

  Widget _buildDateGroup(String dateKey) {
    final messages = _groupedMessages[dateKey]!;
    final isFirstGroup = _dateKeys.indexOf(dateKey) == 0; // First group = latest messages

    return SliverMainAxisGroup(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final message = messages[index];
              // For the first group (latest), show inline header after last message
              if (isFirstGroup && index == messages.length - 1) {
                return Column(
                  children: [
                    _buildMessageItem(message),
                    const SizedBox(height: 16),
                    _buildInlineDateHeader(dateKey),
                    const SizedBox(height: 16),
                  ],
                );
              }
              // For other groups, show header before first message
              if (!isFirstGroup && index == 0) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInlineDateHeader(dateKey),
                    const SizedBox(height: 16),
                    _buildMessageItem(message),
                  ],
                );
              }
              return _buildMessageItem(message);
            },
            childCount: messages.length,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => widget.onMessageTap?.call(message.id),
        child: Row(
          mainAxisAlignment:
          message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!message.isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  message.sender[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: message.isMe
                      ? Colors.blue[500]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: message.isMe
                            ? Colors.white70
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                child: Text(
                  message.sender[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return AnimatedBuilder(
      animation: _floatingHeaderAnimation,
      builder: (context, child) {
        if (!_showFloatingHeader) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          child: Transform.translate(
            offset: Offset(0, -30 * (1 - _floatingHeaderAnimation.value)),
            child: Opacity(
              opacity: _floatingHeaderAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _currentFloatingDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedBuilder(
      animation: _scrollToBottomAnimation,
      builder: (context, child) {
        if (!_showScrollToBottom) return const SizedBox.shrink();

        return Positioned(
          right: 20,
          bottom: 20,
          child: Transform.scale(
            scale: _scrollToBottomAnimation.value,
            child: FloatingActionButton(
              mini: true,
              onPressed: _scrollToBottom,
              backgroundColor: Colors.blue[500],
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineDateHeader(String dateKey) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateKey,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String dateKey;
  final double height;

  _DateHeaderDelegate({
    required this.dateKey,
    required this.height,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: Colors.transparent,
      alignment: Alignment.center, // Ensure proper alignment
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateKey,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}

// Example usage and demo
class CustomList2View extends StatefulWidget {
  @override
  State<CustomList2View> createState() => _CustomList2ViewState();
}

class _CustomList2ViewState extends State<CustomList2View> {
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _generateSampleMessages();
  }

  void _generateSampleMessages() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    messages = [
      // Two days ago
      Message(
        id: '1',
        text: 'Hey! How are you doing?',
        timestamp: twoDaysAgo.add(const Duration(hours: 9, minutes: 30)),
        isMe: false,
        sender: 'Alice',
      ),
      Message(
        id: '11',
        text: 'Hey! How are you doing???',
        timestamp: twoDaysAgo.add(const Duration(hours: 9, minutes: 40)),
        isMe: false,
        sender: 'Alice',
      ),
      Message(
        id: '2',
        text: 'I\'m doing great! Just finished a new Flutter project.',
        timestamp: twoDaysAgo.add(const Duration(hours: 9, minutes: 35)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '3',
        text: 'Cool! Tell me more about it.',
        timestamp: twoDaysAgo.add(const Duration(hours: 9, minutes: 40)),
        isMe: false,
        sender: 'Alice',
      ),

      // Yesterday
      Message(
        id: '4',
        text: 'That sounds awesome! What kind of project?',
        timestamp: yesterday.add(const Duration(hours: 10, minutes: 15)),
        isMe: false,
        sender: 'Alice',
      ),
      Message(
        id: '5',
        text: 'It\'s a chat interface with advanced scrolling features',
        timestamp: yesterday.add(const Duration(hours: 10, minutes: 17)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '6',
        text: 'With sticky headers and floating date indicators!',
        timestamp: yesterday.add(const Duration(hours: 10, minutes: 18)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '7',
        text: 'The scroll behavior is really smooth',
        timestamp: yesterday.add(const Duration(hours: 10, minutes: 20)),
        isMe: true,
        sender: 'Me',
      ),

      // Today
      Message(
        id: '8',
        text: 'Wow, that sounds really cool!',
        timestamp: today.add(const Duration(hours: 8, minutes: 30)),
        isMe: false,
        sender: 'Alice',
      ),
      Message(
        id: '9',
        text: 'Can you show me how it works?',
        timestamp: today.add(const Duration(hours: 8, minutes: 32)),
        isMe: false,
        sender: 'Alice',
      ),
      Message(
        id: '10',
        text: 'Sure! The interface groups messages by date automatically',
        timestamp: today.add(const Duration(hours: 8, minutes: 35)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '11',
        text: 'And it has smooth animations for the floating header',
        timestamp: today.add(const Duration(hours: 8, minutes: 36)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '12',
        text: 'Plus a scroll-to-bottom button that appears intelligently',
        timestamp: today.add(const Duration(hours: 8, minutes: 37)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '13',
        text: 'Try scrolling up to see the floating header in action!',
        timestamp: today.add(const Duration(hours: 8, minutes: 38)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '14',
        text: 'And scroll down to see the scroll-to-bottom button',
        timestamp: today.add(const Duration(hours: 8, minutes: 39)),
        isMe: true,
        sender: 'Me',
      ),
      Message(
        id: '15',
        text: 'This is amazing! Great work!',
        timestamp: today.add(const Duration(hours: 8, minutes: 42)),
        isMe: false,
        sender: 'Alice',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Demo'),
        backgroundColor: Colors.blue[500],
        foregroundColor: Colors.white,
      ),
      body: ChatMessageView(
        messages: messages,
        onMessageTap: (messageId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tapped message: $messageId'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}