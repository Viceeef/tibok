import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/resource_service.dart';

class ResourcePreviewPage extends StatefulWidget {
  const ResourcePreviewPage({
    super.key,
    required this.resource,
    required this.initiallySaved,
  });

  final Map<String, dynamic> resource;
  final bool initiallySaved;

  @override
  State<ResourcePreviewPage> createState() => _ResourcePreviewPageState();
}

class _ResourcePreviewPageState extends State<ResourcePreviewPage> {
  final ResourceService _resourceService = ResourceService();

  late bool _isSaved;

  bool _isBookmarking = false;

  @override
  void initState() {
    super.initState();

    _isSaved = widget.initiallySaved;
  }

  String get _title =>
      widget.resource['title']?.toString() ?? 'Health Resource';

  String get _description =>
      widget.resource['description']?.toString() ?? 'No description available.';

  String get _source =>
      widget.resource['source_name']?.toString() ?? 'External Resource';

  String get _category =>
      widget.resource['topic_category']?.toString() ?? 'Health';

  String get _type => widget.resource['resource_type']?.toString() ?? 'article';

  String? get _url => widget.resource['resource_url']?.toString();

  int? get _readingMinutes {
    final value = widget.resource['estimated_read_minutes'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  String get _typeLabel {
    if (_type.toLowerCase() == 'recipe') {
      return 'Recipe';
    }

    return 'Article';
  }

  IconData get _resourceIcon {
    if (_type.toLowerCase() == 'recipe') {
      return Icons.restaurant_menu_rounded;
    }

    return Icons.article_outlined;
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) {
      return;
    }

    setState(() {
      _isBookmarking = true;
    });

    try {
      final newState = await _resourceService.toggleBookmark(
        resourceId: widget.resource['id'].toString(),
        currentlySaved: _isSaved,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaved = newState;
      });

      _showMessage(
        _isSaved ? 'Saved to bookmarks.' : 'Removed from bookmarks.',
      );
    } catch (_) {
      _showMessage(
        'Could not update bookmark.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarking = false;
        });
      }
    }
  }

  Future<void> _openResource() async {
    final url = _url;

    if (url == null || url.trim().isEmpty) {
      _showMessage(
        'This resource does not have a valid web address.',
      );
      return;
    }

    final uri = Uri.tryParse(
      url.trim(),
    );

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'https' || uri.scheme == 'http')) {
      _showMessage(
        'This resource web address is invalid.',
      );
      return;
    }

    final host = uri.host.isEmpty
        ? url
        : uri.host.replaceFirst(
            'www.',
            '',
          );

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Open External Website?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will leave Tibok and open a website from $_source.',
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      host,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              icon: const Icon(
                Icons.open_in_new_rounded,
              ),
              label: const Text(
                'Open Website',
              ),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) {
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        'Could not open the external resource.',
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Resource',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    _resourceIcon,
                    color: colors.onPrimaryContainer,
                    size: 29,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Text(
                    _title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(
                          width: 9,
                        ),
                        Expanded(
                          child: Text(
                            _source,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        _buildMetaItem(
                          icon: _resourceIcon,
                          text: _typeLabel,
                        ),
                        _buildMetaItem(
                          icon: Icons.favorite_outline_rounded,
                          text: _category,
                        ),
                        if (_readingMinutes != null)
                          _buildMetaItem(
                            icon: Icons.schedule_outlined,
                            text: '${_readingMinutes!} min read',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            Semantics(
              header: true,
              child: Text(
                'Overview',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _description,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(
              height: 28,
            ),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: _openResource,
                icon: const Icon(
                  Icons.open_in_new_rounded,
                ),
                label: const Text(
                  'Open Resource',
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBookmarking ? null : _toggleBookmark,
                icon: _isBookmarking
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                label: Text(
                  _isSaved ? 'Saved to Bookmarks' : 'Save to Bookmarks',
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    'Health resources open in your web browser. '
                    'They provide educational information and do not replace medical care.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          size: 18,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
