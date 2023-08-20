import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/services/v2.0/user_info.dart';

class CommunitiesListSection extends StatelessWidget {
  const CommunitiesListSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KC2UserInfo?>(
        valueListenable: kc2User.userInfo,
        builder: (context, value, child) {
          if (value == null) {
            return CupertinoListTile.notched(
              title: Text(
                'Your are not a member of any community.',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .textStyle
                    .merge(const TextStyle(fontSize: 14)),
              ),
              onTap: () => {
                // TODO: show community web page on site
              },
            );
          }

          return ListView.builder(
              shrinkWrap: true,
              itemCount: value.communityMemberships.length,
              itemBuilder: (context, index) {
                return _getCommunityTile(
                    context, value.communityMemberships[index]);
              });
        });
  }

  Widget _getCommunityTile(BuildContext context, CommunityMembership value) {
    Community? community = GenesisConfig.communities[value.communityId];
    if (community == null) {
      return Container();
    }

    if (value.isAdmin) {
      return CupertinoListTile.notched(
        title: Text(community.name),
        subtitle: const Text('ADMIN'),
        leading: Text(community.emoji, style: const TextStyle(fontSize: 24)),
        trailing: const CupertinoListTileChevron(),
        onTap: () =>
            context.push(GenesisConfig.communityHomeScreenPaths[community.id]!),
      );
    }

    return CupertinoListTile.notched(
      title: Text(community.name),
      leading: Text(community.emoji, style: const TextStyle(fontSize: 24)),
      trailing: const CupertinoListTileChevron(),
      onTap: () =>
          context.push(GenesisConfig.communityHomeScreenPaths[community.id]!),
    );
  }
}
