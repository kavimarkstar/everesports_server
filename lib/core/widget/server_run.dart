import 'package:everesports_server/theme/colors.dart';
import 'package:flutter/material.dart';

Widget serverRun(
  BuildContext context,
  bool isServerRunning,
  Function() stopServer,
  Function() autoRunRunBat,
  String? currentCommand,
  bool autoStartEnabled,
  Function(bool) onAutoStartChanged,
) {
  return Card(
    elevation: 4,
    color: AppColors.card,
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isServerRunning ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isServerRunning ? Colors.green : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isServerRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isServerRunning
                          ? 'Server is running in background'
                          : 'Server is not running',
                      style: TextStyle(
                        fontSize: 14,
                        color: isServerRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isServerRunning)
                ElevatedButton.icon(
                  onPressed: stopServer,
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Stop Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: autoRunRunBat,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Start Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          if (isServerRunning && currentCommand != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.terminal, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Running Command:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentCommand,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: autoStartEnabled ? mainColor : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-start server on app launch',
                  style: TextStyle(
                    fontSize: 12,
                    color: autoStartEnabled ? mainColor : Colors.grey,
                  ),
                ),
              ),
              Switch(
                value: autoStartEnabled,
                onChanged: onAutoStartChanged,
                activeColor: mainColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
