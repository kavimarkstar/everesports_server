import 'package:everesports_server/core/widget/appbar_moniter.dart';
import 'package:everesports_server/core/widget/folder_insert.dart';
import 'package:everesports_server/core/widget/folder_list.dart';
import 'package:everesports_server/core/widget/server_run.dart';
import 'package:everesports_server/theme/colors.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _selectedFolderPath;
  List<FileSystemEntity> _folderContents = [];
  bool _isLoading = false;
  List<String> _breadcrumb = [];
  String _currentPath = '';
  bool _isServerRunning = false;
  Process? _serverProcess;
  String? _currentCommand;
  bool _autoStartEnabled = false;
  String _networkSpeed = '0 Mbps';
  String _processorSpeed = '0 GHz';
  String _ramUsage = '0%';
  String _hardDriveSpeed = '0 MB/s';

  @override
  void initState() {
    super.initState();
    _loadSavedFolderPath();
    _startNetworkSpeedMonitoring();
    _startProcessorSpeedMonitoring();
    _startRamCapacityMonitoring();
    _startRamUsageMonitoring();
    _startHardDriveSpeedMonitoring();
    _checkAndAutoStartServer();
  }

  @override
  void dispose() {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
    }
    super.dispose();
  }

  Future<void> _loadSavedFolderPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('selected_folder_path');
      final autoStartEnabled = prefs.getBool('auto_start_server') ?? false;

      setState(() {
        _autoStartEnabled = autoStartEnabled;
      });

      if (savedPath != null) {
        setState(() {
          _selectedFolderPath = savedPath;
          _currentPath = savedPath;
          _breadcrumb = [savedPath.split(Platform.pathSeparator).last];
        });
        _loadFolderContents();
      }
    } catch (e) {
      print('Error loading saved folder path: $e');
    }
  }

  Future<void> _checkAndAutoStartServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoStartEnabled = prefs.getBool('auto_start_server') ?? false;

      setState(() {
        _autoStartEnabled = autoStartEnabled;
      });

      if (autoStartEnabled &&
          _selectedFolderPath != null &&
          _selectedFolderPath!.isNotEmpty) {
        // Wait a bit for the UI to load completely
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          print('Auto-starting server on app launch...');
          await _autoRunRunBat();
        }
      }
    } catch (e) {
      print('Error in auto-start server: $e');
    }
  }

  Future<void> _onAutoStartChanged(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_start_server', value);

      setState(() {
        _autoStartEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Auto-start enabled - Server will start automatically on app launch'
                : '❌ Auto-start disabled - Server will not start automatically',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error saving auto-start setting: $e');
    }
  }

  Future<void> _saveFolderPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_folder_path', path);
    } catch (e) {
      print('Error saving folder path: $e');
    }
  }

  Future<void> _selectFolder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder for File Storage',
      );

      if (selectedDirectory != null) {
        setState(() {
          _selectedFolderPath = selectedDirectory;
          _currentPath = selectedDirectory;
          _breadcrumb = [selectedDirectory.split(Platform.pathSeparator).last];
        });

        await _saveFolderPath(selectedDirectory);
        await _loadFolderContents();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Folder selected: ${selectedDirectory.split(Platform.pathSeparator).last}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error selecting folder';
      if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'File picker not initialized. Please restart the app.';
      } else {
        errorMessage = 'Error selecting folder: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFolderContents() async {
    if (_currentPath.isEmpty) return;

    try {
      final directory = Directory(_currentPath);
      if (await directory.exists()) {
        final contents = await directory.list().toList();
        setState(() {
          _folderContents = contents;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading folder contents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToFolder(String folderPath, String folderName) async {
    setState(() {
      _currentPath = folderPath;
      _breadcrumb.add(folderName);
    });
    await _loadFolderContents();
  }

  Future<void> _insertFiles() async {
    if (_currentPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a folder first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        dialogTitle: 'Select Files to Insert',
      );

      if (result != null && result.files.isNotEmpty) {
        int successCount = 0;
        int errorCount = 0;

        for (var file in result.files) {
          if (file.path != null) {
            try {
              final sourceFile = File(file.path!);
              final fileName = file.name;
              final destinationPath =
                  '$_currentPath${Platform.pathSeparator}$fileName';
              final destinationFile = File(destinationPath);

              // Check if source file exists
              if (!await sourceFile.exists()) {
                print('Source file does not exist: ${file.path}');
                errorCount++;
                continue;
              }

              // Check if destination already exists and handle it
              if (await destinationFile.exists()) {
                // Create backup name
                final nameWithoutExt = fileName.contains('.')
                    ? fileName.substring(0, fileName.lastIndexOf('.'))
                    : fileName;
                final extension = fileName.contains('.')
                    ? fileName.substring(fileName.lastIndexOf('.'))
                    : '';
                int counter = 1;
                String newFileName = fileName;

                while (await File(
                  '$_currentPath${Platform.pathSeparator}$newFileName',
                ).exists()) {
                  newFileName = '${nameWithoutExt}_copy$counter$extension';
                  counter++;
                }

                final finalDestinationPath =
                    '$_currentPath${Platform.pathSeparator}$newFileName';
                await sourceFile.copy(finalDestinationPath);
                successCount++;
              } else {
                // Direct copy
                await sourceFile.copy(destinationPath);
                successCount++;
              }
            } catch (e) {
              print('Error copying file ${file.name}: $e');
              errorCount++;
            }
          }
        }

        await _loadFolderContents();

        String message = 'Successfully inserted $successCount files';
        if (errorCount > 0) {
          message += ' ($errorCount failed)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error inserting files';
      if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'File picker not initialized. Please restart the app.';
      } else {
        errorMessage = 'Error inserting files: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _insertFolders() async {
    if (_currentPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a folder first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String? selectedFolder = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder to Insert',
      );

      if (selectedFolder != null) {
        print('Selected folder: $selectedFolder');

        final sourceDirectory = Directory(selectedFolder);
        final folderName = selectedFolder.split(Platform.pathSeparator).last;
        print('Folder name: $folderName');

        // Check if source directory exists
        if (!await sourceDirectory.exists()) {
          print('Source directory does not exist: $selectedFolder');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected folder does not exist'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Handle duplicate folder names
        String finalFolderName = folderName;
        String destinationPath =
            '$_currentPath${Platform.pathSeparator}$finalFolderName';
        Directory destinationDirectory = Directory(destinationPath);

        int counter = 1;
        while (await destinationDirectory.exists()) {
          finalFolderName = '${folderName}_copy$counter';
          destinationPath =
              '$_currentPath${Platform.pathSeparator}$finalFolderName';
          destinationDirectory = Directory(destinationPath);
          counter++;
        }

        print('Destination path: $destinationPath');

        try {
          // Create destination directory
          await destinationDirectory.create(recursive: true);
          print('Created destination directory: $destinationPath');

          // Copy all contents from source to destination
          await _copyDirectory(sourceDirectory, destinationDirectory);
          print('Finished copying directory contents');

          await _loadFolderContents();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully inserted folder: $finalFolderName'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Error during folder copy operation: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error copying folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('No folder selected');
      }
    } catch (e) {
      print('Error in _insertFolders: $e');
      String errorMessage = 'Error inserting folder';
      if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'File picker not initialized. Please restart the app.';
      } else {
        errorMessage = 'Error inserting folder: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await source.exists()) {
      throw Exception('Source directory does not exist');
    }

    // Create destination directory if it doesn't exist
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    try {
      // List all items in source directory
      final entities = await source.list().toList();

      for (final entity in entities) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        final destinationPath =
            '${destination.path}${Platform.pathSeparator}$fileName';

        if (entity is File) {
          try {
            // Check if destination file exists and create backup name
            String finalDestinationPath = destinationPath;
            if (await File(destinationPath).exists()) {
              final nameWithoutExt = fileName.contains('.')
                  ? fileName.substring(0, fileName.lastIndexOf('.'))
                  : fileName;
              final extension = fileName.contains('.')
                  ? fileName.substring(fileName.lastIndexOf('.'))
                  : '';
              int counter = 1;
              String newFileName = fileName;

              while (await File(
                '${destination.path}${Platform.pathSeparator}$newFileName',
              ).exists()) {
                newFileName = '${nameWithoutExt}_copy$counter$extension';
                counter++;
              }
              finalDestinationPath =
                  '${destination.path}${Platform.pathSeparator}$newFileName';
            }

            await entity.copy(finalDestinationPath);
            print('Copied file: ${entity.path} to $finalDestinationPath');
          } catch (e) {
            print('Error copying file ${entity.path}: $e');
          }
        } else if (entity is Directory) {
          try {
            final subDestination = Directory(destinationPath);
            await _copyDirectory(entity, subDestination);
            print('Copied directory: ${entity.path} to $destinationPath');
          } catch (e) {
            print('Error copying directory ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error during directory copy: $e');
      throw Exception('Error during directory copy: $e');
    }
  }

  Future<void> _runBatFile(String filePath) async {
    if (_currentPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a folder first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if the file exists
      final batFile = File(filePath);
      if (!await batFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected .bat file does not exist'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Running .bat file: $filePath');
      print('Working directory: $_currentPath');

      // Run the file with proper error handling for both platforms
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run(
          'cmd',
          ['/c', filePath],
          workingDirectory: _currentPath,
          runInShell: true,
        );
      } else {
        // Linux: Make file executable and run with bash
        await Process.run('chmod', ['+x', filePath]);
        result = await Process.run(
          'bash',
          [filePath],
          workingDirectory: _currentPath,
          runInShell: true,
        );
      }

      // Print output for debugging
      if (result.stdout.toString().isNotEmpty) {
        print('STDOUT: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        print('STDERR: ${result.stderr}');
      }

      print('Process exit code: ${result.exitCode}');

      if (result.exitCode == 0) {
        String fileExtension = Platform.isWindows ? '.bat' : '.sh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $fileExtension file executed successfully: ${batFile.path.split(Platform.pathSeparator).last}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String fileExtension = Platform.isWindows ? '.bat' : '.sh';
        String errorMessage =
            '⚠️ $fileExtension file executed with exit code: ${result.exitCode}';
        if (result.stderr.toString().isNotEmpty) {
          errorMessage += '\nError: ${result.stderr}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error running .bat file: $e');
      String fileExtension = Platform.isWindows ? '.bat' : '.sh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error running $fileExtension file: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoRunRunBat() async {
    if (_currentPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a folder first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if server is already running
    if (_isServerProcessRunning()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Server is already running. Stop it first to start a new one.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Stop any existing server process first
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if run file exists in the current folder (run.bat for Windows, run.sh for Linux)
      String runFileName = Platform.isWindows ? 'run.bat' : 'run.sh';
      final runFile = File(
        '$_currentPath${Platform.pathSeparator}$runFileName',
      );
      if (!await runFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ $runFileName file not found in the selected folder',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Starting server process: ${runFile.path}');
      print('Working directory: $_currentPath');

      // Set the current command based on platform
      String commandDisplay;
      if (Platform.isWindows) {
        commandDisplay = 'start cmd /k "${runFile.path}"';
      } else {
        commandDisplay =
            'gnome-terminal --working-directory="$_currentPath" -- bash -c "cd \\"$_currentPath\\" && ./$runFileName"';
      }

      setState(() {
        _currentCommand = commandDisplay;
      });

      // Run run.bat file as a long-running process with visible terminal
      if (Platform.isWindows) {
        // Windows: Use start command to open new terminal window
        _serverProcess = await Process.start(
          'cmd',
          ['/c', 'start', 'cmd', '/k', runFile.path],
          workingDirectory: _currentPath,
          runInShell: true,
        );
      } else if (Platform.isLinux) {
        // Linux: Use gnome-terminal or xterm to open new terminal window
        String terminalCommand = 'gnome-terminal';
        List<String> terminalArgs = [
          '--working-directory=$_currentPath',
          '--',
          'bash',
          '-c',
          'cd "$_currentPath" && ./run.sh',
        ];

        // Try different terminal emulators
        try {
          _serverProcess = await Process.start(
            terminalCommand,
            terminalArgs,
            workingDirectory: _currentPath,
          );
        } catch (e) {
          // Fallback to xterm
          try {
            _serverProcess = await Process.start('xterm', [
              '-e',
              'cd "$_currentPath" && ./run.sh',
            ], workingDirectory: _currentPath);
          } catch (e2) {
            // Fallback to direct execution
            _serverProcess = await Process.start(
              'bash',
              ['-c', 'cd "$_currentPath" && ./run.sh'],
              workingDirectory: _currentPath,
              runInShell: true,
            );
          }
        }
      }

      // Listen to stdout and stderr
      _serverProcess!.stdout.transform(const Utf8Decoder()).listen((data) {
        print('Server STDOUT: $data');
      });

      _serverProcess!.stderr.transform(const Utf8Decoder()).listen((data) {
        print('Server STDERR: $data');
      });

      // Listen for process exit
      _serverProcess!.exitCode.then((exitCode) {
        print('Server process exited with code: $exitCode');
        if (mounted) {
          setState(() {
            _isServerRunning = false;
            _serverProcess = null;
            _currentCommand = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🛑 Server process stopped (exit code: $exitCode)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

      // Check if process started successfully
      if (_serverProcess != null) {
        setState(() {
          _isServerRunning = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Server started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to start server process'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error starting server: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error starting server: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _stopServer() {
    if (_serverProcess != null) {
      try {
        print('Stopping server process...');
        _serverProcess!.kill();
        _serverProcess = null;
        print('Server process killed successfully');
      } catch (e) {
        print('Error killing server process: $e');
      }
    }

    setState(() {
      _isServerRunning = false;
      _currentCommand = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Server stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  bool _isServerProcessRunning() {
    return _serverProcess != null && _isServerRunning;
  }

  void _startNetworkSpeedMonitoring() {
    // Simulate network speed updates every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Simulate random network speed between 10-100 Mbps
          final random = Random();
          final speed = 10 + random.nextInt(91);
          _networkSpeed = '$speed Mbps';
        });
      }
    });
  }

  void _startProcessorSpeedMonitoring() {
    // Simulate processor speed updates every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Simulate random processor speed between 1.5-4.5 GHz
          final random = Random();
          final baseSpeed = 1.5 + random.nextDouble() * 3.0;
          _processorSpeed = '${baseSpeed.toStringAsFixed(1)} GHz';
        });
      }
    });
  }

  void _startRamCapacityMonitoring() {
    // Simulate RAM capacity updates every 4 seconds
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          // Simulate random RAM capacity between 8-32 GB
        });
      }
    });
  }

  void _startRamUsageMonitoring() {
    // Simulate RAM usage updates every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Simulate random RAM usage between 20-85%
          final random = Random();
          final usage = 20 + random.nextInt(66);
          _ramUsage = '$usage%';
        });
      }
    });
  }

  void _startHardDriveSpeedMonitoring() {
    // Simulate hard drive speed updates every 6 seconds
    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          // Simulate random hard drive speed between 50-500 MB/s
          final random = Random();
          final speed = 50 + random.nextInt(451);
          _hardDriveSpeed = '$speed MB/s';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Image.asset(
              'assets/logo/everesports_server.png',
              width: 30,
              height: 30,
            ),
            const Text(
              'EverEsports File Server',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          appBarMoniter(context, _networkSpeed, Icons.speed),
          appBarMoniter(context, _processorSpeed, Icons.memory),
          appBarMoniter(context, _ramUsage, Icons.memory_outlined),
          appBarMoniter(context, _hardDriveSpeed, Icons.storage),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        folderInsert(
                          context,
                          _selectedFolderPath ?? '',
                          _isLoading,
                          _selectFolder,
                          _loadFolderContents,
                          _insertFiles,
                          _insertFolders,
                          _autoRunRunBat,
                        ),
                        serverRun(
                          context,
                          _isServerRunning,
                          _stopServer,
                          _autoRunRunBat,
                          _currentCommand,
                          _autoStartEnabled,
                          _onAutoStartChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FolderList(
                      selectedFolderPath: _selectedFolderPath ?? '',
                      breadcrumb: _breadcrumb,
                      currentPath: _currentPath,
                      folderContents: _folderContents,
                      isLoading: _isLoading,
                      loadFolderContents: _loadFolderContents,
                      runBatFile: _runBatFile,
                      navigateToFolder: _navigateToFolder,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
