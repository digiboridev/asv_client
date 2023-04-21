// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';

// import 'package:equatable/equatable.dart';
// import 'package:flutter/foundation.dart';

// @immutable
// class Message extends Equatable {
//   Message({
//     required this.text,
//     required this.clientId,
//     DateTime? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now();

//   final String text;
//   final String clientId;
//   final DateTime createdAt;

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'text': text,
//       'clientId': clientId,
//       'createdAt': createdAt.millisecondsSinceEpoch,
//     };
//   }

//   factory Message.fromMap(Map<String, dynamic> map) {
//     return Message(
//       text: map['text'] as String,
//       clientId: map['clientId'] as String,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
//     );
//   }

//   @override
//   bool get stringify => true;

//   @override
//   List<Object> get props => [text, clientId, createdAt];

//   Message copyWith({
//     String? text,
//     String? clientId,
//     DateTime? createdAt,
//   }) {
//     return Message(
//       text: text ?? this.text,
//       clientId: clientId ?? this.clientId,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory Message.fromJson(String source) => Message.fromMap(json.decode(source) as Map<String, dynamic>);
// }
