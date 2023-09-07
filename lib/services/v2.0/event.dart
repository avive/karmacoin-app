class KC2Event {
  String phase;
  int? extrinsicIndex;
  String pallet;
  String eventName;
  dynamic data;

  KC2Event({
    required this.phase,
    required this.extrinsicIndex,
    required this.pallet,
    required this.eventName,
    required this.data,
  });

  KC2Event.fromSubstrateEvent(Map<String, dynamic> event)
      : phase = event['phase'].key,
        extrinsicIndex = event['phase'].value,
        pallet = event['event'].key,
        eventName = event['event'].value.key,
        data = event['event'].value.value;

  factory KC2Event.fromJson(Map<String, dynamic> event) {
    // Safety: only one entry in phase
    final phaseEntry = event['phase'].entries.first;
    final phase = phaseEntry.key;
    final extrinsicIndex = phaseEntry.value;

    // Parsing event that represented as following string:
    // 'RuntimeEvent::$PALLET_NAME(Event::$EVENT_NAME { $EVENT_DATA })
    final rawEvent = event['event'];
    List<String> parts = rawEvent.split('(');

    final pallet = parts[0].replaceAll('RuntimeEvent::', '').trim();
    parts.removeAt(0);

    parts = parts.join('(').split('{');

    final eventName = parts[0].replaceAll('Event::', '').trim();
    parts.removeAt(0);

    // TODO: @HolyGrease - please fix this
    // $EVENT_DATA is represented as { id: 1 } for example so jsonDecode fails
    // to do this as it expected { "id": 1 }
    Map<String, dynamic> data = {};

    return KC2Event(
      phase: phase,
      extrinsicIndex: extrinsicIndex,
      pallet: pallet,
      eventName: eventName,
      data: data,
    );
  }
}
