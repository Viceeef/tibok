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

      if (!mounted) {
        return;
      }

      setState(() {
        _resources = resources;
        _savedIds = savedIds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredResources {
    final query = _searchController.text.trim().toLowerCase();

    return _resources.where(
      (resource) {
        final id = resource['id']?.toString() ?? '';

        if (_selectedTab == 'Bookmarks' && !_savedIds.contains(id)) {
          return false;
        }

        final type = resource['resource_type']?.toString().toLowerCase() ?? '';

        if (_selectedTab == 'Articles' && type != 'article') {
          return false;
        }

        if (_selectedTab == 'Recipes' && type != 'recipe') {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final title = resource['title']?.toString().toLowerCase() ?? '';

        final description =
            resource['description']?.toString().toLowerCase() ?? '';

        final source = resource['source_name']?.toString().toLowerCase() ?? '';

        final category =
            resource['topic_category']?.toString().toLowerCase() ?? '';

        return title.contains(query) ||
            description.contains(query) ||
            source.contains(query) ||
            category.contains(query);
      },
    ).toList();
  }

  int? _readMinutes(
    Map<String, dynamic> resource,
  ) {
    final value = resource['estimated_read_minutes'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
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

      if (!mounted) {
        return;
      }

      setState(() {
        if (newState) {
          _savedIds.add(id);
        } else {
          _savedIds.remove(id);
        }
      });

      _showMessage(
        newState ? 'Saved to bookmarks.' : 'Removed from bookmarks.',
      );
    } catch (_) {
      _showMessage(
        'Could not update bookmark.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {});
  }

  IconData _resourceIcon(
    String type,
  ) {
    if (type.toLowerCase() == 'recipe') {
      return Icons.restaurant_menu_rounded;
    }

    return Icons.article_outlined;
  }

  String _resourceTypeLabel(
    String type,
  ) {
    if (type.toLowerCase() == 'recipe') {
      return 'Recipe';
    }

    return 'Article';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
      return _buildErrorState();
    }

    final resources = _filteredResources;

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        30,
      ),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Search resources',
            prefixIcon: const Icon(
              Icons.search_rounded,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
          ),
        ),
        const SizedBox(
          height: 14,
        ),
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
                    label: Text(
                      tab,
                    ),
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
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedTab == 'Bookmarks' ? 'Saved Resources' : 'Resources',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(
              '${resources.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
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
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 42,
          horizontal: 24,
        ),
        child: Column(
          children: [
            Icon(
              _selectedTab == 'Bookmarks'
                  ? Icons.bookmark_border_rounded
                  : Icons.menu_book_outlined,
              size: 54,
              color: colors.outline,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              _selectedTab == 'Bookmarks'
                  ? 'No saved resources yet'
                  : 'No resources found',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              _selectedTab == 'Bookmarks'
                  ? 'Save useful resources and they will appear here.'
                  : 'Try another search or category.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    Map<String, dynamic> resource,
  ) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final id = resource['id'].toString();

    final title = resource['title']?.toString() ?? 'Health Resource';

    final description = resource['description']?.toString() ?? '';

    final source = resource['source_name']?.toString() ?? 'External Resource';

    final category = resource['topic_category']?.toString() ?? 'Health';

    final type = resource['resource_type']?.toString() ?? 'article';

    final minutes = _readMinutes(
      resource,
    );

    final saved = _savedIds.contains(id);

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(
        alpha: 0.05,
      ),
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: () {
          _openResource(
            resource,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      _resourceIcon(
                        type,
                      ),
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  IconButton(
                    tooltip: saved ? 'Remove bookmark' : 'Save bookmark',
                    onPressed: () {
                      _toggleBookmark(
                        resource,
                      );
                    },
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(
                  height: 10,
                ),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(
                height: 12,
              ),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _buildMetaItem(
                    icon: type.toLowerCase() == 'recipe'
                        ? Icons.restaurant_outlined
                        : Icons.article_outlined,
                    text: _resourceTypeLabel(
                      type,
                    ),
                  ),
                  _buildMetaItem(
                    icon: Icons.favorite_outline_rounded,
                    text: category,
                  ),
                  if (minutes != null)
                    _buildMetaItem(
                      icon: Icons.schedule_outlined,
                      text: '$minutes min',
                    ),
                ],
              ),
              const SizedBox(
                height: 9,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Text(
                      source,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(
        24,
      ),
      children: [
        const SizedBox(
          height: 100,
        ),
        Icon(
          Icons.error_outline,
          size: 60,
          color: theme.colorScheme.error,
        ),
        const SizedBox(
          height: 14,
        ),
        Text(
          'Unable to load health resources.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 18,
        ),
        FilledButton.icon(
          onPressed: _loadResources,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Try Again',
          ),
        ),
      ],
    );
  }
}
