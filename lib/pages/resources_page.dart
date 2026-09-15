import 'package:flutter/material.dart';

import '../services/resource_service.dart';
import 'resource_preview_page.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({
    super.key,
  });

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final ResourceService _service = ResourceService();

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedTab = 'All';

  List<Map<String, dynamic>> _resources = [];
  Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final resources = await _service.getResources();

      final savedIds = await _service.getSavedResourceIds();

      if (!mounted) return;

      setState(() {
        _resources = resources;
        _savedIds = savedIds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredResources {
    final query = _searchController.text.trim().toLowerCase();

    return _resources.where((resource) {
      final id = resource['id']?.toString() ?? '';

      if (_selectedTab == 'Bookmarks' && !_savedIds.contains(id)) {
        return false;
      }

      if (_selectedTab == 'Articles') {
        final type = resource['resource_type']?.toString().toLowerCase() ?? '';

        if (type != 'article') {
          return false;
        }
      }

      if (_selectedTab == 'Recipes') {
        final type = resource['resource_type']?.toString().toLowerCase() ?? '';

        if (type != 'recipe') {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      final title = resource['title']?.toString().toLowerCase() ?? '';

      final description =
          resource['description']?.toString().toLowerCase() ?? '';

      final source = resource['source_name']?.toString().toLowerCase() ?? '';

      return title.contains(query) ||
          description.contains(query) ||
          source.contains(query);
    }).toList();
  }

  Future<void> _openResource(
    Map<String, dynamic> resource,
  ) async {
    final id = resource['id'].toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResourcePreviewPage(
          resource: resource,
          initiallySaved: _savedIds.contains(id),
        ),
      ),
    );

    if (mounted) {
      await _loadResources();
    }
  }

  Future<void> _toggleBookmark(
    Map<String, dynamic> resource,
  ) async {
    final id = resource['id'].toString();

    final isSaved = _savedIds.contains(id);

    try {
      final newState = await _service.toggleBookmark(
        resourceId: id,
        currentlySaved: isSaved,
      );

      if (!mounted) return;

      setState(() {
        if (newState) {
          _savedIds.add(id);
        } else {
          _savedIds.remove(id);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update bookmark.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Resources',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadResources,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load health resources.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadResources,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    final resources = _filteredResources;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Search health resources...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All',
              'Articles',
              'Recipes',
              'Bookmarks',
            ].map(
              (tab) {
                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: _selectedTab == tab,
                    onSelected: (_) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                  ),
                );
              },
            ).toList(),
          ),
        ),
        const SizedBox(height: 18),
        if (resources.isEmpty)
          _buildEmptyState()
        else
          ...resources.map(
            _buildResourceCard,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: Column(
        children: [
          Icon(
            _selectedTab == 'Bookmarks'
                ? Icons.bookmark_border
                : Icons.menu_book_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            _selectedTab == 'Bookmarks'
                ? 'No saved resources yet'
                : 'No resources found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 'Bookmarks'
                ? 'Bookmark useful resources to find them here.'
                : 'Try a different search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    Map<String, dynamic> resource,
  ) {
    final id = resource['id'].toString();

    final title = resource['title']?.toString() ?? 'Health Resource';

    final description = resource['description']?.toString() ?? '';

    final source = resource['source_name']?.toString() ?? 'External Resource';

    final category = resource['topic_category']?.toString() ?? 'Health';

    final type = resource['resource_type']?.toString() ?? 'article';

    final saved = _savedIds.contains(id);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openResource(resource);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  type.toLowerCase() == 'recipe'
                      ? Icons.restaurant_menu
                      : Icons.article_outlined,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '$category • $source',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: saved ? 'Remove bookmark' : 'Save bookmark',
                onPressed: () {
                  _toggleBookmark(
                    resource,
                  );
                },
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
