import 'package:flutter/material.dart';
import '../theme.dart';

class VoiceNoteButton extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageToggle;

  const VoiceNoteButton({
    super.key,
    required this.currentLanguage,
    required this.onLanguageToggle,
  });

  @override
  State<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

class _VoiceNoteButtonState extends State<VoiceNoteButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      _animController.repeat(reverse: true);
    } else {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _LangChip(
              label: 'EN',
              isSelected: widget.currentLanguage == 'EN',
              onTap: () => widget.onLanguageToggle('EN'),
            ),
            const SizedBox(width: 6),
            _LangChip(
              label: 'ML',
              isSelected: widget.currentLanguage == 'ML',
              onTap: () => widget.onLanguageToggle('ML'),
            ),
          ],
        ),
        GestureDetector(
          onTap: _toggle,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isRecording)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context2, child2) => Container(
                      width: 44 * _pulseAnim.value,
                      height: 44 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }
}
