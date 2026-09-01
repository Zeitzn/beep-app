import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountSelector extends StatefulWidget {
  final List<int> presetValues;
  final ValueChanged<double> onAmountSelected;

  const AmountSelector({
    super.key,
    this.presetValues = const [3, 4, 5],
    required this.onAmountSelected,
  });

  @override
  State<AmountSelector> createState() => _AmountSelectorState();
}

class _AmountSelectorState extends State<AmountSelector> {
  int? _selectedIndex;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      setState(() {
        _inputFocused = _inputFocusNode.hasFocus;
      });
    });
  }

  double? get _selectedAmount {
    if (_selectedIndex != null) {
      return widget.presetValues[_selectedIndex!].toDouble();
    }
    if (_inputController.text.isNotEmpty) {
      return double.tryParse(_inputController.text);
    }
    return null;
  }

  void _onPresetTap(int index) {
    setState(() {
      _selectedIndex = index;
      _inputController.clear();
    });
    _inputFocusNode.unfocus();
    _emitAmount();
  }

  void _onInputChanged(String value) {
    setState(() {
      if (value.isNotEmpty) {
        _selectedIndex = null;
      }
    });
    _emitAmount();
  }

  void _emitAmount() {
    final amount = _selectedAmount;
    if (amount != null) {
      widget.onAmountSelected(amount);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = theme.colorScheme.primary;

    return Row(
      children: [
        for (var i = 0; i < widget.presetValues.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _NumberButton(
            value: widget.presetValues[i],
            isSelected: _selectedIndex == i && !_inputFocused,
            onTap: () => _onPresetTap(i),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 64,
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '?',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: (_inputFocused ||
                        (_selectedIndex == null &&
                            _inputController.text.isNotEmpty))
                    ? purple
                    : Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: purple.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: purple.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: purple,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _onInputChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _NumberButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purple = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? purple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? purple : purple.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : purple,
          ),
        ),
      ),
    );
  }
}
