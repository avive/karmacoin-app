import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';

class Block {
  BigInt blockNumber;
  late String blockHash;
  List<KC2Event> events = [];

  Block({required this.blockNumber});

  Future<void> init() async {
    final String blockNumberString = '0x${blockNumber.toRadixString(16)}';
    blockHash = await kc2Service.karmachain
        .send('chain_getBlockHash', [blockNumberString]).then((v) => v.result);
    events = await _getBlockEvents(blockHash);
  }

  /// Returns tx events for a specific transaction in a block
  Future<List<KC2Event>> getTransactionEvents(int transactionIndex) async {
    try {
      final transactionEvents = events
          .where((event) => event.extrinsicIndex == transactionIndex)
          .toList();

      return transactionEvents;
    } catch (e) {
      debugPrint('>>>> error getting tx events: $e');
      rethrow;
    }
  }

  /// Retrieves events for this accessing `System` pallet storage
  /// return decoded events
  Future<List<KC2Event>> _getBlockEvents(String blockHash) async {
    try {
      final value = await kc2Service.readStorage('System', 'Events');

      final List<KC2Event> events = kc2Service.chainInfo.scaleCodec
          .decode('EventCodec', ByteInput(value!))
          .map<KC2Event>((e) => KC2Event.fromSubstrateEvent(e))
          .toList();

      return events;
    } catch (e) {
      debugPrint('Failed to get events: $e');
      rethrow;
    }
  }
}
