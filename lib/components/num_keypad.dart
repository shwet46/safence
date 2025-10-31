import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumKeypad extends StatefulWidget {
  final void Function(String number) onCall;
  final void Function(String number)? onSms;
  final VoidCallback? onClose;
  final String? initialNumber;

  const NumKeypad({
    super.key,
    required this.onCall,
    this.onSms,
    this.onClose,
    this.initialNumber,
  });

  @override
  State<NumKeypad> createState() => _NumKeypadState();
}

class _NumKeypadState extends State<NumKeypad> with SingleTickerProviderStateMixin {
  String _number = '';
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _number = widget.initialNumber ?? '';
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _append(String ch) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_number.length < 20) _number += ch;
    });
  }

  void _backspace() {
    if (_number.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _number = _number.substring(0, _number.length - 1);
    });
  }

  void _clearAll() {
    if (_number.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _number = '');
  }

  String _keyPadSublabel(String key) {
    switch (key) {
      case '2':
        return 'ABC';
      case '3':
        return 'DEF';
      case '4':
        return 'GHI';
      case '5':
        return 'JKL';
      case '6':
        return 'MNO';
      case '7':
        return 'PQRS';
      case '8':
        return 'TUV';
      case '9':
        return 'WXYZ';
      case '0':
        return '+';
      default:
        return '';
    }
  }

  Widget _buildKey(String label, {double size = 70}) {
    final sub = _keyPadSublabel(label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _append(label),
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: const Color(0xFF8952D4).withOpacity(0.3),
        highlightColor: const Color(0xFF8952D4).withOpacity(0.1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F1F1F),
                const Color(0xFF151515),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F0F),
              const Color(0xFF0A0A0A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF8952D4).withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _number.isNotEmpty 
                      ? const Color(0xFF8952D4).withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    color: _number.isNotEmpty 
                        ? const Color(0xFF8952D4) 
                        : Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: _number.isEmpty 
                            ? Colors.white.withOpacity(0.4) 
                            : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      child: Text(
                        _number.isEmpty ? 'Enter number' : _number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Keypad grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']) 
                  _buildKey(k),
              ],
            ),

            const SizedBox(height: 20),


            Row(
              children: [
                InkWell(
                  onTap: _backspace,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      Icons.backspace_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // SMS and Call buttons
                Expanded(
                  child: Row(
                    children: [
                      // SMS button
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: (_number.isNotEmpty && widget.onSms != null)
                                  ? [
                                      const Color(0xFF2A2A2A),
                                      const Color(0xFF1F1F1F),
                                    ]
                                  : [
                                      const Color(0xFF151515),
                                      const Color(0xFF121212),
                                    ],
                            ),
                            border: Border.all(
                              color: (_number.isNotEmpty && widget.onSms != null)
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_number.isNotEmpty && widget.onSms != null)
                                  ? () {
                                      widget.onSms!(_number);
                                      widget.onClose?.call();
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message_rounded,
                                    color: (_number.isNotEmpty && widget.onSms != null)
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SMS',
                                    style: TextStyle(
                                      color: (_number.isNotEmpty && widget.onSms != null)
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Call button
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: _number.isNotEmpty
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF9B5FE8),
                                      const Color(0xFF8952D4),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFF2A2A2A),
                                      const Color(0xFF1F1F1F),
                                    ],
                                  ),
                            boxShadow: _number.isNotEmpty
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8952D4).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _number.isNotEmpty
                                  ? () {
                                      widget.onCall(_number);
                                      widget.onClose?.call();
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_rounded,
                                    color: _number.isNotEmpty
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      color: _number.isNotEmpty
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Clear all button
                InkWell(
                  onTap: _clearAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      Icons.clear_all_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}