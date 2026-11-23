import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/add_transaction_dialog.dart';

class QuickAddScreen extends StatelessWidget {
  final String initialType;
  const QuickAddScreen({super.key, this.initialType = 'EXPENSE'});

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
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          // Dialog placed at bottom/center
          Align(
            alignment: Alignment.bottomCenter,
            child: AddTransactionDialog(
              initialType: initialType,
              onComplete: () {
                // Instantly exit back to home screen
                SystemNavigator.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
