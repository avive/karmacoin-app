import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/api/types.pb.dart';

String getCommunitiesBadge(Contact contact) {
  String badge = '';
  for (CommunityMembership m in contact.communityMemberships) {
    Community? c = GenesisConfig.communities[m.communityId];
    if (c == null) {
      continue;
    }
    badge += '${c.emoji} ';

    if (m.isAdmin) {
      badge += '👑 ';
    }
  }

  return badge.trim();
}
