import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/voice_assistant_dialog.dart';

/// Transparent floating overlay screen launched from the Home Screen Widget
/// or App Shortcuts to allow adding transactions via Voice AI without opening the full app.
class QuickVoiceScreen extends StatelessWidget {
  const QuickVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent backdrop over home screen wallpaper
          GestureDetector(
            onTap: () => SystemNavigator.pop(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          // Centered Aurex Voice Assistant Dialog
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: VoiceAssistantDialog(
                onDismiss: () {
                  // Instantly exit back to home screen
                  SystemNavigator.pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
