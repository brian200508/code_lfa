import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xterm/xterm.dart';

/// Model for custom keyboard button
class CustomKeyButton {
  final String label;
  final String? key;
  final List<String>? keySequence;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final VoidCallback? onCustomAction;

  const CustomKeyButton({
    required this.label,
    this.key,
    this.keySequence,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.onCustomAction,
  }) : assert(
    key != null || keySequence != null || onCustomAction != null,
    'Must provide either key, keySequence, or onCustomAction',
  );

  /// Creates a simple key button
  const CustomKeyButton.simpleKey({
    required String label,
    required String key,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) : this(
    label: label,
    key: key,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
  );

  /// Creates a key combination button
  const CustomKeyButton.keyCombo({
    required String label,
    required List<String> keySequence,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) : this(
    label: label,
    keySequence: keySequence,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
  );

  /// Creates a custom action button
  const CustomKeyButton.action({
    required String label,
    required VoidCallback onCustomAction,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) : this(
    label: label,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    onCustomAction: onCustomAction,
  );
}

/// Controller for custom keyboard bar
class CustomKeyboardController extends GetxController {
  final Terminal terminal;
  late final List<CustomKeyButton> buttons;
  final RxBool isVisible = true.obs;
  final RxBool isCompactMode = false.obs;

  CustomKeyboardController({
    required this.terminal,
    List<CustomKeyButton>? customButtons,
  }) {
    buttons = customButtons ?? _getDefaultButtons();
  }

  /// Default keyboard buttons
  List<CustomKeyButton> _getDefaultButtons() {
    return [
      const CustomKeyButton.simpleKey(
        label: 'Tab',
        key: 'Tab',
        icon: Icons.space_bar,
      ),
      const CustomKeyButton.keyCombo(
        label: 'Ctrl+C',
        keySequence: ['ctrl', 'c'],
        icon: Icons.stop,
      ),
      const CustomKeyButton.simpleKey(
        label: 'Esc',
        key: 'Escape',
        icon: Icons.close,
      ),
      const CustomKeyButton.keyCombo(
        label: 'Ctrl+D',
        keySequence: ['ctrl', 'd'],
        icon: Icons.exit_to_app,
      ),
      const CustomKeyButton.simpleKey(
        label: '↑',
        key: 'ArrowUp',
        icon: Icons.arrow_upward,
      ),
      const CustomKeyButton.simpleKey(
        label: '↓',
        key: 'ArrowDown',
        icon: Icons.arrow_downward,
      ),
      const CustomKeyButton.simpleKey(
        label: '←',
        key: 'ArrowLeft',
        icon: Icons.arrow_back,
      ),
      const CustomKeyButton.simpleKey(
        label: '→',
        key: 'ArrowRight',
        icon: Icons.arrow_forward,
      ),
    ];
  }

  /// Send a single key to terminal
  void sendKey(String key) {
    try {
      terminal.keyboard.sendKey(
        key: key,
        ctrl: false,
        alt: false,
        shift: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send key: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Send key combination to terminal
  void sendKeyCombo(List<String> keys) {
    try {
      bool ctrl = false;
      bool alt = false;
      bool shift = false;
      String? mainKey;

      for (String key in keys) {
        if (key.toLowerCase() == 'ctrl') ctrl = true;
        if (key.toLowerCase() == 'alt') alt = true;
        if (key.toLowerCase() == 'shift') shift = true;
        if (!['ctrl', 'alt', 'shift'].contains(key.toLowerCase())) {
          mainKey = key;
        }
      }

      if (mainKey != null) {
        terminal.keyboard.sendKey(
          key: mainKey,
          ctrl: ctrl,
          alt: alt,
          shift: shift,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send key combination: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Handle button press
  void onButtonPressed(CustomKeyButton button) {
    if (button.onCustomAction != null) {
      button.onCustomAction!();
    } else if (button.keySequence != null) {
      sendKeyCombo(button.keySequence!);
    } else if (button.key != null) {
      sendKey(button.key!);
    }
  }

  /// Toggle keyboard visibility
  void toggleVisibility() {
    isVisible.toggle();
  }

  /// Toggle compact mode
  void toggleCompactMode() {
    isCompactMode.toggle();
  }

  /// Update buttons
  void updateButtons(List<CustomKeyButton> newButtons) {
    buttons.clear();
    buttons.addAll(newButtons);
    update();
  }
}

/// Custom Keyboard Bar Widget
class CustomKeyboardBar extends StatelessWidget {
  final CustomKeyboardController controller;
  final MainAxisAlignment alignment;
  final EdgeInsets padding;
  final double buttonHeight;
  final double spacing;

  const CustomKeyboardBar({
    Key? key,
    required this.controller,
    this.alignment = MainAxisAlignment.start,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.buttonHeight = 40.0,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                ...controller.buttons.map((button) {
                  return Obx(
                    () => _buildKeyButton(context, button, controller.isCompactMode.value),
                  );
                }),
                SizedBox(width: spacing),
                _buildControlButton(
                  context,
                  Icons.close,
                  'Hide',
                  () => controller.toggleVisibility(),
                ),
                SizedBox(width: spacing),
                _buildControlButton(
                  context,
                  controller.isCompactMode.value ? Icons.unfold_more : Icons.unfold_less,
                  controller.isCompactMode.value ? 'Expand' : 'Compact',
                  () => controller.toggleCompactMode(),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildKeyButton(BuildContext context, CustomKeyButton button, bool isCompact) {
    final backgroundColor = button.backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
    final foregroundColor = button.foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: SizedBox(
        height: buttonHeight,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6.0),
          child: InkWell(
            onTap: () => controller.onButtonPressed(button),
            borderRadius: BorderRadius.circular(6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: isCompact
                  ? (button.icon != null
                      ? Icon(button.icon, color: foregroundColor, size: 20)
                      : Text(
                          button.label,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ))
                  : Center(
                      child: Text(
                        button.label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: buttonHeight,
        width: buttonHeight,
        child: Material(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(6.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6.0),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simplified widget for terminal with keyboard bar
class TerminalWithKeyboardBar extends StatelessWidget {
  final Widget terminalView;
  final CustomKeyboardController keyboardController;
  final bool showKeyboardBar;

  const TerminalWithKeyboardBar({
    Key? key,
    required this.terminalView,
    required this.keyboardController,
    this.showKeyboardBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: terminalView),
        if (showKeyboardBar)
          CustomKeyboardBar(
            controller: keyboardController,
            alignment: MainAxisAlignment.start,
          ),
      ],
    );
  }
}
