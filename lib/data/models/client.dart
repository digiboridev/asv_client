import 'dart:convert';
import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({required this.clientId, required this.name});

  final String clientId;
  final String name;

  Client copyWith({
    String? clientId,
    String? name,
  }) {
    return Client(
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clientId': clientId,
      'name': name,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      clientId: map['clientId'] as String,
      name: map['name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) => Client.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [clientId, name];
}
