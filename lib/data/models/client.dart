import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Client extends Equatable {
  /// Private constructor
  const Client._({required this.clientId, required this.name});

  /// Creates a new client with a unique id and the base name
  factory Client.empty() {
    String uuid = Uuid().v4();
    String name = 'Guest${uuid.hashCode.toString().substring(0, 4)}';
    return Client._(clientId: uuid, name: name);
  }

  final String clientId;
  final String name;

  Client copyWith({String? clientId, String? name}) {
    return Client._(clientId: clientId ?? this.clientId, name: name ?? this.name);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'clientId': clientId, 'name': name};
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client._(clientId: map['clientId'] as String, name: map['name'] as String);
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) => Client.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [clientId, name];
}
