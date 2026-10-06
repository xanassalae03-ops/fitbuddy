import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'models.dart';

class EventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onTap;
  final bool showRole;

  const EventCard({super.key, required this.event, required this.onTap, this.showRole = false});

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: kMint, child: Icon(event.icon, color: kGreenDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${event.eventDate} • ${event.locationName}', style: const TextStyle(color: kMuted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  UserAvatar(url: event.host.avatar, size: 24),
                  const SizedBox(width: 6),
                  Text(event.host.displayName, style: const TextStyle(color: kNavy, fontSize: 13)),
                ],
              ),
              OutlinedButton(onPressed: onTap, child: const Text('ดูรายละเอียด')),
            ],
          ),
        ],
      ),
    );
  }
}