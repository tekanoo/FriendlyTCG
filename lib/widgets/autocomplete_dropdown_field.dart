import 'package:flutter/material.dart';

class AutocompleteDropdownField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final List<String> options;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool strictValidation; // Nouveau: validation stricte dans la liste

  const AutocompleteDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    required this.options,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.strictValidation = false,
  });

  @override
  State<AutocompleteDropdownField> createState() => _AutocompleteDropdownFieldState();
}

class _AutocompleteDropdownFieldState extends State<AutocompleteDropdownField> {
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownOpen = false;
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isDropdownOpen = true;
        _filterOptions(widget.controller.text);
      });
    }
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredOptions = widget.options
            .where((option) => option.toLowerCase().contains(lowerQuery))
            .toList();
      }
    });
  }

  void _selectOption(String option) {
    widget.controller.text = option;
    widget.onChanged?.call(option);
    setState(() {
      _isDropdownOpen = false;
    });
    _focusNode.unfocus();
  }

  void _closeDropdown() {
    setState(() {
      _isDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator ?? (widget.strictValidation ? (value) {
            if (widget.isRequired && (value == null || value.isEmpty)) {
              return 'Ce champ est obligatoire';
            }
            if (widget.strictValidation && value != null && value.isNotEmpty && !widget.options.contains(value)) {
              return 'Veuillez sélectionner une option dans la liste';
            }
            return null;
          } : null),
          onChanged: (value) {
            _filterOptions(value);
            widget.onChanged?.call(value);
          },
          onTap: () {
            setState(() {
              _isDropdownOpen = true;
              _filterOptions(widget.controller.text);
            });
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                      _filterOptions('');
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
                  onPressed: () {
                    if (_isDropdownOpen) {
                      _closeDropdown();
                      _focusNode.unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isDropdownOpen && _filteredOptions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredOptions.length,
              itemBuilder: (context, index) {
                final option = _filteredOptions[index];
                final query = widget.controller.text.toLowerCase();
                
                return ListTile(
                  dense: true,
                  title: _buildHighlightedText(option, query),
                  onTap: () => _selectOption(option),
                  hoverColor: Colors.blue.shade50,
                );
              },
            ),
          ),
        if (_isDropdownOpen)
          GestureDetector(
            onTap: _closeDropdown,
            child: Container(
              color: Colors.transparent,
              height: 50,
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(text);
    }

    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          if (startIndex > 0)
            TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.yellow,
            ),
          ),
          if (endIndex < text.length)
            TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }
}
