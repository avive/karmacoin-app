import 'package:convert/convert.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/error.dart';
import 'package:karma_coin/services/v2.0/event.dart';
import 'package:karma_coin/services/v2.0/txs/tx.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';
import 'package:ss58/ss58.dart' as ss58;

enum DestinationType { unknown, accountId, username, phoneNumberHash }

/// A basic appreciation tx based on on-chain data only
/// Use KC2EnrichedAppreciationTxV1 for additional on-chain data
class KC2AppreciationTxV1 extends KC2Tx {
  String fromAddress;

  String? fromUserName;

  // non-null if appreciation was to a phone number hash or enriched
  String? toPhoneNumberHash;

  // non-null if appreciation was to a username or enriched
  String? toUserName;

  // non-null if appreciation was to an account id enriched
  String? toAccountId;

  BigInt amount;
  int? communityId;
  int? charTraitId;

  DestinationType destinationType = DestinationType.unknown;

  /// Create an appreciation tx from the provided tx data w/o any RPC enrichment's
  static Future<KC2AppreciationTxV1> createAppreciationTx(
      {required String hash,
      required int timestamp,
      required String signer,
      required Map<String, dynamic> args,
      required ChainError? chainError,
      required BigInt blockNumber,
      required int blockIndex,
      required Map<String, dynamic> rawData,
      required List<KC2Event> txEvents,
      required int netId}) async {
    try {
      // debugPrint("Appreciation tx args: $args");
      final to = args['to'];
      final accountIdentityType = to.key;
      final accountIdentityValue = to.value;

      final BigInt amount = args['amount'];
      final int? communityId = args['community_id'].value;
      final int? charTraitId = args['char_trait_id'].value;

      String? toAccountId;
      String? toUserName;
      String? toPhoneNumberHash;

      DestinationType destinationType = DestinationType.unknown;

      // Extract one of the destination fields from the tx
      switch (accountIdentityType) {
        case 'AccountId':
          toAccountId =
              ss58.Codec(netId).encode(accountIdentityValue.cast<int>());
          destinationType = DestinationType.accountId;
          break;
        case 'Username':
          toUserName = accountIdentityValue;
          destinationType = DestinationType.username;
          break;
        case 'PhoneNumberHash':
        default:
          toPhoneNumberHash = hex.encode(accountIdentityValue.cast<int>());
          destinationType = DestinationType.phoneNumberHash;
          break;
      }

      return KC2AppreciationTxV1(
          fromAddress: signer,
          toPhoneNumberHash: toPhoneNumberHash,
          toUserName: toUserName,
          toAccountId: toAccountId,
          amount: amount,
          communityId: communityId,
          charTraitId: charTraitId,
          args: args,
          signer: signer,
          chainError: chainError,
          timestamp: timestamp,
          hash: hash,
          blockNumber: blockNumber,
          blockIndex: blockIndex,
          transactionEvents: txEvents,
          rawData: rawData,
          destinationType: destinationType);
    } catch (e) {
      debugPrint("Error processing appreciation tx: $e");
      rethrow;
    }
  }

  KC2AppreciationTxV1(
      {required this.fromAddress,
      this.toPhoneNumberHash,
      this.toAccountId,
      this.toUserName,
      required this.amount,
      this.communityId = 0,
      this.charTraitId = 0,
      required super.transactionEvents,
      required super.args,
      required super.chainError,
      required super.timestamp,
      required super.hash,
      required super.blockNumber,
      required super.blockIndex,
      required super.rawData,
      required super.signer,
      required this.destinationType});

  String getTitle() {
    if (charTraitId != null &&
        charTraitId != 0 &&
        charTraitId! < GenesisConfig.personalityTraits.length) {
      PersonalityTrait trait = GenesisConfig.personalityTraits[charTraitId!];
      return '${trait.emoji} You are ${trait.name.toLowerCase()}';
    } else {
      return '🤑 Karma Coin Transfer';
    }
  }

  /// Enrich the tx with additional data from the chain based on sender, receiver
  /// and a local user identity
  /// userInfo - local user info
  Future<void> enrichForUser(KC2UserInfo userInfo) async {
    // the other user for this tx
    KC2UserInfo? otherUserInfo;

    // compute fromUserName
    if (signer == userInfo.accountId) {
      fromUserName = userInfo.userName;
    } else {
      otherUserInfo = await kc2Service.getUserInfoByAccountId(signer);
      if (otherUserInfo != null) {
        fromUserName = otherUserInfo.userName;
      } else {
        debugPrint(
            'Warning: account not found on chain for tx signer: $signer');
      }
    }

    switch (destinationType) {
      case DestinationType.accountId:
        // tx was sent for an accountId
        if (toAccountId == signer) {
          // appreciation is to the local user
          toUserName = userInfo.userName;
          toPhoneNumberHash = userInfo.phoneNumberHash;
        } else {
          // receiver is not the local user
          otherUserInfo ??=
              await kc2Service.getUserInfoByAccountId(toAccountId!);
          // complete tx data fields from obtained info
          if (otherUserInfo != null) {
            toUserName = otherUserInfo.userName;
            toPhoneNumberHash = otherUserInfo.phoneNumberHash;
          } else {
            debugPrint(
                'Warning: account not found on chain for receiver $toAccountId');
          }
        }
        break;
      case DestinationType.username:
        // tx dest is a user name
        if (signer == userInfo.accountId) {
          // appreciation is from the local user
          // get other user by username and fill missing info
          otherUserInfo ??= await kc2Service.getUserInfoByUserName(toUserName!);
          if (otherUserInfo != null) {
            toAccountId = otherUserInfo.accountId;
            toPhoneNumberHash = otherUserInfo.phoneNumberHash;
          } else {
            debugPrint(
                'Warning: account not found on chain for receiver $toAccountId');
          }
        } else {
          // appreciation to local user
          toAccountId = userInfo.accountId;
          toPhoneNumberHash = userInfo.phoneNumberHash;
        }
        break;
      case DestinationType.phoneNumberHash:
        // tx is to a phone number hash
        if (signer == userInfo.accountId) {
          // tx from local user - get other user by phone hash and fill info
          otherUserInfo ??=
              await kc2Service.getUserInfoByPhoneNumberHash(toPhoneNumberHash!);
          if (otherUserInfo != null) {
            toAccountId = otherUserInfo.accountId;
            toUserName = otherUserInfo.userName;
          } else {
            debugPrint('Warning: account not found on chain for $toAccountId');
          }
        } else {
          // tx is to local user
          toAccountId = userInfo.accountId;
          toUserName = userInfo.userName;
        }
        break;
      default:
        throw 'Unsupported destination type: $destinationType';
    }
  }
}
