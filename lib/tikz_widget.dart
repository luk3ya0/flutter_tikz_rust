import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'flutter_tikz_rust.dart';

/// A widget that renders TikZ code as SVG
class TikzWidget extends StatefulWidget {
  final String tikzCode;
  final double? width;
  final double? height;
  final BoxFit fit;

  const TikzWidget({
    Key? key,
    required this.tikzCode,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<TikzWidget> createState() => _TikzWidgetState();
}

class _TikzWidgetState extends State<TikzWidget> {
  String? _svg;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _renderTikz();
  }

  @override
  void didUpdateWidget(TikzWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tikzCode != widget.tikzCode) {
      _renderTikz();
    }
  }

  Future<void> _renderTikz() async {
    setState(() {
      _loading = true;
      _error = null;
      _svg = null;
    });

    try {
      // Render TikZ in a separate isolate to avoid blocking UI
      final svg = await Future.microtask(() {
        return FlutterTikzRust.tikzToSvg(widget.tikzCode);
      });

      if (mounted) {
        setState(() {
          _svg = svg;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.width ?? 100,
        height: widget.height ?? 100,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text(
                  'TikZ Render Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_svg == null) {
      return const SizedBox.shrink();
    }

    return SvgPicture.string(
      _svg!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

