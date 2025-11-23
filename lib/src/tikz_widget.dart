import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'flutter_tikz_rust_ffi.dart';
import 'dart:async';
import 'dart:isolate';

/// Message for isolate communication
class _IsolateMessage {
  final String tikzCode;
  final SendPort sendPort;
  
  _IsolateMessage(this.tikzCode, this.sendPort);
}

/// Global queue for TikZ rendering to ensure sequential execution
class TikzRenderQueue {
  static final TikzRenderQueue _instance = TikzRenderQueue._internal();
  factory TikzRenderQueue() => _instance;
  TikzRenderQueue._internal();

  final List<_QueuedTask> _queue = [];
  bool _processing = false;
  bool _documentReady = false;
  DateTime? _documentLoadTime;

  /// Mark when document starts loading
  void markDocumentLoading() {
    _documentLoadTime = DateTime.now();
    _documentReady = false;
    debugPrint('📄 TikZ: Document loading started');
  }

  /// Mark when document is ready (parsed and displayed)
  void markDocumentReady() {
    if (_documentLoadTime != null) {
      final elapsed = DateTime.now().difference(_documentLoadTime!);
      debugPrint('📄 TikZ: Document ready after ${elapsed.inMilliseconds}ms');
    }
    
    // Wait a bit more to ensure UI is stable before starting renders
    Future.delayed(const Duration(milliseconds: 500), () {
      _documentReady = true;
      debugPrint('✅ TikZ: Ready to start rendering');
      _processQueue();
    });
  }

  /// Add a render task to the queue
  Future<String> enqueue(String tikzCode) async {
    final completer = Completer<String>();
    
    _queue.add(_QueuedTask(tikzCode, completer));
    debugPrint('📐 TikZ: Task queued (queue size: ${_queue.length})');
    
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    // Don't start processing until document is ready
    if (!_documentReady) {
      debugPrint('⏳ TikZ: Waiting for document to be ready...');
      return;
    }
    
    if (_processing || _queue.isEmpty) return;
    
    _processing = true;
    debugPrint('🚀 TikZ: Starting queue processing (${_queue.length} tasks)');
    
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      
      try {
        debugPrint('🎨 TikZ: Starting render (queue size: ${_queue.length})');
        
        // Run FFI call in a separate isolate to avoid blocking UI
        final svg = await _renderInIsolate(task.tikzCode);
        
        debugPrint('✅ TikZ: Render complete');
        task.completer.complete(svg);
      } catch (e) {
        debugPrint('❌ TikZ: Render error: $e');
        task.completer.completeError(e);
      }
      
      // Delay between renders to keep UI responsive
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    _processing = false;
    debugPrint('✅ TikZ: Queue processing complete');
  }

  /// Run TikZ rendering in a separate isolate
  static Future<String> _renderInIsolate(String tikzCode) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateEntry,
      _IsolateMessage(tikzCode, receivePort.sendPort),
    );
    
    final result = await receivePort.first;
    
    if (result is String) {
      return result;
    } else if (result is Exception) {
      throw result;
    } else {
      throw Exception('Unknown error in isolate: $result');
    }
  }

  /// Isolate entry point
  static void _isolateEntry(_IsolateMessage message) {
    try {
      final svg = FlutterTikzRust.tikzToSvg(message.tikzCode);
      message.sendPort.send(svg);
    } catch (e) {
      message.sendPort.send(Exception('TikZ render failed: $e'));
    }
  }
}

class _QueuedTask {
  final String tikzCode;
  final Completer<String> completer;
  
  _QueuedTask(this.tikzCode, this.completer);
}

typedef ErrorWidgetBuilder = Widget Function(BuildContext context, Object error);

/// Widget for displaying TikZ diagrams
/// 
/// Similar to TexImage, this widget uses FutureBuilder to render asynchronously
/// and display a placeholder while rendering.
class TikzWidget extends StatefulWidget {
  const TikzWidget({
    required this.tikzCode,
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.error,
    this.alignment = Alignment.center,
    this.keepAlive = true,
    Key? key,
  }) : super(key: key);

  /// TikZ code to render
  final String tikzCode;
  
  /// Color to apply to the SVG (for dark/light mode adaptation)
  final Color? color;
  
  /// Width of the rendered image
  final double? width;
  
  /// Height of the rendered image
  final double? height;
  
  /// How to fit the SVG within its bounds
  final BoxFit fit;
  
  /// Widget to display while rendering
  final Widget? placeholder;
  
  /// Builder for error widget
  final ErrorWidgetBuilder? error;
  
  /// Alignment of the image
  final AlignmentGeometry alignment;
  
  /// Whether to keep the widget alive when scrolled out of view
  final bool keepAlive;

  @override
  State<TikzWidget> createState() => _TikzWidgetState();
}

class _TikzWidgetState extends State<TikzWidget>
    with AutomaticKeepAliveClientMixin<TikzWidget> {
  
  String get id => widget.key?.hashCode.toString() ?? identityHashCode(this).toString();
  
  Future<String>? _renderFuture;
  String? _lastTikzCode;

  @override
  void dispose() {
    // TODO: Implement cancel if needed
    super.dispose();
  }

  // Memoize the Future to prevent spurious re-renders
  Future<String> _buildRenderFuture(String tikzCode) {
    if (_renderFuture == null || tikzCode != _lastTikzCode) {
      debugPrint('📐 TikZ: Creating render future for widget $id');
      _renderFuture = TikzRenderQueue().enqueue(tikzCode);
      _lastTikzCode = tikzCode;
    } else {
      debugPrint('📐 TikZ: Reusing existing render future for widget $id');
    }
    return _renderFuture!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.tikzCode.trim().isEmpty) {
      return Text(widget.tikzCode);
    }
    
    // Get text color from context for dark/light mode adaptation
    final textStyle = DefaultTextStyle.of(context).style;
    final color = widget.color ?? textStyle.color;
    
    return FutureBuilder<String>(
      future: _buildRenderFuture(widget.tikzCode),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Render complete - show SVG
          // Use Container with padding to prevent clipping when scaled
          return Container(
            // Add padding to accommodate 1.5x scale (50% extra space = 25% on each side)
            // Use generous padding since we can't add border in LaTeX (rust_tikz limitation)
            padding: const EdgeInsets.all(50),
            child: Transform.scale(
              scale: 1.5,
              child: SvgPicture.string(
                snapshot.data!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                alignment: widget.alignment,
                // Don't use colorFilter - it replaces ALL colors
                // TikZ should render with correct colors from the start
                colorFilter: null,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // Error occurred
          return _buildErrorWidget(snapshot.error!);
        } else {
          // Still rendering - show placeholder
          return widget.placeholder ?? _buildDefaultPlaceholder();
        }
      },
    );
  }
  
  /// Check if we should apply color filter
  /// Only apply for black/white colors (default text colors)
  /// to preserve user-defined colors in TikZ
  bool _shouldApplyColorFilter(Color? color) {
    if (color == null) return false;
    
    // Check if color is close to black or white
    final isBlack = color.red < 50 && color.green < 50 && color.blue < 50;
    final isWhite = color.red > 200 && color.green > 200 && color.blue > 200;
    
    return isBlack || isWhite;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height ?? 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rendering TikZ...',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    final errorBuilder = widget.error ?? _defaultError;
    return errorBuilder(context, error);
  }

  Widget _defaultError(BuildContext context, Object error) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.withOpacity(0.7), size: 16),
              const SizedBox(width: 4),
              Text(
                'TikZ Render Error',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.red.withOpacity(0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
