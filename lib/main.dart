import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filechecksum/filesize.dart';
import 'package:filechecksum/loading_ellipsis.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  static const kToolbarTitle = 'File Checksum Comparer';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kToolbarTitle,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Roboto Mono',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: kToolbarTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

extension FileFormatter on num {
  String readableFileSize({bool base1024 = true}) {
    return filesize(this);
  }
}

class FileChecksumData {
  final String fileDirectory;
  final String filename;
  final int sizeInBytes;
  final Map<String, String> checksum;

  const FileChecksumData({
    required this.fileDirectory,
    required this.checksum,
    required this.sizeInBytes,
    required this.filename,
  });

  List<String> get computedMetadataForDisplay {
    return [
      fileDirectory,
      filename,
      sizeInBytes.readableFileSize(),
    ];
  }
}

class FileChecksumStateManager extends ChangeNotifier {
  final List<FileChecksumData> fileChecksumList = [];
  final Set<String> recentlyCopiedHashes = <String>{};
  bool disposed = false;
  bool makingComputations = false;

  @override
  void dispose() {
    disposed = true;
    return super.dispose();
  }

  Future<void> updateFileBySelectingNewOne(String fileDirectory) async {
    final int index =
        fileChecksumList.indexWhere((e) => e.fileDirectory == fileDirectory);

    final FileChecksumData? updatedFile = await pickFile();

    if (updatedFile == null) return;

    fileChecksumList[index] = updatedFile;

    if (!disposed) notifyListeners();
  }

  void copyHash({required String hash}) {
    Clipboard.setData(
      ClipboardData(
        text: hash,
      ),
    );

    recentlyCopiedHashes.add(hash);

    notifyListeners();

    Future.delayed(const Duration(seconds: 3)).then((_) {
      if (disposed) return;

      recentlyCopiedHashes.remove(hash);

      notifyListeners();
    });
  }

  static Future<FilePickerResult?> _pickFile([String? initialDirectory]) async {
    return await FilePicker.platform.pickFiles(
      allowMultiple: false,
      dialogTitle: 'File to generate checksum hashes',
      withData: true,
      initialDirectory: initialDirectory,
      onFileLoading: (status) {},
    );
  }

  Future<FileChecksumData?> pickFile({String? initialDirectory}) async {
    final FilePickerResult? result =
        await compute<String?, FilePickerResult?>(_pickFile, initialDirectory);

    if (result == null) return null;

    return _generateChecksumData(result.files.first);
  }

  Future<FileChecksumData> _generateChecksumData(PlatformFile file) async {
    final Map<String, String> checksum = <String, String>{};

    final Map<String, String Function(List<int>)> algorithms = {
      'MD5': (bytes) => md5.convert(bytes).toString(),
      'SHA-1': (bytes) => sha1.convert(bytes).toString(),
      'SHA-224': (bytes) => sha224.convert(bytes).toString(),
      'SHA-256': (bytes) => sha256.convert(bytes).toString(),
      'SHA-384': (bytes) => sha384.convert(bytes).toString(),
      'SHA-512': (bytes) => sha512.convert(bytes).toString(),
    };

    makingComputations = true;
    notifyListeners();

    for (final String algorithm in algorithms.keys) {
      if (file.bytes == null) {
        checksum[algorithm] = 'Unknown, could not read file bytes.';
      } else {
        checksum[algorithm] = await compute<List<int>, String>(
          algorithms[algorithm]!,
          file.bytes!,
        );
      }
    }

    makingComputations = false;
    notifyListeners();

    return FileChecksumData(
      fileDirectory: file.path ?? 'Could not determine this file path.',
      checksum: checksum,
      filename: file.name,
      sizeInBytes: file.size,
    );
  }

