enum RTCConnectionState {
  /// The connection attempt failed.
  failed,

  /// The connection has been established and communication is possible.
  connected,

  /// The connection is in the process of becoming connected.
  connecting,

  /// The connection is new and not yet connected.
  idle,
}
