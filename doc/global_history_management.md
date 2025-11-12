# Global History Management per Flutter Quill

Questa implementazione aggiunge la gestione globale dell'undo/redo per multiple istanze di `QuillController`, permettendo di gestire operazioni di undo/redo che funzionano su tutti i controller attivi contemporaneamente.

## Funzionalità

- **Undo/Redo Globale**: Traccia le modifiche di tutti i QuillController registrati e permette di fare undo/redo su qualsiasi controller basandosi sul timestamp delle operazioni
- **Gestione Automatica**: I controller vengono automaticamente registrati e rimossi dal GlobalHistoryManager
- **Singleton Pattern**: Un unico manager globale gestisce tutti i controller dell'applicazione
- **Debug Support**: Widget per visualizzare lo stato della history globale
- **Thread-Safe**: Gestisce correttamente le operazioni concorrenti

## Classi Principali

### GlobalHistoryManager

Il cuore del sistema. Gestisce la cronologia globale di tutti i QuillController.

```dart
// Ottieni l'istanza singleton
final historyManager = GlobalHistoryManager();

// Registra un controller
historyManager.registerController(controller, 'unique_id');

// Undo/redo globale
if (historyManager.canUndo()) {
  historyManager.undo();
}

if (historyManager.canRedo()) {
  historyManager.redo();
}
```

### SectionTextController

Wrapper che gestisce automaticamente la registrazione nel GlobalHistoryManager.

```dart
// Crea un controller per una sezione
final sectionController = SectionTextController(sectionId: 'verse_1');

// Oppure con contenuto iniziale
final sectionController = SectionTextController.withContent(
  sectionId: 'chorus',
  initialName: 'Chorus',
  initialContent: 'La la la...',
);

// Accedi ai QuillController interni
final nameController = sectionController.quillNameController;
final contentController = sectionController.quillController;
```

### SongEditorData

Gestisce multiple sezioni con registrazione automatica.

```dart
final editorData = SongEditorData();

// Aggiungi sezioni
final section1 = editorData.addSection(sectionId: 'verse1');
final section2 = editorData.addSectionWithContent(
  sectionId: 'chorus',
  initialName: 'Chorus',
  initialContent: 'This is the chorus',
);

// Ottieni il testo completo
final fullSong = editorData.getFullSongText();
```

## Widget UI

### GlobalUndoRedoToolbar

Toolbar con pulsanti undo/redo globali.

```dart
AppBar(
  actions: [
    const GlobalUndoRedoToolbar(
      showDebugInfo: true, // Mostra informazioni di debug
      iconSize: 20,
    ),
  ],
)
```

### GlobalHistoryDebugPanel

Panel per debugging con informazioni dettagliate sulla history.

```dart
const GlobalHistoryDebugPanel()
```

### GlobalHistoryMixin

Mixin per integrare facilmente il GlobalHistoryManager nei tuoi widget.

```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> with GlobalHistoryMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: canGlobalUndo ? globalUndo : null,
          child: Text('Undo'),
        ),
        ElevatedButton(
          onPressed: canGlobalRedo ? globalRedo : null,
          child: Text('Redo'),
        ),
      ],
    );
  }
}
```

## Esempio Completo

```dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class SongEditorPage extends StatefulWidget {
  @override
  State<SongEditorPage> createState() => _SongEditorPageState();
}

class _SongEditorPageState extends State<SongEditorPage> 
    with GlobalHistoryMixin {
  late SongEditorData editorData;

  @override
  void initState() {
    super.initState();
    editorData = SongEditorData();
    
    // Aggiungi alcune sezioni
    editorData.addSectionWithContent(
      sectionId: 'verse1',
      initialName: 'Verse 1',
      initialContent: 'First verse lyrics...',
    );
    
    editorData.addSectionWithContent(
      sectionId: 'chorus',
      initialName: 'Chorus',
      initialContent: 'Chorus lyrics...',
    );
  }

  @override
  void dispose() {
    editorData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Editor'),
        actions: [
          // Toolbar globale undo/redo
          const GlobalUndoRedoToolbar(showDebugInfo: true),
        ],
      ),
      body: ListView.builder(
        itemCount: editorData.sectionCount,
        itemBuilder: (context, index) {
          final section = editorData.getSection(index)!;
          return Card(
            child: Column(
              children: [
                // Editor per il nome della sezione
                QuillEditor.basic(
                  controller: section.quillNameController,
                  config: const QuillEditorConfig(
                    placeholder: 'Section name...',
                  ),
                ),
                // Editor per il contenuto
                QuillEditor.basic(
                  controller: section.quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Section content...',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Come Funziona Internamente

1. **Registrazione**: Quando un `SectionTextController` viene creato, registra automaticamente i suoi QuillController nel `GlobalHistoryManager`

2. **Tracking**: Il manager ascolta gli eventi `changes` di ogni controller e registra le modifiche con timestamp

3. **Undo/Redo**: Quando viene chiamato undo/redo globale, il manager identifica l'ultima modifica (basandosi sul timestamp) e applica l'operazione al controller corretto

4. **Cleanup**: Quando un controller viene disposto, viene automaticamente rimosso dal manager

## Limitazioni e Considerazioni

- **Performance**: Con molti controller attivi, la dimensione della history può crescere. Il manager mantiene un limite di 1000 operazioni per default
- **Memory**: Ogni operazione viene salvata come Delta completo, non solo le differenze
- **Concurrency**: Le operazioni di undo/redo sono sincrone e potrebbero bloccare l'UI per operazioni molto grandi

## Testing

La libreria include test completi per verificare:
- Registrazione/rimozione dei controller
- Funzionalità di undo/redo
- Gestione dello stato della history
- Singleton pattern del manager

Esegui i test con:
```bash
flutter test test/global_history_test.dart
```

## Demo

Puoi testare l'implementazione con:
```bash
# Test semplice
flutter run lib/simple_global_history_test.dart

# Test completo
flutter run lib/global_history_test.dart
```