  static Future<FilePickerResult?> _staticPickMultipleFiles([
    String? initialDirectory,
  ]) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Files to generate checksum hashes',
      withData: true,
      initialDirectory: initialDirectory,
    );

    if (result == null) return null;

    return result;
  }

  Future<List<FileChecksumData>?> pickMultipleFiles(
      {String? initialDirectory}) async {
    final FilePickerResult? result = await compute<String?, FilePickerResult?>(
        _staticPickMultipleFiles, initialDirectory);

    if (result == null) return null;

    return [
      for (final PlatformFile file in result.files)
        await _generateChecksumData(file)
    ];
  }

  void selectFilesToChecksumDataTable() {
    pickMultipleFiles().then((selectedFiles) {
      if (selectedFiles == null) return;

      fileChecksumList.addAll(selectedFiles);

      notifyListeners();
    });
  }

  void clearFileChecksumList() {
    fileChecksumList.clear();
    notifyListeners();
  }
}

class _HomePageState extends State<HomePage> {
  late FileChecksumStateManager _fileChecksumStateManager =
      FileChecksumStateManager();

  @override
  void initState() {
    _fileChecksumStateManager = FileChecksumStateManager();
    super.initState();
  }

  @override
  void dispose() {
    _fileChecksumStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _fileChecksumStateManager,
      child: Scaffold(
        appBar: const AppBarActions(),
        bottomNavigationBar: const BottomAppBarActions(),
        body: AnimatedBuilder(
          animation: _fileChecksumStateManager,
          builder: (context, child) {
            return SizedBox.expand(
              child: _fileChecksumStateManager.fileChecksumList.isEmpty
                  ? const EmptyFileChecksumListWarning()
                  : FileChecksumList(_fileChecksumStateManager),
            );
          },
        ),
      ),
    );
  }
}

class AppBarActions extends StatelessWidget implements PreferredSizeWidget {
  const AppBarActions({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildToolbarAction(String text, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: () => launchUrlString(url),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            text,
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      title: Image.asset('assets/images/icon.png', height: 50),
      actions: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildToolbarAction('Blog', 'https://alexrintt.io'),
            _buildToolbarAction('GitHub', 'https://github.com/alexrintt'),
            _buildToolbarAction(
                'Repository', 'https://github.com/alexrintt/filechecksum'),
          ],
        ),
      ],
    );
  }
}

class BottomAppBarActions extends StatefulWidget {
  const BottomAppBarActions({Key? key}) : super(key: key);

  @override
  State<BottomAppBarActions> createState() => _BottomAppBarActionsState();
}

mixin FileChecksumStateManagerMixin<T extends StatefulWidget> on State<T> {
  FileChecksumStateManager get fileChecksumStateManager => Provider.of(
        context,
        listen: false,
      );
}

class _BottomAppBarActionsState extends State<BottomAppBarActions>
    with FileChecksumStateManagerMixin {
  int lastClickedAction = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (index) {
        switch (index) {
          case 0:
            fileChecksumStateManager.selectFilesToChecksumDataTable();
            break;
          case 1:
            fileChecksumStateManager.clearFileChecksumList();
            break;
        }

        lastClickedAction = index;

        setState(() {});
      },
      currentIndex: lastClickedAction,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Pixel.upload),
          label: 'Add files',
        ),
        BottomNavigationBarItem(
          icon: Icon(Pixel.trash),
          label: 'Clear current files',
        ),
      ],
    );
  }
}

class FileMetadata extends StatefulWidget {
  final FileChecksumData fileChecksum;

  const FileMetadata({
    Key? key,
    required this.fileChecksum,
  }) : super(key: key);

  @override
  State<FileMetadata> createState() => _FileMetadataState();
}

