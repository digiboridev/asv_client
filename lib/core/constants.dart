import 'package:asv_client/core/env.dart';

final kRTCPeerConfig = {
  'iceServers': [
    // {'urls': 'stun:stun.l.google.com:19302'},
    // {'urls': 'stun:stun1.l.google.com:19302'},
    // {'urls': 'stun:stun2.l.google.com:19302'},
    // {'urls': 'stun:stun3.l.google.com:19302'},
    // {'urls': 'stun:stun4.l.google.com:19302'},
    {
      "urls": "stun:stun.relay.metered.ca:80",
    },
    {
      "urls": "turn:a.relay.metered.ca:80",
      "username": Env.turnU,
      "credential": Env.turnC,
    },
    {
      "urls": "turn:a.relay.metered.ca:80?transport=tcp",
      "username": Env.turnU,
      "credential": Env.turnC,
    },
    {
      "urls": "turn:a.relay.metered.ca:443",
      "username": Env.turnU,
      "credential": Env.turnC,
    },
    {
      "urls": "turn:a.relay.metered.ca:443?transport=tcp",
      "username": Env.turnU,
      "credential": Env.turnC,
    },
  ],
  'sdpSemantics': 'unified-plan',
};
