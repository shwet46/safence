import 'package:flutter/material.dart';

class FloatingKeypad extends StatefulWidget {
  final ValueNotifier<bool>? visibleNotifier;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Offset? initialPosition;
  final String initialValue;

  const FloatingKeypad({
    super.key,
    this.visibleNotifier,
    this.onChanged,
    this.onSubmitted,
    this.initialPosition,
    this.initialValue = '',
  });

  @override
  State<FloatingKeypad> createState() => _FloatingKeypadState();
}

class _FloatingKeypadState extends State<FloatingKeypad> {
  late Offset _pos;
  late String _value;
  late ValueNotifier<bool> _visible;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPosition ?? const Offset(24, 200);
    _value = widget.initialValue;
    _visible = widget.visibleNotifier ?? ValueNotifier<bool>(false);
    _visible.addListener(_onVisibleChanged);
  }

  void _onVisibleChanged() => setState(() {});

  @override
  void dispose() {
    _visible.removeListener(_onVisibleChanged);
    // only dispose if we created it locally
    if (widget.visibleNotifier == null) _visible.dispose();
    super.dispose();
  }

  void _press(String key) {
    setState(() {
      if (key == '⌫') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (key == 'CLR') {
        _value = '';
      } else if (key == 'OK') {
        widget.onSubmitted?.call(_value);
        _visible.value = false;
      } else {
        _value = '$_value$key';
      }
    });
    widget.onChanged?.call(_value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible.value) return const SizedBox.shrink();

    final w = MediaQuery.of(context).size.width;
    final panelWidth = w * 0.86;

    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _pos = Offset(_pos.dx + d.delta.dx, _pos.dy + d.delta.dy);
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: panelWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 18)],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_value, style: const TextStyle(color: Colors.white, fontSize: 20))),
                    IconButton(
                      onPressed: () => _visible.value = false,
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildKeysRow(['1', '2', '3']),
                _buildKeysRow(['4', '5', '6']),
                _buildKeysRow(['7', '8', '9']),
                _buildKeysRow(['CLR', '0', '⌫']),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _press('OK'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8952D4)),
                        child: const Text('Done', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeysRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: keys.map((k) => _KeyButton(label: k, onTap: () => _press(k))).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSpecial = label == 'CLR' || label == '⌫';
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isSpecial ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(color: isSpecial ? Colors.white70 : Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
