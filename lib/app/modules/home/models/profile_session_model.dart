enum ProfileSessionStatus { disconnected, connected, registered }

ProfileSessionStatus resolveProfileSessionStatus({
  required bool walletAuthenticated,
  required bool playerExists,
}) {
  if (!walletAuthenticated) return ProfileSessionStatus.disconnected;
  return playerExists
      ? ProfileSessionStatus.registered
      : ProfileSessionStatus.connected;
}
