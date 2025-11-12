import 'package:flutter/widgets.dart';

import '../../quill_delta.dart';
import '../controller/global_history_manager.dart';
import '../controller/quill_controller.dart';

class SectionTextController {
  SectionTextController({required this.sectionId}) {
    _quillController = QuillController.basic();
    _quillNameController = QuillController.basic();

    _globalHistoryManager
      ..registerController(
        _quillController,
        '${sectionId}_content',
      )
      ..registerController(
        _quillNameController,
        '${sectionId}_name',
      );

    debugPrint('SectionTextController: Creato per sezione $sectionId');
  }

  factory SectionTextController.withContent({
    required String sectionId,
    String? initialName,
    String? initialContent,
  }) {
    final controller = SectionTextController(sectionId: sectionId);

    if (initialName != null && initialName.isNotEmpty) {
      controller.setName(initialName);
    }

    if (initialContent != null && initialContent.isNotEmpty) {
      controller.setContent(initialContent);
    }

    return controller;
  }
  late final QuillController _quillController;
  late final QuillController _quillNameController;
  final String sectionId;
  final GlobalHistoryManager _globalHistoryManager = GlobalHistoryManager();

  QuillController get quillController => _quillController;
  QuillController get quillNameController => _quillNameController;

  void setName(String name) {
    _quillNameController.replaceText(
      0,
      _quillNameController.document.length - 1,
      name,
      const TextSelection.collapsed(offset: 0),
    );
  }

  void setContent(String content) {
    _quillController.replaceText(
      0,
      _quillController.document.length - 1,
      content,
      const TextSelection.collapsed(offset: 0),
    );
  }

  String getName() {
    return _quillNameController.document.toPlainText().trim();
  }

  String getContent() {
    return _quillController.document.toPlainText();
  }

  Delta getNameDelta() {
    return _quillNameController.document.toDelta();
  }

  Delta getContentDelta() {
    return _quillController.document.toDelta();
  }

  bool get isEmpty {
    return getName().isEmpty && getContent().trim().isEmpty;
  }

  bool get isNotEmpty => !isEmpty;

  void clear() {
    _quillNameController.clear();
    _quillController.clear();
  }

  void insertTextInContent(int index, String text) {
    _quillController.replaceText(
      index,
      0,
      text,
      TextSelection.collapsed(offset: index + text.length),
    );
  }

  void insertTextInName(int index, String text) {
    _quillNameController.replaceText(
      index,
      0,
      text,
      TextSelection.collapsed(offset: index + text.length),
    );
  }

  void setReadOnly(bool readOnly) {
    _quillController.readOnly = readOnly;
    _quillNameController.readOnly = readOnly;
  }

  void addContentListener(VoidCallback listener) {
    _quillController.addListener(listener);
  }

  void addNameListener(VoidCallback listener) {
    _quillNameController.addListener(listener);
  }

  void removeContentListener(VoidCallback listener) {
    _quillController.removeListener(listener);
  }

  void removeNameListener(VoidCallback listener) {
    _quillNameController.removeListener(listener);
  }

  void dispose() {
    debugPrint('SectionTextController: Disposing sezione $sectionId');

    _globalHistoryManager
      ..unregisterController(_quillController)
      ..unregisterController(_quillNameController);

    _quillController.dispose();
    _quillNameController.dispose();
  }

  @override
  String toString() {
    return 'SectionTextController(sectionId: $sectionId, name: "${getName()}", contentLength: ${getContent().length})';
  }
}

class SongEditorData {
  final List<SectionTextController> textControllers = [];
  final GlobalHistoryManager globalHistoryManager = GlobalHistoryManager();

  SectionTextController addSection({String? sectionId}) {
    final id = sectionId ?? 'section_${textControllers.length}';
    final controller = SectionTextController(sectionId: id);
    textControllers.add(controller);
    return controller;
  }

  SectionTextController addSectionWithContent({
    String? sectionId,
    String? initialName,
    String? initialContent,
  }) {
    final id = sectionId ?? 'section_${textControllers.length}';
    final controller = SectionTextController.withContent(
      sectionId: id,
      initialName: initialName,
      initialContent: initialContent,
    );
    textControllers.add(controller);
    return controller;
  }

  void removeSection(int index) {
    if (index >= 0 && index < textControllers.length) {
      textControllers[index].dispose();
      textControllers.removeAt(index);
    }
  }

  void removeSectionController(SectionTextController controller) {
    final index = textControllers.indexOf(controller);
    if (index >= 0) {
      removeSection(index);
    }
  }

  SectionTextController? getSection(int index) {
    if (index >= 0 && index < textControllers.length) {
      return textControllers[index];
    }
    return null;
  }

  List<SectionTextController> getNonEmptySections() {
    return textControllers
        .where((controller) => controller.isNotEmpty)
        .toList();
  }

  void clearAllSections() {
    for (final controller in textControllers) {
      controller.clear();
    }
  }

  String getFullSongText() {
    final buffer = StringBuffer();
    for (var i = 0; i < textControllers.length; i++) {
      final controller = textControllers[i];
      if (controller.isNotEmpty) {
        final name = controller.getName();
        if (name.isNotEmpty) {
          buffer.writeln('[$name]');
        }
        buffer.writeln(controller.getContent());
        if (i < textControllers.length - 1) {
          buffer.writeln();
        }
      }
    }
    return buffer.toString();
  }

  int get sectionCount => textControllers.length;

  bool get hasSections => textControllers.isNotEmpty;

  bool get isEmpty => textControllers.every((controller) => controller.isEmpty);

  void dispose() {
    debugPrint('SongEditorData: Disposing ${textControllers.length} sezioni');

    for (final controller in textControllers) {
      controller.dispose();
    }
    textControllers.clear();

    globalHistoryManager.clearHistory();
  }

  @override
  String toString() {
    return 'SongEditorData(sections: ${textControllers.length})';
  }
}
