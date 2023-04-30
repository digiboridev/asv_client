import 'package:equatable/equatable.dart';

abstract class ChatEntry {
  final DateTime time;
  const ChatEntry(this.time);

  factory ChatEntry.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'message':
        return Message.fromJson(json);
      case 'user_joined':
        return UserJoined.fromJson(json);
      case 'user_left':
        return UserLeft.fromJson(json);
      default:
        throw Exception('Unimplemented ChatEntry type');
    }
  }

  Map<String, dynamic> toJson();

  factory ChatEntry.userJoined(String userName) => UserJoined(userName, DateTime.now());
  factory ChatEntry.userLeft(String userName) => UserLeft(userName, DateTime.now());
  factory ChatEntry.message(String userName, String message) => Message(userName, message, DateTime.now());
}

class UserJoined extends ChatEntry with EquatableMixin {
  final String userName;
  final String _type = 'user_joined';

  const UserJoined(this.userName, super.time);

  @override
  factory UserJoined.fromJson(Map<String, dynamic> json) {
    return UserJoined(
      json['userName'] as String,
      DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userName': userName,
      'time': time.millisecondsSinceEpoch,
      'type': _type,
    };
  }

  @override
  List<Object> get props => [userName];

  @override
  bool get stringify => true;
}

class UserLeft extends ChatEntry with EquatableMixin {
  final String userName;
  final String _type = 'user_left';

  const UserLeft(this.userName, super.time);

  @override
  factory UserLeft.fromJson(Map<String, dynamic> json) {
    return UserLeft(
      json['userName'] as String,
      DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userName': userName,
      'time': time.millisecondsSinceEpoch,
      'type': _type,
    };
  }

  @override
  List<Object> get props => [userName];

  @override
  bool get stringify => true;
}

class Message extends ChatEntry with EquatableMixin {
  final String userName;
  final String message;
  final String _type = 'message';

  const Message(this.userName, this.message, super.time);

  @override
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      json['userName'] as String,
      json['message'] as String,
      DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userName': userName,
      'message': message,
      'time': time.millisecondsSinceEpoch,
      'type': _type,
    };
  }

  @override
  List<Object> get props => [userName, message, time];

  @override
  bool get stringify => true;
}
