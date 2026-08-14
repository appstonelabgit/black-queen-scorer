import 'package:flutter/widgets.dart';

/// Anchor rect for the iOS share sheet. iOS 26+ rejects share requests with
/// a zero [ShareParams.sharePositionOrigin] on iPhone too (was iPad-only),
/// so every SharePlus call must pass one.
Rect shareOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size != Size.zero) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: size.center(Offset.zero),
    width: 1,
    height: 1,
  );
}
