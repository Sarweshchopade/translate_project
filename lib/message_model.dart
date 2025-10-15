class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(json['text'], json['isUser']);
}