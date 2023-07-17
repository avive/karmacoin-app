class Event {
  String phase;
  int extrinsicIndex;
  String pallet;
  String eventName;
  dynamic data;

  Event.fromSubstrateEvent(Map<String, dynamic> event)
      : phase = event['phase'].key,
      extrinsicIndex = event['phase'].value,
      pallet = event['event'].key,
      eventName = event['event'].value.key,
      data = event['event'].value.value;
}
