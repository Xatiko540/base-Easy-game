enum ProfileSessionStatus { disconnected, connected, registered }

ProfileSessionStatus resolveProfileSessionStatus({
  required bool walletConnected,
  required bool playerExists,
}) {
  if (!walletConnected) return ProfileSessionStatus.disconnected;
  return playerExists
      ? ProfileSessionStatus.registered
      : ProfileSessionStatus.connected;
}
