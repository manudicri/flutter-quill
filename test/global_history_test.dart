import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlobalHistoryManager Tests', () {
    late GlobalHistoryManager historyManager;
    late QuillController controller1;
    late QuillController controller2;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      historyManager = GlobalHistoryManager();
      controller1 = QuillController.basic();
      controller2 = QuillController.basic();
    });

    tearDown(() {
      historyManager.clearHistory();
      controller1.dispose();
      controller2.dispose();
    });

    test('should register and unregister controllers correctly', () {
      expect(historyManager.getRegisteredControllerIds(), isEmpty);

      historyManager.registerController(controller1, 'test_controller_1');
      expect(historyManager.getRegisteredControllerIds(),
          contains('test_controller_1'));

      historyManager.registerController(controller2, 'test_controller_2');
      expect(historyManager.getRegisteredControllerIds().length, 2);
      expect(historyManager.getRegisteredControllerIds(),
          contains('test_controller_1'));
      expect(historyManager.getRegisteredControllerIds(),
          contains('test_controller_2'));

      historyManager.unregisterController(controller1);
      expect(historyManager.getRegisteredControllerIds().length, 1);
      expect(historyManager.getRegisteredControllerIds(),
          contains('test_controller_2'));
      expect(historyManager.getRegisteredControllerIds(),
          isNot(contains('test_controller_1')));
    });

    test('should track history state correctly', () {
      historyManager.registerController(controller1, 'test_controller_1');

      expect(historyManager.canUndo(), false);
      expect(historyManager.canRedo(), false);
      expect(historyManager.historySize, 0);
      expect(historyManager.currentIndex, -1);
    });

    test('should clear history correctly', () {
      historyManager.registerController(controller1, 'test_controller_1');

      controller1.replaceText(
          0, 0, 'Test text', const TextSelection.collapsed(offset: 0));

      historyManager.clearHistory();
      expect(historyManager.historySize, 0);
      expect(historyManager.currentIndex, -1);
      expect(historyManager.canUndo(), false);
      expect(historyManager.canRedo(), false);
    });

    test('should handle singleton pattern correctly', () {
      final manager1 = GlobalHistoryManager();
      final manager2 = GlobalHistoryManager();

      expect(identical(manager1, manager2), true);
      expect(manager1 == manager2, true);
    });
  });

  group('SectionTextController Tests', () {
    late SectionTextController sectionController;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      sectionController = SectionTextController(sectionId: 'test_section');
    });

    tearDown(() {
      sectionController.dispose();
    });

    test('should initialize correctly', () {
      expect(sectionController.sectionId, 'test_section');
      expect(sectionController.isEmpty, true);
      expect(sectionController.getName(), isEmpty);
      expect(sectionController.getContent().trim(), isEmpty);
    });

    test('should set and get name correctly', () {
      const testName = 'Test Section Name';
      sectionController.setName(testName);
      expect(sectionController.getName(), testName);
    });

    test('should set and get content correctly', () {
      const testContent = 'This is test content\nWith multiple lines';
      sectionController.setContent(testContent);
      expect(sectionController.getContent().trimRight(), testContent);
    });

    test('should handle isEmpty correctly', () {
      expect(sectionController.isEmpty, true);

      sectionController.setName('Test');
      expect(sectionController.isEmpty, false);

      sectionController.clear();
      expect(sectionController.isEmpty, true);

      sectionController.setContent('Content');
      expect(sectionController.isEmpty, false);
    });

    test('should create with initial content', () {
      final controller = SectionTextController.withContent(
        sectionId: 'test_with_content',
        initialName: 'Initial Name',
        initialContent: 'Initial Content',
      );

      expect(controller.getName(), 'Initial Name');
      expect(controller.getContent().trimRight(), 'Initial Content');
      expect(controller.isEmpty, false);

      controller.dispose();
    });
  });

  group('SongEditorData Tests', () {
    late SongEditorData editorData;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      editorData = SongEditorData();
    });

    tearDown(() {
      editorData.dispose();
    });

    test('should start empty', () {
      expect(editorData.sectionCount, 0);
      expect(editorData.hasSections, false);
      expect(editorData.isEmpty, true);
    });

    test('should add sections correctly', () {
      final section1 = editorData.addSection(sectionId: 'section1');
      expect(editorData.sectionCount, 1);
      expect(editorData.hasSections, true);
      expect(section1.sectionId, 'section1');

      final section2 = editorData.addSectionWithContent(
        sectionId: 'section2',
        initialName: 'Test Section',
        initialContent: 'Test Content',
      );
      expect(editorData.sectionCount, 2);
      expect(section2.getName(), 'Test Section');
      expect(section2.getContent().trimRight(), 'Test Content');
    });

    test('should remove sections correctly', () {
      editorData
        ..addSection()
        ..addSection();
      expect(editorData.sectionCount, 2);

      editorData.removeSection(0);
      expect(editorData.sectionCount, 1);

      editorData.removeSection(0);
      expect(editorData.sectionCount, 0);
      expect(editorData.isEmpty, true);
    });

    test('should get non-empty sections correctly', () {
      final section1 = editorData.addSectionWithContent(
        initialName: 'Section 1',
        initialContent: 'Content 1',
      );
      editorData.addSection();
      final section3 = editorData.addSectionWithContent(
        initialName: 'Section 3',
        initialContent: 'Content 3',
      );

      final nonEmptySections = editorData.getNonEmptySections();
      expect(nonEmptySections.length, 2);
      expect(nonEmptySections, contains(section1));
      expect(nonEmptySections, contains(section3));
    });

    test('should generate full song text correctly', () {
      editorData
        ..addSectionWithContent(
          initialName: 'Verse 1',
          initialContent: 'This is verse 1',
        )
        ..addSectionWithContent(
          initialName: 'Chorus',
          initialContent: 'This is the chorus',
        );

      final fullText = editorData.getFullSongText();
      expect(fullText, contains('[Verse 1]'));
      expect(fullText, contains('This is verse 1'));
      expect(fullText, contains('[Chorus]'));
      expect(fullText, contains('This is the chorus'));
    });
  });
}
