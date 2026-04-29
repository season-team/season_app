import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrShareService {
  static Future<void> shareGroupQR({
    required String inviteCode,
    required String groupName,
    required bool isRtl,
  }) async {
    try {
      // Create QR code widget
      final qrWidget = _buildQRWidget(inviteCode, groupName, isRtl);
      
      // Convert to image
      final image = await _widgetToImage(qrWidget);
      
      // Save to file
      final file = await _saveImageToFile(image);
      
      // Share
      final message = isRtl
          ? 'انضم إلى مجموعتي "$groupName" على Season!\nكود الدعوة: $inviteCode'
          : 'Join my group "$groupName" on Season!\nInvite code: $inviteCode';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
      );
    } catch (e) {
      print('Error sharing QR code: $e');
      rethrow;
    }
  }

  static Widget _buildQRWidget(String inviteCode, String groupName, bool isRtl) {
    return Container(
      width: 400,
      height: 400,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFFF8A3C).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // QR Code
                  QrImageView(
                    data: inviteCode,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D3748),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Invite Code
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFF8A3C).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instruction
            Text(
              isRtl
                  ? 'امسح الرمز للانضمام إلى المجموعة'
                  : 'Scan to join the group',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Future<ui.Image> _widgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
        logicalConstraints: BoxConstraints(maxWidth: 400, maxHeight: 400),
        devicePixelRatio: 3.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 3.0);
    return image;
  }

  static Future<File> _saveImageToFile(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/group_qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);

    return file;
  }
}

