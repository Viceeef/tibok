import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final settings = AppSettingsController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accessibility & Display',
        ),
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (
          context,
          child,
        ) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              32,
            ),
            children: [
              _buildIntroCard(
                context,
              ),
              const SizedBox(
                height: 24,
              ),
              Semantics(
                header: true,
                child: Text(
                  'Text Size',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Choose the size that is most comfortable to read.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(
                height: 14,
              ),
              for (final size in AppTextSize.values) ...[
                _TextSizeOption(
                  size: size,
                  selected: settings.textSize == size,
                  onTap: () {
                    settings.setTextSize(
                      size,
                    );
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
              const SizedBox(
                height: 14,
              ),
              _buildPreviewCard(
                context,
                settings,
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                padding: const EdgeInsets.all(
                  16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.phone_android_outlined,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        'Tibok also respects your phone\'s system text-size setting. '
                        'Your Tibok preference is added on top of it.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              OutlinedButton.icon(
                onPressed: settings.textSize == AppTextSize.standard
                    ? null
                    : settings.resetTextSize,
                icon: const Icon(
                  Icons.restart_alt,
                ),
                label: const Text(
                  'Reset to Normal',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroCard(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Made to be easier to read',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Increase Tibok\'s text size without changing your health records or app data.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    AppSettingsController settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Preview',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Text(
                    settings.textSize.percentageLabel,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Today\'s Sodium Intake',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'Track your food and blood pressure with clear, readable information.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TextSizeOption extends StatelessWidget {
  const _TextSizeOption({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final AppTextSize size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '${size.label} text, ${size.percentageLabel}',
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            18,
          ),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 74,
            ),
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 14 * size.scaleFactor,
                      fontWeight: FontWeight.w800,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        size.label,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${size.description} • ${size.percentageLabel}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.outline,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
