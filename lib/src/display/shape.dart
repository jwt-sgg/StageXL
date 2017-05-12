part of stagexl.display;

/// This class is used to create lightweight shapes.
///
/// The Shape class includes a [graphics] property, which lets you access
/// methods from the [Graphics] class.
///
/// The [Sprite] class also includes a graphic sproperty, and it includes other
/// features not available to the [Shape] class. For example, a [Sprite] object
/// is a display object container, whereas a [Shape] object is not (and cannot
/// contain child display objects). For this reason, [Shape] objects consume
/// less memory than [Sprite] objects that contain the same graphics. However, a
/// [Sprite] object supports user input events, while a [Shape] object does not.
class Shape extends DisplayObject {

  /// Specifies the graphics object belonging to this Shape object, where vector
  /// drawing commands can occur.
  Graphics graphics = new Graphics();

  @override
  Rectangle<num> get unfilteredBounds {
    if ( _scrollRect != null ) return _scrollRect.clone();
    return graphics != null ? graphics.bounds : super.bounds;
  }

  @override
  DisplayObject hitTestInput(num localX, num localY) {
    if (graphics == null) return null;
    if ( _scrollRect != null ) {
      if ( !this.bounds.contains(localX, localY) ) return null;
      localX += _scrollRect.left;
      localY += _scrollRect.top;
    }
    if (graphics.hitTest(localX, localY)) return this;
    return null;
  }

  @override
  void render(RenderState renderState) {
    if (graphics != null) graphics.render(renderState);
  }
}
