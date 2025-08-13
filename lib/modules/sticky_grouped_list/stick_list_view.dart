import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:list_demo/data/models/message_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

import '../../data/dummy_generator.dart';
import '../scrollable_positioned_list/list_view.dart';

class StickyGroupedView extends StatefulWidget {
  const StickyGroupedView({super.key});

  @override
  State<StickyGroupedView> createState() => _StickyGroupedViewState();
}

class _StickyGroupedViewState extends State<StickyGroupedView> {
  late List<double> itemHeights;
  late List<Color> itemColors;
  List<MessageModel> messages = [];

  final GroupedItemScrollController itemScrollController =
      GroupedItemScrollController();
  final ItemPositionsListener itemPositionsListener =
  ItemPositionsListener.create();

  double alignment = 0.25;

  final ValueNotifier<bool> showFloatingHeaderNotifier = ValueNotifier(true);
  final ValueNotifier<String> dateHeaderNotifier = ValueNotifier("");
  Timer? _hideHeaderTimer;

  @override
  void initState() {
    final heightGenerator = math.Random(328902348);
    final colorGenerator = math.Random(42490823);
    messages = DummyData().generateDummyData(count: 30);

    itemHeights = List<double>.generate(
        messages.length,
            (int _) =>
        heightGenerator.nextDouble() * (maxItemHeight - minItemHeight) +
            minItemHeight);
    itemColors = List<Color>.generate(
      messages.length,
      (int _) => Color(colorGenerator.nextInt(randomMax)).withValues(alpha: 1),
    );
    super.initState();
  }

  void _onScroll() {
    if (!showFloatingHeaderNotifier.value) {
      Future.microtask(()=> showFloatingHeaderNotifier.value = true);
    }
    _hideHeaderTimer?.cancel();
    _hideHeaderTimer = Timer(const Duration(seconds: 2), () {
      if(showFloatingHeaderNotifier.value){
        Future.microtask(()=> showFloatingHeaderNotifier.value = false);
      }
    });
  }

  @override
  void dispose() {
    _hideHeaderTimer?.cancel();
    showFloatingHeaderNotifier.dispose();
    super.dispose();
  }

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _updateFloatingHeaderDate(int last) {
    final Map<String, List<MessageModel>> grouped = {};
    for (final message in messages.reversed) {
      final key = _formatDate(message.timeStampMillis);
      grouped.putIfAbsent(key, () => []).add(message);
    }
    // print("***********, last: $last");
    int index = last;
    grouped.forEach((k, v){
      if(index < -1){
        return;
      }
      index--;
      // print("-- group: $k, index:$index");
      for(var item in v){
        // print("\t\titem: ${_formatDate(item.timeStampMillis)}, index: $index");
        if(index <= 0){
          // print("Header date: ${_formatDate(item.timeStampMillis)}");
          Future.microtask(()=> dateHeaderNotifier.value = _formatDate(item.timeStampMillis));
        }
        index--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Icon(Icons.arrow_back_ios_new, color: Colors.black),
        title: Text(
          "Scrollable Positioned List",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          ///user details
          Container(
            height: 70,
            color: Colors.pinkAccent,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CircleAvatar(
                    radius: 20,
                  ),
                ),
                Text(
                    "John Doe"
                )
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: StickyGroupedListView<MessageModel, DateTime>(
                        itemScrollController: itemScrollController,
                        itemPositionsListener: itemPositionsListener,
                        elements: messages,
                        groupBy: (MessageModel element) {
                          DateTime date = DateTime.fromMillisecondsSinceEpoch(
                            element.timeStampMillis,
                          );
                          return DateTime(date.year, date.month, date.day);
                        },
                        groupSeparatorBuilder: (MessageModel details) {
                          //return SizedBox.shrink();
                          return Text(
                            _formatDate(details.timeStampMillis),
                            textAlign: TextAlign.center,
                          );
                        },
                        indexedItemBuilder: (_, details, index){
                          return Container(
                            height: itemHeights[index],
                            color: itemColors[index],
                            child: Center(
                              child: Text(
                                "Index: $index, Id: ${details.id}, ${details.message}",
                                style: TextStyle(
                                    color: Colors.white
                                ),
                              ),
                            ),
                          );
                        },
                        itemComparator: (m1, m2) => m1.timeStampMillis.compareTo(m2.timeStampMillis),
                        elementIdentifier: (element) => element.id,
                        order: StickyGroupedListOrder.DESC,
                        reverse: true,
                        floatingHeader: false,
                      ),
                    ),
                    positionsView,
                    scrollControlButtons,
                    alignmentControl,
                    //SafeArea(child: SizedBox(height: 0)),
                  ],
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: showFloatingHeaderNotifier,
                    builder: (context, showFloatingHeader2, _) {
                      if(showFloatingHeader2){
                        return ValueListenableBuilder<String>(
                            valueListenable: dateHeaderNotifier,
                            builder: (context, floatingDate, _) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: 20,
                                  color: Colors.red,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        floatingDate,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }
                        );
                      }else{
                        return SizedBox.shrink();
                      }
                    }
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: scrollToBottomView,
    );
  }

