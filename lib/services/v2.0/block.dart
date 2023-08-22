import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/interfaces.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';

class Block {
  /// Returns tx events for a specific transaction in a block
  static Future<List<KC2Event>> getTransactionEvents(BigInt blockNumber,
      int transactionIndex, ChainApiProvider apiProvider) async {
    try {
      final String blockNumberString = '0x${blockNumber.toRadixString(16)}';
      final blockHash = await apiProvider.karmachain.send(
          'chain_getBlockHash', [blockNumberString]).then((v) => v.result);
      final events = await getBlockEvents(blockHash, apiProvider);
      final transactionEvents = events
          .where((event) => event.extrinsicIndex == transactionIndex)
          .toList();

      return transactionEvents;
    } catch (e) {
      debugPrint('>>>> error getting tx events: $e');
      rethrow;
    }
  }

  /// Retrieves events for specific block by accessing `System` pallet storage
  /// return decoded events
  static Future<List<KC2Event>> getBlockEvents(
      String blockHash, ChainApiProvider apiProvider) async {
    try {
      final value = await apiProvider.readStorage('System', 'Events');

      final List<KC2Event> events = apiProvider.chainInfo.scaleCodec
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
