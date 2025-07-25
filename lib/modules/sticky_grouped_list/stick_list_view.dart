import 'dart:math';

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

  @override
  void initState() {
    final heightGenerator = Random(328902348);
    final colorGenerator = Random(42490823);
    messages = DummyData().generateDummyData(count: 200);

    itemHeights = List<double>.generate(
        messages.length,
            (int _) =>
        heightGenerator.nextDouble() * (maxItemHeight - minItemHeight) +
            minItemHeight);
    itemColors = List<Color>.generate(
      messages.length,
      (int _) => Color(colorGenerator.nextInt(randomMax)).withOpacity(1),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "Scrollable Positioned List",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Column(
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
                  DateFormat('dd-MMMM-yyyy').format(
                    DateTime.fromMillisecondsSinceEpoch(
                      details.timeStampMillis,
                    ),
                  ),
                );
              },
              indexedItemBuilder: (_, details, index){
                return Container(
                  height: itemHeights[index],
                  color: itemColors[index],
                  child: Center(
                    child: Text(
                      "${details.message}, id: ${details.id}",
                      style: TextStyle(
                        color: Colors.white
                      ),
                    ),
                  ),
                );
              },
              itemComparator: (m1, m2) => m1.timeStampMillis.compareTo(m2.timeStampMillis),
              //elementIdentifier: (element) => element.id,
              order: StickyGroupedListOrder.DESC,
              reverse: true,
              floatingHeader: true,
            ),
          ),
          positionsView,
          scrollControlButtons,
          alignmentControl,
          //SafeArea(child: SizedBox(height: 0)),
        ],
      ),
      floatingActionButton: scrollToBottomView,
    );
  }

  Widget get scrollToBottomView => ValueListenableBuilder<Iterable<ItemPosition>>(
    valueListenable: itemPositionsListener.itemPositions,
    builder: (context, positions, child) {
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
      int? min;
      int? max;
      if (positions.isNotEmpty) {
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
            .where((ItemPosition position) => position.itemLeadingEdge < 1)
            .reduce((ItemPosition max, ItemPosition position) =>
        position.itemLeadingEdge > max.itemLeadingEdge
            ? position
            : max)
            .index;
      }
      return Row(
        children: <Widget>[
          Expanded(child: Text('First Item: ${min ?? ''}')),
          Expanded(child: Text('Last Item: ${max ?? ''}')),
        ],
      );
    },
  );

  Widget get scrollControlButtons => Wrap(
    children: <Widget>[
      const Text('scroll to'),
      scrollItemButton(0),
      scrollItemButton(1),
      scrollItemButton(7),
      scrollItemButton(40),
      scrollItemButton(70),
    ],
  );

  Widget scrollItemButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollTo(value),
    child: Text('$value'),
    style: _scrollButtonStyle(horizonalPadding: 20),
  );

  void scrollTo(int index) => itemScrollController.scrollTo(
      index: index,
      duration: scrollDuration,
      curve: Curves.easeInOutCubic,
      automaticAlignment: false,
      alignment: alignment);

  ButtonStyle _scrollButtonStyle({required double horizonalPadding}) =>
      ButtonStyle(
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(horizontal: horizonalPadding, vertical: 0),
        ),
        minimumSize: MaterialStateProperty.all(Size.zero),
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
