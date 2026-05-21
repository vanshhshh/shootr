enum ChatMessageType { text, image, location, quickReply }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
    this.type = ChatMessageType.text,
    this.isRead = false,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final ChatMessageType type;
  final bool isRead;

  ChatMessage copyWith({bool? isRead}) {
    return ChatMessage(
      id: id,
      bookingId: bookingId,
      senderId: senderId,
      senderName: senderName,
      body: body,
      sentAt: sentAt,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}
