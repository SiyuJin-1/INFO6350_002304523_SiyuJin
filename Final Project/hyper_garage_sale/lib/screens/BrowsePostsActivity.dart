import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import 'NewPostActivity.dart';
import 'PostDetailScreen.dart';

enum _PriceSort {
  none,
  lowToHigh,
  highToLow,
}

class BrowsePostsScreen extends StatefulWidget {
  const BrowsePostsScreen({super.key});

  @override
  State<BrowsePostsScreen> createState() => _BrowsePostsScreenState();
}

class _BrowsePostsScreenState extends State<BrowsePostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  bool _showSearchBar = false;
  _PriceSort _priceSort = _PriceSort.none;

  bool get _isGuest {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  void _showGuestNotAllowed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to create a post')),
    );
  }

  Future<void> _openNewPost() async {
    if (_isGuest) {
      _showGuestNotAllowed();
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewPostScreen()),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New post added')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchTerm = '';
      }
    });
  }

  void _applySearch() {
    setState(() {
      _searchTerm = _searchController.text.trim().toLowerCase();
    });
  }

  double _parsePrice(String price) {
    final cleaned = price.replaceAll(RegExp(r'[^\d\.]'), '');
    return double.tryParse(cleaned.isEmpty ? '0' : cleaned) ?? 0.0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceColor = Colors.orange.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Post'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchBar,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new') {
                _openNewPost();
              } else if (value == 'sort_low') {
                setState(() {
                  _priceSort = _PriceSort.lowToHigh;
                });
              } else if (value == 'sort_high') {
                setState(() {
                  _priceSort = _PriceSort.highToLow;
                });
              } else if (value == 'sort_none') {
                setState(() {
                  _priceSort = _PriceSort.none;
                });
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];

              if (!_isGuest) {
                items.add(
                  const PopupMenuItem(
                    value: 'new',
                    child: Text('New Post'),
                  ),
                );
                items.add(const PopupMenuDivider());
              }

              items.addAll(const [
                PopupMenuItem(
                  value: 'sort_low',
                  child: Text('Sort by price ↑'),
                ),
                PopupMenuItem(
                  value: 'sort_high',
                  child: Text('Sort by price ↓'),
                ),
                PopupMenuItem(
                  value: 'sort_none',
                  child: Text('Clear price sort'),
                ),
              ]);

              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by title or description',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _applySearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _applySearch,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.postsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  if (_searchTerm.isEmpty) return true;
                  final data = doc.data();
                  final title =
                  (data['title'] as String? ?? '').toLowerCase();
                  final desc =
                  (data['description'] as String? ?? '').toLowerCase();
                  return title.contains(_searchTerm) ||
                      desc.contains(_searchTerm);
                }).toList();

                if (_priceSort != _PriceSort.none) {
                  filteredDocs.sort((a, b) {
                    final da = a.data();
                    final db = b.data();
                    final pa =
                    _parsePrice(da['price'] as String? ?? '');
                    final pb =
                    _parsePrice(db['price'] as String? ?? '');
                    if (_priceSort == _PriceSort.lowToHigh) {
                      return pa.compareTo(pb);
                    } else {
                      return pb.compareTo(pa);
                    }
                  });
                }

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchTerm.isEmpty
                          ? 'No posts yet.\nTap + to add one!'
                          : 'No posts match "$_searchTerm".',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();

                    final title = data['title'] as String? ?? '';
                    final price = data['price'] as String? ?? '';
                    final description =
                    (data['description'] as String? ?? '').trim();
                    final sellerName =
                        data['sellerName'] as String? ?? 'Unknown seller';
                    final List<dynamic>? dynUrls =
                    data['imageUrls'] as List<dynamic>?;
                    final imageUrls =
                        dynUrls?.map((e) => e.toString()).toList() ??
                            <String>[];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _MarketCard(
                        title: title,
                        description: description.isEmpty
                            ? 'No description'
                            : description,
                        price: price,
                        imageUrl:
                        imageUrls.isNotEmpty ? imageUrls.first : null,
                        priceColor: priceColor,
                        sellerName: sellerName,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                postId: doc.id,
                                title: title,
                                price: price,
                                description: description,
                                imageUrls: imageUrls,
                                sellerName: sellerName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: _isGuest
          ? null
          : FloatingActionButton(
        onPressed: _openNewPost,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String? imageUrl;
  final Color priceColor;
  final String sellerName;
  final VoidCallback onTap;

  const _MarketCard({
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.priceColor,
    required this.sellerName,
    required this.onTap,
  });

  String _formatPrice(String raw) {
    final trimmed = raw.trim();
    final noSymbol = trimmed.replaceFirst(RegExp(r'^[\$💲]\s*'), '');
    return '\$$noSymbol';
  }

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(price);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: priceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seller: $sellerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