  Widget get scrollToBottomView => ValueListenableBuilder<Iterable<ItemPosition>>(
    valueListenable: itemPositionsListener.itemPositions,
    builder: (context, positions, child) {
      //return SizedBox.shrink();
      int? min;
      if (positions.isNotEmpty) {
        min = positions
            .where((ItemPosition position) => position.itemTrailingEdge > 0)
            .reduce((ItemPosition min, ItemPosition position) =>
        position.itemTrailingEdge < min.itemTrailingEdge
            ? position
            : min)
            .index;
      }
      if(min != null){
        if(min >= 1){
          return FloatingActionButton(
            onPressed: (){
              scrollTo(0);
            },
            child: Icon(CupertinoIcons.down_arrow),
          );
        }
      }
     return SizedBox.shrink();
    },
  );

  Widget get positionsView => ValueListenableBuilder<Iterable<ItemPosition>>(
    valueListenable: itemPositionsListener.itemPositions,
    builder: (context, positions, child) {
      _onScroll();

      int? min;
      int? max;
      if (positions.isEmpty) {
        return SizedBox.shrink();
      }

      // Determine the first visible item by finding the item with the
      // smallest trailing edge that is greater than 0.  i.e. the first
      // item whose trailing edge in visible in the viewport.
      min = positions
          .where((ItemPosition position) => position.itemTrailingEdge > 0)
          .reduce((ItemPosition min, ItemPosition position) =>
      position.itemTrailingEdge < min.itemTrailingEdge
          ? position
          : min)
          .index;
      // Determine the last visible item by finding the item with the
      // greatest leading edge that is less than 1.  i.e. the last
      // item whose leading edge in visible in the viewport.
      max = positions
          .where((ItemPosition position) => position.itemLeadingEdge < 0.97)
          .reduce((ItemPosition max, ItemPosition position) =>
      position.itemLeadingEdge > max.itemLeadingEdge
          ? position
          : max)
          .index;

      /*log("=============");
      for(var item in positions){
        log("${item.toString()}");
      }*/


      _updateFloatingHeaderDate(max);
      return Row(
        children: <Widget>[
          Expanded(child: Text('First Item: $min')),
          Expanded(child: Text('Last Item: $max')),
        ],
      );
    },
  );

  Widget get scrollControlButtons => Wrap(
    children: <Widget>[
      const Text('scroll to'),
      scrollItemButton(0),
      scrollItemButton(5),
      scrollItemButton(10),
      scrollItemButton(15),
      scrollItemButton(18),
    ],
  );

  Widget scrollItemButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollToElement(value),
    style: _scrollButtonStyle(horizontalPadding: 20),
    child: Text('$value'),
  );

  void scrollTo(int index) => itemScrollController.scrollTo(
      index: index,
      duration: scrollDuration,
      curve: Curves.easeInOutCubic,
      automaticAlignment: false,
      alignment: alignment);

  void scrollToElement(int id) => itemScrollController.scrollToElement(
      identifier: id,
      duration: scrollDuration,
      curve: Curves.easeInOutCubic,
      automaticAlignment: false,
      alignment: alignment);

  ButtonStyle _scrollButtonStyle({required double horizontalPadding}) =>
      ButtonStyle(
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
        ),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  Widget get alignmentControl => Row(
    mainAxisSize: MainAxisSize.max,
    children: <Widget>[
      const Text('Alignment: '),
      SizedBox(
        width: 200,
        child: SliderTheme(
          data: SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: Slider(
            value: alignment,
            label: alignment.toStringAsFixed(2),
            onChanged: (double value) => setState(() => alignment = value),
          ),
        ),
      ),
    ],
  );
}
