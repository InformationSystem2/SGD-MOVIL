import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla de escaneo estilo Adobe Scan.
/// Retorna List<XFile> al hacer pop con Navigator.pop(context, pages).
class ScannerScreen extends StatefulWidget {
  final List<XFile> initialPages;

  const ScannerScreen({super.key, this.initialPages = const []});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  late List<XFile> _pages;
  int? _previewIndex;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.initialPages);
    // Si no hay páginas aún, abre la cámara automáticamente
    if (_pages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureCamera());
    }
  }

  Future<void> _captureCamera() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() => _pages.add(photo));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a la cámara: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 92);
      if (picked.isNotEmpty) {
        setState(() => _pages.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a galería: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removePage(int index) {
    setState(() {
      _pages.removeAt(index);
      if (_previewIndex != null) {
        if (_previewIndex! >= _pages.length) {
          _previewIndex = _pages.isEmpty ? null : _pages.length - 1;
        }
      }
    });
  }

  void _done() {
    if (_pages.isEmpty) {
      Navigator.of(context).pop(<XFile>[]);
      return;
    }
    Navigator.of(context).pop(_pages);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPreview = _previewIndex != null ? _pages[_previewIndex!] : (_pages.isNotEmpty ? _pages.last : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(<XFile>[]),
                    tooltip: 'Cancelar',
                  ),
                  const Spacer(),
                  if (_pages.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Text(
                        '${_pages.length} página${_pages.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            // ── Preview area ───────────────────────────────────────────────
            Expanded(
              child: _pages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.document_scanner_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Toca el botón de cámara\npara escanear',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (_previewIndex == null) return;
                        if (details.primaryVelocity! < 0 && _previewIndex! < _pages.length - 1) {
                          setState(() => _previewIndex = _previewIndex! + 1);
                        } else if (details.primaryVelocity! > 0 && _previewIndex! > 0) {
                          setState(() => _previewIndex = _previewIndex! - 1);
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (currentPreview != null)
                            Image.file(
                              File(currentPreview.path),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          // Delete button on preview
                          if (_previewIndex != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removePage(_previewIndex!),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),

            // ── Thumbnail strip ────────────────────────────────────────────
            if (_pages.isNotEmpty)
              Container(
                height: 80,
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pages.length,
                  itemBuilder: (context, idx) {
                    final isSelected = (_previewIndex ?? _pages.length - 1) == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _previewIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.file(File(_pages[idx].path), fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              left: 4,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removePage(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Bottom action bar ─────────────────────────────────────────
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery button
                  _ActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galería',
                    onTap: _busy ? null : _pickGallery,
                    size: 52,
                  ),

                  // Camera shutter (main button)
                  GestureDetector(
                    onTap: _busy ? null : _captureCamera,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: _busy ? Colors.white38 : Colors.white,
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 36, color: Colors.black),
                    ),
                  ),

                  // Done button
                  _ActionButton(
                    icon: Icons.check_circle_rounded,
                    label: _pages.isEmpty ? 'Listo' : 'Usar (${_pages.length})',
                    onTap: _pages.isEmpty ? null : _done,
                    size: 52,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 48,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(icon, color: color, size: size * 0.45),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
