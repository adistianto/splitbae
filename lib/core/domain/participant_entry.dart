/// Participant row for UI and split (display order follows [sortOrder] in DB).
class ParticipantEntry {
  const ParticipantEntry({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}
