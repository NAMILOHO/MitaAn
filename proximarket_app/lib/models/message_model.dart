class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.createdAt,
    this.isRead = false,
  });

  // Firestore → MessageModel
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  // MessageModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}