import 'package:flutter/material.dart';
import 'package:list_demo/modules/scrollable_positioned_list/list_view.dart';

import 'modules/custom_list_view/custom_list_2_view.dart';
import 'modules/custom_list_view/custom_list_view.dart';
import 'modules/grouped_list/grouped_list_view.dart';
import 'modules/sticky_grouped_list/stick_list_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const ScrollablePositionedListView(),
      home: const StickyGroupedView(),
      // home: const GroupedListViewView(),
      // home: const CustomListView(),
      // home: CustomList2View(),
    );
  }
}
