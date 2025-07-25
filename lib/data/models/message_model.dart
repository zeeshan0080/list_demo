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
