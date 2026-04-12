import 'package:flutter/material.dart';
import 'package:mysudoku/database/database_manager.dart';
import 'package:mysudoku/l10n/app_localizations.dart';

class StartupCatalogPreparingGate extends StatefulWidget {
  const StartupCatalogPreparingGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StartupCatalogPreparingGate> createState() =>
      _StartupCatalogPreparingGateState();
}

class _StartupCatalogPreparingGateState extends State<StartupCatalogPreparingGate> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late PuzzleCatalogStatus _status;
  bool _isPreparing = false;
  bool _isReady = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _status = _databaseManager.catalogStatus.value;
    _databaseManager.catalogStatus.addListener(_handleCatalogStatusChanged);
    _prepareCatalog();
  }

  @override
  void dispose() {
    _databaseManager.catalogStatus.removeListener(_handleCatalogStatusChanged);
    super.dispose();
  }

  void _handleCatalogStatusChanged() {
    if (!mounted) return;
    setState(() {
      _status = _databaseManager.catalogStatus.value;
    });
  }

  Future<void> _prepareCatalog() async {
    if (_isPreparing) {
      return;
    }
    setState(() {
      _isPreparing = true;
      _error = null;
    });

    try {
      await _databaseManager.ensureCatalogFullyPrepared();
      _databaseManager.markInitialCatalogIntroSeen();
      if (!mounted) return;
      setState(() {
        _status = _databaseManager.catalogStatus.value;
        _isReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final retryLabel =
        Localizations.localeOf(context).languageCode == 'ko' ? '다시 시도' : 'Retry';
    final total = _status.totalTarget;
    final generated = _status.totalGenerated.clamp(0, total);
    final remaining = (total - generated).clamp(0, total);
    final progress = total > 0 ? generated / total : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_download_rounded,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.homeCatalogPreparingTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeCatalogProgressDetail(generated, total, remaining),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _isPreparing ? null : _prepareCatalog,
                      child: Text(retryLabel),
                    ),
                  ],
                  if (_error == null) ...[
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
