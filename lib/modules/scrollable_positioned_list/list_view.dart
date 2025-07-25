import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/dummy_generator.dart';
import '../../data/models/message_model.dart';

//const numberOfItems = 100;
const minItemHeight = 15.0;
const maxItemHeight = 150.0;
const scrollDuration = Duration(milliseconds: 300);

const randomMax = 1 << 32;

class ScrollablePositionedListView extends StatefulWidget {
  const ScrollablePositionedListView({super.key});

  @override
  State<ScrollablePositionedListView> createState() => _ScrollablePositionedListViewState();
}

class _ScrollablePositionedListViewState extends State<ScrollablePositionedListView> {
  List<MessageModel> messages = [];

  /// Controller to scroll or jump to a particular item.
  final ItemScrollController itemScrollController = ItemScrollController();

  /// Controller to scroll a certain number of pixels relative to the current
  /// scroll offset.
  final ScrollOffsetController scrollOffsetController =
  ScrollOffsetController();

  /// Listener that reports the position of items when the list is scrolled.
  final ItemPositionsListener itemPositionsListener =
  ItemPositionsListener.create();
  late List<double> itemHeights;
  late List<Color> itemColors;
  bool reversed = true;

  /// The alignment to be used next time the user scrolls or jumps to an item.
  double alignment = 0;


  @override
  void initState() {
    messages = DummyData().generateDummyData(count: 3000);
    super.initState();
    final heightGenerator = Random(328902348);
    final colorGenerator = Random(42490823);
    itemHeights = List<double>.generate(
        messages.length,
            (int _) =>
        heightGenerator.nextDouble() * (maxItemHeight - minItemHeight) +
            minItemHeight);
    itemColors = List<Color>.generate(messages.length,
            (int _) => Color(colorGenerator.nextInt(randomMax)).withOpacity(1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Scrollable Positioned List", style: TextStyle(fontSize: 18),),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) => Column(
          children: <Widget>[
            Expanded(
              child: list(orientation),
            ),
            positionsView,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    scrollControlButtons,
                    //scrollOffsetControlButtons,
                    const SizedBox(height: 10),
                    jumpControlButtons,
                    alignmentControl,
                  ],
                ),
              ],
            )
          ],
        ),
      )
    );
  }

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

  Widget list(Orientation orientation) => ScrollablePositionedList.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) => item(index, orientation),
    itemScrollController: itemScrollController,
    itemPositionsListener: itemPositionsListener,
    scrollOffsetController: scrollOffsetController,
    reverse: reversed,
    scrollDirection: orientation == Orientation.portrait
        ? Axis.vertical
        : Axis.horizontal,
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
          const Text('Reversed: '),
          Checkbox(
              value: reversed,
              onChanged: (bool? value) => setState(() {
                reversed = value!;
              }))
        ],
      );
    },
  );

  Widget get scrollControlButtons => Row(
    children: <Widget>[
      const Text('scroll to'),
      scrollItemButton(0),
      scrollItemButton(1),
      scrollItemButton(40),
      scrollItemButton(70),
      scrollItemButton(99),
    ],
  );

  Widget get scrollOffsetControlButtons => Row(
    children: <Widget>[
      const Text('scroll by'),
      scrollOffsetButton(-30),
      scrollOffsetButton(-20),
      scrollOffsetButton(-10),
      scrollOffsetButton(10),
      scrollOffsetButton(20),
      scrollOffsetButton(30),
    ],
  );

  Widget get jumpControlButtons => Row(
    children: <Widget>[
      const Text('jump to'),
      jumpButton(1),
      jumpButton(10),
      jumpButton(40),
      jumpButton(70),
      jumpButton(99),
    ],
  );

  ButtonStyle _scrollButtonStyle({required double horizonalPadding}) =>
      ButtonStyle(
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(horizontal: horizonalPadding, vertical: 0),
        ),
        minimumSize: MaterialStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  Widget scrollItemButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollTo(value),
    child: Text('$value'),
    style: _scrollButtonStyle(horizonalPadding: 20),
  );

  Widget scrollOffsetButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollBy(value.toDouble()),
    child: Text('$value'),
    style: _scrollButtonStyle(horizonalPadding: 10),
  );

  Widget scrollPixelButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollTo(value),
    child: Text('$value'),
    style: _scrollButtonStyle(horizonalPadding: 20),
  );

  Widget jumpButton(int value) => TextButton(
    key: ValueKey<String>('Jump$value'),
    onPressed: () => jumpTo(value),
    child: Text('$value'),
    style: _scrollButtonStyle(horizonalPadding: 20),
  );

  void scrollTo(int index) => itemScrollController.scrollTo(
      index: index,
      duration: scrollDuration,
      curve: Curves.easeInOutCubic,
      alignment: alignment);

  void scrollBy(double offset) => scrollOffsetController.animateScroll(
      offset: offset, duration: scrollDuration, curve: Curves.easeInOutCubic);

  void jumpTo(int index) =>
      itemScrollController.jumpTo(index: index, alignment: alignment);

  /// Generate item number [i].
  Widget item(int i, Orientation orientation) {
    final details = messages[i];
    return SizedBox(
      height: orientation == Orientation.portrait ? itemHeights[i] : null,
      width: orientation == Orientation.landscape ? itemHeights[i] : null,
      child: Container(
        color: itemColors[i],
        child: Center(
          child: Text("${details.message}, ${DateFormat('dd-MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(details.timeStampMillis))}"),
        ),
      ),
    );
  }

}
