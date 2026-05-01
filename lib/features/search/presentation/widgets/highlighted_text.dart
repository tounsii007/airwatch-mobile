import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color highlightColor;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index < 0) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index), style: baseStyle),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: baseStyle.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
              style: baseStyle,
            ),
        ],
      ),
    );
  }
}
