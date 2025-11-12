import 'dart:async';
import 'package:flutter/material.dart';

import '../controller/global_history_manager.dart';

class GlobalUndoRedoToolbar extends StatefulWidget {
  const GlobalUndoRedoToolbar({
    super.key,
    this.iconSize = 18,
    this.undoTooltip = 'Global Undo',
    this.redoTooltip = 'Global Redo',
    this.undoIcon = Icons.undo_outlined,
    this.redoIcon = Icons.redo_outlined,
    this.showDebugInfo = false,
  });

  final double iconSize;
  final String undoTooltip;
  final String redoTooltip;
  final IconData undoIcon;
  final IconData redoIcon;
  final bool showDebugInfo;

  @override
  State<GlobalUndoRedoToolbar> createState() => _GlobalUndoRedoToolbarState();
}

class _GlobalUndoRedoToolbarState extends State<GlobalUndoRedoToolbar> {
  final GlobalHistoryManager _historyManager = GlobalHistoryManager();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    _historyManager.addListener(_updateState);

    _updateTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _historyManager.removeListener(_updateState);
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _historyManager.canUndo();
    final canRedo = _historyManager.canRedo();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(widget.undoIcon, size: widget.iconSize),
          onPressed: canUndo ? _historyManager.undo : null,
          tooltip: widget.undoTooltip,
          color: canUndo ? null : Colors.grey,
        ),
        IconButton(
          icon: Icon(widget.redoIcon, size: widget.iconSize),
          onPressed: canRedo ? _historyManager.redo : null,
          tooltip: widget.redoTooltip,
          color: canRedo ? null : Colors.grey,
        ),
        if (widget.showDebugInfo) ...[
          const SizedBox(width: 8),
          _buildDebugInfo(),
        ],
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'H: ${_historyManager.historySize} | I: ${_historyManager.currentIndex}',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

class GlobalHistoryDebugPanel extends StatefulWidget {
  const GlobalHistoryDebugPanel({super.key});

  @override
  State<GlobalHistoryDebugPanel> createState() =>
      _GlobalHistoryDebugPanelState();
}

class _GlobalHistoryDebugPanelState extends State<GlobalHistoryDebugPanel> {
  final GlobalHistoryManager _historyManager = GlobalHistoryManager();

  @override
  void initState() {
    super.initState();
    _historyManager.addListener(_updateState);
  }

  @override
  void dispose() {
    _historyManager.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _historyManager.getHistoryEntries();
    final currentIndex = _historyManager.currentIndex;
    final registeredControllers = _historyManager.getRegisteredControllerIds();

    return ExpansionTile(
      title: const Text('Global History Debug'),
      subtitle:
          Text('History: ${entries.length} entries, Index: $currentIndex'),
      children: [
        ListTile(
          title: const Text('Registered Controllers'),
          subtitle: Text(registeredControllers.join(', ')),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed:
                  _historyManager.canUndo() ? _historyManager.undo : null,
              child: const Text('Undo'),
            ),
            ElevatedButton(
              onPressed:
                  _historyManager.canRedo() ? _historyManager.redo : null,
              child: const Text('Redo'),
            ),
            ElevatedButton(
              onPressed: _historyManager.clearHistory,
              child: const Text('Clear'),
            ),
          ],
        ),
        if (entries.isNotEmpty) ...[
          const Divider(),
          const Text('History Entries:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isCurrent = index == currentIndex;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isCurrent ? Icons.arrow_right : Icons.circle,
                    size: 16,
                    color: isCurrent ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    entry.controllerId,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.blue : null,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.timestamp.toLocal().toString().split('.')[0]}\n'
                    'Change: ${entry.changeDelta.operations.length} ops',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Text('#${entry.changeIndex}'),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

mixin GlobalHistoryMixin<T extends StatefulWidget> on State<T> {
  GlobalHistoryManager get globalHistoryManager => GlobalHistoryManager();

  @override
  void dispose() {
    super.dispose();
  }

  void clearGlobalHistory() {
    globalHistoryManager.clearHistory();
  }

  bool get canGlobalUndo => globalHistoryManager.canUndo();
  bool get canGlobalRedo => globalHistoryManager.canRedo();

  void globalUndo() => globalHistoryManager.undo();
  void globalRedo() => globalHistoryManager.redo();
}
