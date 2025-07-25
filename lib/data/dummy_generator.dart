import 'dart:math';

import 'package:list_demo/data/models/message_model.dart';

import '../modules/scrollable_positioned_list/list_view.dart';

class DummyData {
  List<MessageModel> generateDummyData({int count = 20}) {
    final idGenerator = Random(42490823);
    List<MessageModel> messages = [];
    for (int i = 0; i < count; i++) {
      messages.add(
        MessageModel.fake(
          id: idGenerator.nextInt(randomMax),
          message: "Test message $i",
          timeStampMillis:
              DateTime.now().subtract(Duration(days: i)).millisecondsSinceEpoch,
        ),
      );
      /*messages.add(
        MessageModel.fake(
          id: idGenerator.nextInt(randomMax),
          message: "Test message $i",
          timeStampMillis:
          DateTime.now().subtract(Duration(days: i)).millisecondsSinceEpoch,
        ),
      );
      messages.add(
        MessageModel.fake(
          id: idGenerator.nextInt(randomMax),
          message: "Test message $i",
          timeStampMillis:
          DateTime.now().subtract(Duration(days: i)).millisecondsSinceEpoch,
        ),
      );
      messages.add(
        MessageModel.fake(
          id: idGenerator.nextInt(randomMax),
          message: "Test message $i",
          timeStampMillis:
          DateTime.now().subtract(Duration(days: i)).millisecondsSinceEpoch,
        ),
      );*/
    }
    return messages;
  }
}
