import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_theme.dart';

/// Horizontal strip of up to 3 photo thumbnails + an add tile.
/// Uses image_picker; downsizes via maxWidth/maxHeight to keep stored
/// images small (per spec: 200–500KB target).
class PhotoStrip extends StatefulWidget {
  final int maxPhotos;
  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final String addLabel;

  const PhotoStrip({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    required this.addLabel,
    this.maxPhotos = 3,
  });

  @override
  State<PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends State<PhotoStrip> {
  final _picker = ImagePicker();

  Future<void> _add() async {
    if (widget.photoPaths.length >= widget.maxPhotos) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    final next = List<String>.from(widget.photoPaths)..add(picked.path);
    widget.onChanged(next);
  }

  void _remove(int i) {
    final next = List<String>.from(widget.photoPaths)..removeAt(i);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.photoPaths.length;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count + (count < widget.maxPhotos ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i < count) {
            return _Thumb(
              path: widget.photoPaths[i],
              onRemove: () => _remove(i),
            );
          }
          return InkWell(
            onTap: _add,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.addLabel, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _Thumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Image.file(
            File(path),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 72,
              height: 72,
              color: theme.dividerColor.withValues(alpha: 0.4),
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
