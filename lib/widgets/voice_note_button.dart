import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/speech_recognition.dart';

class VoiceNoteButton extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageToggle;
  final ValueChanged<String> onTranscript;

  const VoiceNoteButton({
    super.key,
    required this.currentLanguage,
    required this.onLanguageToggle,
    required this.onTranscript,
  });

  @override
  State<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

class _VoiceNoteButtonState extends State<VoiceNoteButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  final _helper = SpeechRecognitionHelper();

  String get _langCode =>
      widget.currentLanguage == 'ML' ? 'ml-IN' : 'en-IN';

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
    if (_isRecording) _helper.stop();
    super.dispose();
  }

  void _onEnd() {
    if (!mounted || !_isRecording) return;
    setState(() => _isRecording = false);
    _animController.stop();
    _animController.reset();
  }

  void _toggle() {
    if (_isRecording) {
      _helper.stop();
      _onEnd();
    } else {
      setState(() => _isRecording = true);
      _animController.repeat(reverse: true);
      _helper.start(_langCode, widget.onTranscript, _onEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = speechRecognitionSupported;
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
          onTap: supported ? _toggle : null,
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: supported ? AppColors.primary : Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.mic,
                    color: supported ? Colors.white : Colors.grey,
                    size: 22,
                  ),
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
