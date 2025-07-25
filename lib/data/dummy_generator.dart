
import 'package:list_demo/data/models/message_model.dart';

class DummyData{

  List<MessageModel> generateDummyData({int count=20}){
    List<MessageModel> messages = [];
    for(int i=0; i<count; i++){
      int id = i+1;
      messages.add(MessageModel.fake(
        id: id,
        message: "Test message $id",
        timeStampMillis: DateTime.now().subtract(Duration(days: id)).millisecondsSinceEpoch
      ));
    }
    return messages;
  }
}