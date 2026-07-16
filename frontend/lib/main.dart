import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'shared/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  ApiService().initialize();

  // Check if backend is already running
  final isBackendRunning = await ApiService().isHealthy();
  if (!isBackendRunning) {
    debugPrint('[StudyOS] Local backend not running. Launching...');
    try {
      final projectDir = Directory.current.path;
      final backendPath = projectDir.endsWith('frontend')
          ? '${Directory.current.parent.path}${Platform.pathSeparator}backend'
          : '$projectDir${Platform.pathSeparator}backend';

      debugPrint('[StudyOS] Backend path: $backendPath');

      final process = await Process.start(
        'python',
        ['-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '8000'],
        workingDirectory: backendPath,
      );

      process.stdout.listen((event) {
        debugPrint('[Backend]: ${String.fromCharCodes(event)}');
      });
      process.stderr.listen((event) {
        debugPrint('[Backend Err]: ${String.fromCharCodes(event)}');
      });

      // Give it time to bind to port
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('[StudyOS] Failed to auto-start backend: $e');
    }
  } else {
    debugPrint('[StudyOS] Backend already running.');
  }

  runApp(
    const ProviderScope(
      child: StudyOsApp(),
    ),
  );
}

