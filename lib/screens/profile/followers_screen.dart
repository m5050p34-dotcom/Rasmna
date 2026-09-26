import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/profile_model.dart';
import '../../services/follows_service.dart';
import '../../utils/app_theme.dart';
import 'photographer_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true = المتابعون، false = المتابَعون

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final _service = FollowsService();
  List<ProfileModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final users = widget.showFollowers
          ? await _service.getFollowers(widget.userId)
          : await _service.getFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showFollowers ? 'المتابعون' : 'يتابع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.showFollowers
                              ? Icons.people_outline
                              : Icons.person_add_outlined,
                          size: 80,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.showFollowers
                              ? 'لا يوجد متابعون بعد'
                              : 'لا يتابع أحداً بعد',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.15),
                            backgroundImage: (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: (user.avatarUrl == null ||
                                    user.avatarUrl!.isEmpty)
                                ? Text(
                                    user.initial,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: user.bio != null && user.bio!.isNotEmpty
                              ? Text(
                                  user.bio!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PhotographerScreen(userId: user.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
