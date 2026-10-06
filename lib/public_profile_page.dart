import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

class PublicProfilePage extends StatefulWidget {
  final int userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<PublicProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getPublicProfile(widget.userId);
  }

  void _reload() {
    setState(() => _profileFuture = ApiService.getPublicProfile(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('โปรไฟล์สมาชิก'),
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<PublicProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kGreen),
            );
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          return _buildProfile(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildProfile(PublicProfile profile) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Center(
        child: AvatarCircle(
          url: profile.avatarUrl,
          name: profile.fullName,
          radius: 52,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        profile.fullName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kInk,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (profile.nickname != null && profile.nickname != profile.fullName) ...[
        const SizedBox(height: 3),
        Text(
          '(${profile.nickname})',
          textAlign: TextAlign.center,
          style: const TextStyle(color: kNeutral),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stars(profile.averageRating, size: 20),
          const SizedBox(width: 8),
          Text(
            profile.reviewCount == 0
                ? 'ยังไม่มีรีวิว'
                : '${profile.averageRating.toStringAsFixed(1)} · ${profile.reviewCount} รีวิว',
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 28),
      const Text(
        'รีวิวจากสมาชิก',
        style: TextStyle(
          color: kInk,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      if (profile.reviews.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'เมื่อร่วมกิจกรรมแล้ว รีวิวจะแสดงที่นี่',
            style: TextStyle(color: kNeutral),
          ),
        )
      else
        for (var index = 0; index < profile.reviews.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          _review(profile.reviews[index]),
        ],
    ],
  );

  Widget _review(PublicReview review) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          AvatarCircle(
            url: review.reviewerAvatarUrl,
            name: review.reviewerName,
            radius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _dateLabel(review.createdAt),
                  style: const TextStyle(color: kNeutral, fontSize: 12),
                ),
              ],
            ),
          ),
          _stars(review.rating.toDouble(), size: 15),
        ],
      ),
      if (review.comment.trim().isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(review.comment, style: const TextStyle(height: 1.45)),
      ],
    ],
  );

  Widget _stars(double rating, {required double size}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 1; index <= 5; index++)
        Icon(
          index <= rating.round() ? Icons.star : Icons.star_border,
          color: const Color(0xFFF2A900),
          size: size,
        ),
    ],
  );

  String _dateLabel(String value) =>
      value.length >= 10 ? value.substring(0, 10) : value;
}
