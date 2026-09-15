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

  String? get _url => widget.resource['resource_url']?.toString();

  int? get _readingMinutes {
    final value = widget.resource['estimated_read_minutes'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;

    setState(() {
      _isBookmarking = true;
    });

    try {
      final newState = await _resourceService.toggleBookmark(
        resourceId: widget.resource['id'].toString(),
        currentlySaved: _isSaved,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = newState;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isSaved
                  ? 'Resource saved to bookmarks.'
                  : 'Resource removed from bookmarks.',
            ),
          ),
        );
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
        'This resource does not have a valid URL.',
      );
      return;
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'https' || uri.scheme == 'http')) {
      _showMessage(
        'This resource URL is invalid.',
      );
      return;
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Open External Link',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You’re leaving Tibok and will be redirected to an external website.',
              ),
              const SizedBox(height: 12),
              Text(
                url,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) return;

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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Resource',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(_category),
              ),
              if (_readingMinutes != null)
                Chip(
                  avatar: const Icon(
                    Icons.schedule,
                    size: 16,
                  ),
                  label: Text(
                    '${_readingMinutes!} min read',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _source,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _openResource,
            icon: const Icon(
              Icons.open_in_new,
            ),
            label: const Text(
              'Open Resource',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isBookmarking ? null : _toggleBookmark,
            icon: _isBookmarking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
            label: Text(
              _isSaved ? 'Saved to Bookmarks' : 'Save to Bookmarks',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
