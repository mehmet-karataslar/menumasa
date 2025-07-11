import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String? hintText;
  final String? initialValue;

  const CustomSearchBar({
    Key? key,
    required this.onSearchChanged,
    this.hintText,
    this.initialValue,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _controller.addListener(() {
      widget.onSearchChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTypography.inputText,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Ara...',
          hintStyle: AppTypography.inputHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _controller.clear();
                    _focusNode.unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
