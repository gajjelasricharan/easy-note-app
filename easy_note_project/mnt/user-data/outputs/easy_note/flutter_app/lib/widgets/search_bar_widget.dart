// lib/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final void Function(String) onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      onChanged: widget.onChanged,
      style: GoogleFonts.dmSans(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search notes...',
        hintStyle: GoogleFonts.dmSans(color: AppTheme.warmGray, fontSize: 15),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.warmGray),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                },
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.warmGray),
              )
            : null,
        filled: true,
        fillColor: AppTheme.warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
