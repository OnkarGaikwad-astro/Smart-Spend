import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/debt_dialogs.dart';

class QuickAddDebtScreen extends StatelessWidget {
  final String initialType;
  const QuickAddDebtScreen({super.key, this.initialType = 'LENT'});

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
            child: AddPersonDebtDialog(
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
