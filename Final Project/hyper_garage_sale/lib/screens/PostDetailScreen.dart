import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/firebase_service.dart';
import 'FullImageScreen.dart';

class PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const PostImageCarousel({
    super.key,
    required this.imageUrls,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.photo_outlined,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final url = images[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageScreen(imageUrl: url),
                    ),
                  );
                },
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageScreen(imageUrl: url),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF8E24AA)
                    : Colors.grey.withOpacity(0.4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String title;
  final String price;
  final String description;
  final List<String> imageUrls;
  final String sellerName;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.sellerName,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  bool get _isGuest {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;
    return user.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    FirebaseService.incrementPostView(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to post a comment.'),
        ),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty || _isSendingComment) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      await FirebaseService.addComment(
        postId: widget.postId,
        text: text,
      );
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  Widget _buildCommentsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.commentsStream(widget.postId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      docs.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E24AA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isGuest) ...[
                const SizedBox(height: 4),
                Text(
                  'Sign in to join the discussion.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Text(
                    'No comments yet. Be the first one!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final name = (data['authorName'] ?? '') as String;
                    final text = (data['text'] ?? '') as String;
                    final ts = data['createdAt'] as Timestamp?;
                    final timeString =
                    ts == null ? '' : _formatTimeAgo(ts.toDate());

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.person, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeString,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 3,
                      enabled: !_isGuest,
                      decoration: InputDecoration(
                        hintText: _isGuest
                            ? 'Sign in to write a comment'
                            : 'Write a comment...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSendingComment
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(
                      Icons.send,
                      color: _isGuest
                          ? Colors.grey
                          : const Color(0xFF8E24AA),
                    ),
                    onPressed:
                    (_isGuest || _isSendingComment) ? null : _sendComment,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    final weeks = diff.inDays ~/ 7;
    return '${weeks}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        elevation: 0,
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3D5FF),
              Color(0xFFF9ECFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ],
                  ),
                  child: StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseService.postStream(widget.postId),
                    builder: (context, snapshot) {
                      final postData = snapshot.data?.data();

                      final title =
                          (postData?['title'] as String?) ?? widget.title;
                      final priceStr =
                          (postData?['price'] as String?) ?? widget.price;
                      final description = (postData?['description']
                      as String?) ??
                          widget.description;
                      final sellerName = (postData?['sellerName']
                      as String?) ??
                          widget.sellerName;
                      final views =
                          (postData?['viewsCount'] as int?) ?? 0;

                      final List<String> imageUrls =
                          (postData?['imageUrls'] as List?)
                              ?.cast<String>() ??
                              widget.imageUrls;

                      final num? latNum = postData?['meetupLat'] as num?;
                      final num? lngNum = postData?['meetupLng'] as num?;
                      final String? meetupAddress =
                      postData?['meetupAddress'] as String?;

                      final LatLng? meetupLatLng =
                      (latNum != null && lngNum != null)
                          ? LatLng(
                          latNum.toDouble(), lngNum.toDouble())
                          : null;

                      final String priceText =
                      priceStr.trim().startsWith('\$') ||
                          priceStr.trim().startsWith('\$')
                          ? priceStr.trim()
                          : '\$${priceStr.trim()}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Seller',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          PostImageCarousel(
                            imageUrls: imageUrls,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8E24AA),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Spacer(),
                              Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$views views',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            description.isEmpty
                                ? 'No description provided.'
                                : description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Meet-up location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: meetupLatLng == null
                                    ? Colors.grey
                                    : const Color(0xFF8E24AA),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  meetupAddress ??
                                      'No meet-up address provided.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: meetupLatLng == null
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (meetupLatLng != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                height: 200,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: meetupLatLng,
                                    zoom: 14,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('meetup'),
                                      position: meetupLatLng,
                                    ),
                                  },
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  tiltGesturesEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'No map location for this post.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                _buildCommentsSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
