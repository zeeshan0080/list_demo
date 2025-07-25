class MessageModel {
  int id;
  String message;
  int timeStampMillis;

  MessageModel({
    required this.id,
    required this.message,
    required this.timeStampMillis,
  });

  factory MessageModel.fake({
    int id = 1,
    String message = "Test message 1",
    int? timeStampMillis
  }) {
    return MessageModel(
      id: id,
      message: message,
      timeStampMillis: timeStampMillis ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final DateTime timeStamp;

  ChatMessage({required this.id, required this.text, required this.timeStamp});

  factory ChatMessage.fake({
    String id = "1",
    String text = "Test message 1",
    DateTime? timeStamp
  }) {
    return ChatMessage(
      id: id,
      text: text,
      timeStamp: timeStamp ?? DateTime.now(),
    );
  }

}
