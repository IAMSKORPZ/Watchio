import 'package:flutter/material.dart';
import 'package:another_iptv_player/models/api_response.dart';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'info_tile_widget.dart';
import 'section_title_widget.dart';
import 'package:another_iptv_player/shared/widgets/app_card.dart';

class ServerInfoWidget extends StatelessWidget {
  final ApiResponse serverInfo;

  const ServerInfoWidget({super.key, required this.serverInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitleWidget(title: context.loc.server_information),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InfoTileWidget(
                icon: Icons.public,
                label: context.loc.server_url,
                value: serverInfo.serverInfo.url,
              ),
              InfoTileWidget(
                icon: Icons.access_time,
                label: context.loc.timezone,
                value: serverInfo.serverInfo.timezone.isEmpty
                    ? context.loc.not_found_in_category
                    : serverInfo.serverInfo.timezone,
              ),
              InfoTileWidget(
                icon: Icons.message,
                label: context.loc.server_message,
                value: serverInfo.userInfo.message.isEmpty
                    ? context.loc.not_found_in_category
                    : serverInfo.userInfo.message,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