class _FileMetadataState extends State<FileMetadata>
    with FileChecksumStateManagerMixin {
  FileChecksumData get _fileChecksum => widget.fileChecksum;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fileChecksumStateManager,
      builder: (context, child) {
        return Tooltip(
          message: 'Edit file',
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).hoverColor,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => fileChecksumStateManager
                    .updateFileBySelectingNewOne(_fileChecksum.fileDirectory),
                child: Table(
                  children: [
                    for (final String metadata
                        in _fileChecksum.computedMetadataForDisplay)
                      TableRow(
                        children: [
                          Text(metadata),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FileChecksumList extends StatefulWidget {
  final FileChecksumStateManager fileChecksumStateManager;

  const FileChecksumList(this.fileChecksumStateManager, {Key? key})
      : super(key: key);

  @override
  State<FileChecksumList> createState() => _FileChecksumListState();
}

class _FileChecksumListState extends State<FileChecksumList>
    with FileChecksumStateManagerMixin {
  FileChecksumStateManager get _fileChecksumStateManager =>
      widget.fileChecksumStateManager;

  List<FileChecksumData> get _fileChecksumList =>
      _fileChecksumStateManager.fileChecksumList;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        AnimatedBuilder(
          animation: _fileChecksumStateManager,
          builder: (context, child) {
            return SliverPadding(
              padding: const EdgeInsets.all(20).copyWith(top: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final FileChecksumData fileChecksum =
                        _fileChecksumList[index];

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FileMetadata(fileChecksum: fileChecksum),
                              FileChecksumTable(fileChecksum: fileChecksum),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: _fileChecksumList.length,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _fileChecksumStateManager,
          builder: (context, child) {
            if (!_fileChecksumStateManager.makingComputations) {
              return SliverList(delegate: SliverChildListDelegate([]));
            }

            return SliverPadding(
              padding: const EdgeInsets.all(20).copyWith(top: 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: LoadingEllipsis(
                          'What are these heavy boxes, man? Wait a little more',
                          dots: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TextWithIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final Widget icon;

  const TextWithIcon(
    this.text, {
    Key? key,
    this.onTap,
    required this.icon,
  }) : super(key: key);

  @override
  State<TextWithIcon> createState() => _TextWithIconState();
}

class _TextWithIconState extends State<TextWithIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        message: 'Copy to clipboard',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: widget.icon,
                  ),
                ),
                TextSpan(
                  text: widget.text,
                ),
              ],
            ),
            softWrap: true,
          ),
        ),
      ),
    );
  }
}

class FileChecksumTable extends StatefulWidget {
  final FileChecksumData fileChecksum;

  const FileChecksumTable({Key? key, required this.fileChecksum})
      : super(key: key);

  @override
  State<FileChecksumTable> createState() => _FileChecksumTableState();
}

class _FileChecksumTableState extends State<FileChecksumTable>
    with FileChecksumStateManagerMixin {
  Widget _buildTextWithIconHash(String text) {
    return TextWithIcon(
      text,
      onTap: () => fileChecksumStateManager.copyHash(hash: text),
      icon: fileChecksumStateManager.recentlyCopiedHashes.contains(text)
          ? Icon(Pixel.check, color: Theme.of(context).primaryColor)
          : Icon(Pixel.clipboard, color: Theme.of(context).primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(
          label: Text(
            'Algorithm',
          ),
        ),
        DataColumn(
          label: Text(
            'Hash',
          ),
        )
      ],
      rows: [
        for (final String algorithm in widget.fileChecksum.checksum.keys)
          DataRow(
            cells: [
              DataCell(
                Text(algorithm),
                placeholder: true,
              ),
              DataCell(
                _buildTextWithIconHash(
                  widget.fileChecksum.checksum[algorithm]!,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class EmptyFileChecksumListWarning extends StatefulWidget {
  const EmptyFileChecksumListWarning({Key? key}) : super(key: key);

  @override
  State<EmptyFileChecksumListWarning> createState() =>
      _EmptyFileChecksumListWarningState();
}

class _EmptyFileChecksumListWarningState
    extends State<EmptyFileChecksumListWarning>
    with FileChecksumStateManagerMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'File Checksum Integrity Verifier\n\n',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    const TextSpan(
                      text:
                          'Hi Stranger! We often need to run software from unknown lands, right? Click on the "Add files" button to verify the integrity of any magical orb you\'ve achieved through your journey, good luck and stay safe.',
                    ),
                    const TextSpan(
                      text: '\n\nCheck this Wikipedia link ',
                    ),
                    TextSpan(
                      text: 'en.wikipedia.org/wiki/File_verification',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlString(
                            'https://en.wikipedia.org/wiki/File_verification'),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const TextSpan(
                      text: ' to be aware of whatf file verification is.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Image.asset(
            'assets/images/welcome.gif',
            height: 150,
          ),
          AnimatedBuilder(
            animation: fileChecksumStateManager,
            builder: (context, child) {
              if (fileChecksumStateManager.makingComputations) {
                return const LoadingEllipsis(
                  'Wait! I am almost there',
                  dots: 3,
                  enabled: true,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
