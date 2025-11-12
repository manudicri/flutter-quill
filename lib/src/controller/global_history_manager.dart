import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../quill_delta.dart';
import '../document/document.dart';
import '../document/structs/doc_change.dart';
import 'quill_controller.dart';

class GlobalHistoryEntry {
  GlobalHistoryEntry({
    required this.controller,
    required this.controllerId,
    required this.beforeDelta,
    required this.afterDelta,
    required this.changeDelta,
    required this.timestamp,
    required this.changeIndex,
  });
  final QuillController controller;
  final String controllerId;
  final Delta beforeDelta;
  final Delta afterDelta;
  final Delta changeDelta;
  final DateTime timestamp;
  final int changeIndex;

  @override
  String toString() {
    return 'GlobalHistoryEntry(controllerId: $controllerId, timestamp: $timestamp, changeIndex: $changeIndex)';
  }
}

class GlobalHistoryManager extends ChangeNotifier {
  factory GlobalHistoryManager() => _instance;
  GlobalHistoryManager._internal();
  static final GlobalHistoryManager _instance =
      GlobalHistoryManager._internal();

  final List<GlobalHistoryEntry> _globalHistory = [];
  int _currentIndex = -1;
  int _changeCounter = 0;

  final Map<QuillController, String> _registeredControllers = {};
  final Map<QuillController, StreamSubscription<DocChange>> _subscriptions = {};

  bool _isUndoRedoInProgress = false;

  static const int maxHistorySize = 1000;
  static const Duration changeGroupInterval = Duration(milliseconds: 400);

  void registerController(QuillController controller, String controllerId) {
    if (_registeredControllers.containsKey(controller)) {
      debugPrint(
          'GlobalHistoryManager: Controller già registrato: $controllerId');
      return;
    }

    _registeredControllers[controller] = controllerId;

    _subscriptions[controller] = controller.changes.listen(
      (docChange) => _handleDocChange(controller, controllerId, docChange),
      onError: (error) => debugPrint('GlobalHistoryManager error: $error'),
    );

    debugPrint('GlobalHistoryManager: Controller registrato: $controllerId');
    notifyListeners();
  }

  void unregisterController(QuillController controller) {
    final controllerId = _registeredControllers[controller];
    if (controllerId == null) return;

    _subscriptions[controller]?.cancel();
    _subscriptions.remove(controller);
    _registeredControllers.remove(controller);

    _globalHistory.removeWhere((entry) => entry.controller == controller);

    if (_currentIndex >= _globalHistory.length) {
      _currentIndex = _globalHistory.length - 1;
    }

    debugPrint('GlobalHistoryManager: Controller rimosso: $controllerId');
    notifyListeners();
  }

  void _handleDocChange(
      QuillController controller, String controllerId, DocChange docChange) {
    if (_isUndoRedoInProgress) return;

    if (docChange.source != ChangeSource.local) return;

    if (docChange.change.isEmpty) return;

    debugPrint('GlobalHistoryManager: Registrando cambio per $controllerId');

    final afterDelta = docChange.before.compose(docChange.change);

    final entry = GlobalHistoryEntry(
      controller: controller,
      controllerId: controllerId,
      beforeDelta: docChange.before,
      afterDelta: afterDelta,
      changeDelta: docChange.change,
      timestamp: DateTime.now(),
      changeIndex: _changeCounter++,
    );

    _addEntryToHistory(entry);
  }

  void _addEntryToHistory(GlobalHistoryEntry entry) {
    if (_currentIndex < _globalHistory.length - 1) {
      _globalHistory.removeRange(_currentIndex + 1, _globalHistory.length);
    }

    _globalHistory.add(entry);
    _currentIndex = _globalHistory.length - 1;

    if (_globalHistory.length > maxHistorySize) {
      _globalHistory.removeAt(0);
      _currentIndex--;
    }

    debugPrint(
        'GlobalHistoryManager: History size: ${_globalHistory.length}, current index: $_currentIndex');
    notifyListeners();
  }

  bool canUndo() => _currentIndex >= 0 && _globalHistory.isNotEmpty;

  bool canRedo() => _currentIndex < _globalHistory.length - 1;

  void undo() {
    if (!canUndo()) {
      debugPrint('GlobalHistoryManager: Impossibile fare undo');
      return;
    }

    final entry = _globalHistory[_currentIndex];
    debugPrint('GlobalHistoryManager: Undo su ${entry.controllerId}');

    _isUndoRedoInProgress = true;

    try {
      final controller = entry.controller;

      final currentLength = controller.document.length - 1;
      controller.replaceText(
        0,
        currentLength,
        entry.beforeDelta,
        TextSelection.collapsed(offset: entry.beforeDelta.length),
      );

      _currentIndex--;
      debugPrint(
          'GlobalHistoryManager: Undo completato, nuovo index: $_currentIndex');
    } catch (e) {
      debugPrint('GlobalHistoryManager: Errore durante undo: $e');
    } finally {
      _isUndoRedoInProgress = false;
    }

    notifyListeners();
  }

  void redo() {
    if (!canRedo()) {
      debugPrint('GlobalHistoryManager: Impossibile fare redo');
      return;
    }

    _currentIndex++;
    final entry = _globalHistory[_currentIndex];
    debugPrint('GlobalHistoryManager: Redo su ${entry.controllerId}');

    _isUndoRedoInProgress = true;

    try {
      final controller = entry.controller;

      final currentLength = controller.document.length - 1;
      controller.replaceText(
        0,
        currentLength,
        entry.afterDelta,
        TextSelection.collapsed(offset: entry.afterDelta.length),
      );

      debugPrint(
          'GlobalHistoryManager: Redo completato, index: $_currentIndex');
    } catch (e) {
      debugPrint('GlobalHistoryManager: Errore durante redo: $e');
    } finally {
      _isUndoRedoInProgress = false;
    }

    notifyListeners();
  }

  void clearHistory() {
    _globalHistory.clear();
    _currentIndex = -1;
    _changeCounter = 0;
    debugPrint('GlobalHistoryManager: History pulita');
    notifyListeners();
  }

  List<GlobalHistoryEntry> getHistoryEntries() =>
      List.unmodifiable(_globalHistory);

  int get currentIndex => _currentIndex;

  int get historySize => _globalHistory.length;

  List<String> getRegisteredControllerIds() =>
      _registeredControllers.values.toList();

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _registeredControllers.clear();
    clearHistory();

    super.dispose();
  }
}
