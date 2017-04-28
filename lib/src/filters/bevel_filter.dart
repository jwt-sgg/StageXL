library stagexl.filters.bevel;

import 'dart:math' hide Point, Rectangle;
import 'dart:html' show ImageData;

import 'inner_drop_shadow_filter.dart';
import 'drop_shadow_filter.dart';
import '../display.dart';
import '../engine.dart';
import '../geom.dart';
import '../internal/filter_helpers.dart';
import '../internal/tools.dart';

class BevelFilter extends BitmapFilter {

  num _distance;
  num _angle;
  int _blurX;
  int _blurY;
  int _quality;
  int _lightColor;
  int _shadowColor;
  int _lightPassCount;

  final List<int> _renderPassSources = new List<int>();
  final List<int> _renderPassTargets = new List<int>();
  final List<int> _preservedTargets = new List<int>();

  RenderTextureQuad pass0Source;

  BevelFilter([
    num distance = 8, num angle = PI / 4,
    int lightColor = 0xFF000000, int shadowColor = 0xFF000000,
    int blurX = 4, int blurY = 4, int quality = 1]) {

    this.distance = distance;
    this.angle = angle;
    this.lightColor = lightColor;
    this.shadowColor = shadowColor;
    this.blurX = blurX;
    this.blurY = blurY;
    this.quality = quality;
  }

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------

  @override
  BitmapFilter clone() {
    return new BevelFilter(
      distance, angle, lightColor, shadowColor, blurX, blurY, quality);
  }

/*
  @override
  Rectangle<int> get overlap {
    int shiftX = (this.distance * cos(this.angle)).round();
    int shiftY = (this.distance * sin(this.angle)).round();
    var sRect = new Rectangle<int>(-1, -1, 2, 2);
    var dRect = new Rectangle<int>(shiftX - blurX, shiftY - blurY, 2 * blurX, 2 * blurY);
    return sRect.boundingBox(dRect);
  }
*/

  @override
  Rectangle<int> get overlap {
    var sRect = new Rectangle<int>(-1, -1, 1, 1);
    return sRect;
  }

  @override
  List<int> get renderPassSources => _renderPassSources;

  @override
  List<int> get renderPassTargets => _renderPassTargets;

  @override
  List<int> get preservedTargets => _preservedTargets;

  //---------------------------------------------------------------------------

  /// The distance from the object to the shadow.

  num get distance => _distance;

  set distance(num value) {
    _distance = value;
  }

  /// The angle where the shadow is casted to.

  num get angle => _angle;

  set angle(num value) {
    _angle = value;
  }

  /// The color of the light.

  int get lightColor => _lightColor;

  set lightColor(int value) {
    _lightColor = value;
  }

  /// The color of the shadow.

  int get shadowColor => _shadowColor;

  set shadowColor(int value) {
    _shadowColor = value;
  }

  /// The horizontal blur radius in the range from 0 to 64.

  int get blurX => _blurX;

  set blurX(int value) {
    RangeError.checkValueInInterval(value, 0, 64);
    _blurX = value;
  }

  /// The vertical blur radius in the range from 0 to 64.

  int get blurY => _blurY;

  set blurY(int value) {
    RangeError.checkValueInInterval(value, 0, 64);
    _blurY = value;
  }

  /// The quality of the shadow in the range from 1 to 5.
  /// A small value is sufficent for small blur radii, a high blur
  /// radius may require a heigher quality setting.

  int get quality => _quality;

  set quality(int value) {

    RangeError.checkValueInInterval(value, 1, 5);

    _quality = value;
    _renderPassSources.clear();
    _renderPassTargets.clear();
    _preservedTargets.clear();

    for(int i = 0; i < value*2; i++) {
      _renderPassSources.add(i * 2 + 0);
      _renderPassSources.add(i * 2 + 1);
      _renderPassTargets.add(i * 2 + 1);
      _renderPassTargets.add(i * 2 + 2);
    }

    _lightPassCount = value*2;

    _preservedTargets.add(0);
    _preservedTargets.add(_lightPassCount);
  }

  //---------------------------------------------------------------------------

  @override
  void apply(BitmapData bitmapData, [Rectangle<num> rectangle]) {
/*
NOTE: this is the drop shadow filter apply (minus knock out and hideObject
      The BevelFilter version would need to be created similar to this & InnerDropShadowFilter

    RenderTextureQuad renderTextureQuad = rectangle == null
        ? bitmapData.renderTextureQuad
        : bitmapData.renderTextureQuad.cut(rectangle);

    ImageData sourceImageData = renderTextureQuad.getImageData();

    ImageData imageData = renderTextureQuad.getImageData();
    List<int> data = imageData.data;
    int width = ensureInt(imageData.width);
    int height = ensureInt(imageData.height);
    int shiftX = (this.distance * cos(this.angle)).round();
    int shiftY = (this.distance * sin(this.angle)).round();

    num pixelRatio = renderTextureQuad.pixelRatio;
    int blurX = (this.blurX * pixelRatio).round();
    int blurY = (this.blurY * pixelRatio).round();
    int alphaChannel = BitmapDataChannel.getCanvasIndex(BitmapDataChannel.ALPHA);
    int stride = width * 4;

    shiftChannel(data, 3, width, height, shiftX, shiftY);

    for (int x = 0; x < width; x++) {
      blur(data, x * 4 + alphaChannel, height, stride, blurY);
    }

    for (int y = 0; y < height; y++) {
      blur(data, y * stride + alphaChannel, width, 4, blurX);
    }

    setColorBlend(data, this.color, sourceImageData.data);

    renderTextureQuad.putImageData(imageData);
*/
  }

  //---------------------------------------------------------------------------

  @override
  void renderFilter(RenderState renderState,
                    RenderTextureQuad renderTextureQuad, int pass) {

    RenderContextWebGL renderContext = renderState.renderContext;
    RenderTexture renderTexture = renderTextureQuad.renderTexture;
    int passCount = _renderPassSources.length;
    num passScale = pow(0.5, pass >> 1);
    num pixelRatio = sqrt(renderState.globalMatrix.det.abs());
    num pixelRatioScale = pixelRatio * passScale;
    num pixelRatioDistance = pixelRatio * distance;

    int color = pass < _lightPassCount ? _lightColor : _shadowColor;
    num angle = pass < _lightPassCount ? _angle : _angle + PI;

    if ( ( pass == 0 ) || ( pass == _lightPassCount ) )
    {
      InnerDropShadowFilterProgram renderProgram = renderContext.getRenderProgram(
          r"$InnerDropShadowFilterProgram", () => new InnerDropShadowFilterProgram());

      renderContext.activateRenderProgram(renderProgram);
      renderContext.activateRenderTexture(renderTexture);

      renderProgram.configure(
          color | 0xFF000000,
          1.0,
          pixelRatioDistance * cos(angle) / renderTexture.width,
          pixelRatioDistance * sin(angle) / renderTexture.height,
          pixelRatioScale * blurX / renderTexture.width,
          0.0 );

      renderProgram.renderTextureQuad(renderState, renderTextureQuad);
      renderProgram.flush();

      pass0Source = renderTextureQuad;
    }
    else
    if ( (pass == _lightPassCount - 1) || (pass == passCount - 1) )
    {
      InnerDropShadowFilterBlendProgram renderProgram = renderContext.getRenderProgram(
          r"InnerDropShadowFilterBlendProgram", () => new InnerDropShadowFilterBlendProgram());

      renderContext.activateRenderProgram(renderProgram);
      renderContext.activateRenderTexture(renderTexture);
      renderContext.activateRenderTextureAt(pass0Source.renderTexture,1);

      renderProgram.configure(
          color,
          renderState.globalAlpha,
          0.0,
          0.0,
          0.0,
          pixelRatioScale * blurY / renderTexture.height);

      renderProgram.renderTextureQuad(renderState, renderTextureQuad);
      renderProgram.flush();

      pass0Source = null;
    }
    else
    {
      DropShadowFilterProgram renderProgram = renderContext.getRenderProgram(
          r"$DropShadowFilterProgram", () => new DropShadowFilterProgram());

      renderContext.activateRenderProgram(renderProgram);
      renderContext.activateRenderTexture(renderTexture);

      renderProgram.configure(
          color | 0xFF000000,
          1.0,
          0.0,
          0.0,
          pass.isEven ? pixelRatioScale * blurX / renderTexture.width : 0.0,
          pass.isEven ? 0.0 : pixelRatioScale * blurY / renderTexture.height);

      renderProgram.renderTextureQuad(renderState, renderTextureQuad);
      renderProgram.flush();
    }
  }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
/*

class InnerDropShadowFilterProgram extends RenderProgramSimple {

  @override
  String get vertexShaderSource => """

    uniform mat4 uProjectionMatrix;
    uniform vec2 uRadius;
    uniform vec2 uShift;

    attribute vec2 aVertexPosition;
    attribute vec2 aVertexTextCoord;

    varying vec2 vBlurCoords[7];

    void main() {
      vec2 texCoord = aVertexTextCoord - uShift;
      vBlurCoords[0] = texCoord - uRadius * 1.2;
      vBlurCoords[1] = texCoord - uRadius * 0.8;
      vBlurCoords[2] = texCoord - uRadius * 0.4;
      vBlurCoords[3] = texCoord;
      vBlurCoords[4] = texCoord + uRadius * 0.4;
      vBlurCoords[5] = texCoord + uRadius * 0.8;
      vBlurCoords[6] = texCoord + uRadius * 1.2;
      gl_Position = vec4(aVertexPosition, 0.0, 1.0) * uProjectionMatrix;
    }
    """;

  @override
  String get fragmentShaderSource => """

    precision mediump float;

    uniform sampler2D uSampler;
    uniform vec4 uColor;
      
    varying vec2 vBlurCoords[7];

    void main() {
      float alpha = 0.0;
      alpha += texture2D(uSampler, vBlurCoords[0]).a * 0.00443;
      alpha += texture2D(uSampler, vBlurCoords[1]).a * 0.05399;
      alpha += texture2D(uSampler, vBlurCoords[2]).a * 0.24197;
      alpha += texture2D(uSampler, vBlurCoords[3]).a * 0.39894;
      alpha += texture2D(uSampler, vBlurCoords[4]).a * 0.24197;
      alpha += texture2D(uSampler, vBlurCoords[5]).a * 0.05399;
      alpha += texture2D(uSampler, vBlurCoords[6]).a * 0.00443;
      alpha = 1.0 - alpha;
      alpha *= uColor.a;
      gl_FragColor = vec4(uColor.rgb * alpha, alpha);
    }
    """;

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------

  void configure(
      int color, num alpha,
      num shiftX, num shiftY,
      num radiusX, num radiusY) {

    num r = colorGetR(color) / 255.0;
    num g = colorGetG(color) / 255.0;
    num b = colorGetB(color) / 255.0;
    num a = colorGetA(color) / 255.0 * alpha;

    renderingContext.uniform2f(uniforms["uShift"], shiftX, shiftY);
    renderingContext.uniform2f(uniforms["uRadius"], radiusX, radiusY);
    renderingContext.uniform4f(uniforms["uColor"], r, g, b, a);
  }

}
//-----------------------------------------------------------------------------

class InnerDropShadowFilterBlendProgram extends RenderProgramSimple {

  @override
  String get vertexShaderSource => """

    uniform mat4 uProjectionMatrix;
    uniform vec2 uRadius;
    uniform vec2 uShift;

    attribute vec2 aVertexPosition;
    attribute vec2 aVertexTextCoord;

    varying vec2 vSrcCoords;
    varying vec2 vBlurCoords[7];

    void main() {
      vSrcCoords = aVertexTextCoord;
      vec2 texCoord = aVertexTextCoord - uShift;
      vBlurCoords[0] = texCoord - uRadius * 1.2;
      vBlurCoords[1] = texCoord - uRadius * 0.8;
      vBlurCoords[2] = texCoord - uRadius * 0.4;
      vBlurCoords[3] = texCoord;
      vBlurCoords[4] = texCoord + uRadius * 0.4;
      vBlurCoords[5] = texCoord + uRadius * 0.8;
      vBlurCoords[6] = texCoord + uRadius * 1.2;
      gl_Position = vec4(aVertexPosition, 0.0, 1.0) * uProjectionMatrix;
    }
    """;

  @override
  String get fragmentShaderSource => """

    precision mediump float;

    uniform sampler2D uSrcSampler;
    uniform sampler2D uSampler;
    uniform vec4 uColor;

    varying vec2 vSrcCoords;
    varying vec2 vBlurCoords[7];

    void main() {
      float alpha = 0.0;
      alpha += texture2D(uSampler, vBlurCoords[0]).a * 0.00443;
      alpha += texture2D(uSampler, vBlurCoords[1]).a * 0.05399;
      alpha += texture2D(uSampler, vBlurCoords[2]).a * 0.24197;
      alpha += texture2D(uSampler, vBlurCoords[3]).a * 0.39894;
      alpha += texture2D(uSampler, vBlurCoords[4]).a * 0.24197;
      alpha += texture2D(uSampler, vBlurCoords[5]).a * 0.05399;
      alpha += texture2D(uSampler, vBlurCoords[6]).a * 0.00443;
      alpha *= uColor.a;
      vec4 srcColor = texture2D(uSrcSampler,vSrcCoords);
      gl_FragColor = vec4(((srcColor.rgb*(1.0-alpha))+(uColor.rgb * alpha))*srcColor.a, srcColor.a);
    }
    """;

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------

  void configure(
      int color, num alpha,
      num shiftX, num shiftY,
      num radiusX, num radiusY) {

    renderingContext.uniform1i(uniforms["uSrcSampler"], 1);

    num r = colorGetR(color) / 255.0;
    num g = colorGetG(color) / 255.0;
    num b = colorGetB(color) / 255.0;
    num a = colorGetA(color) / 255.0 * alpha;

    renderingContext.uniform2f(uniforms["uShift"], shiftX, shiftY);
    renderingContext.uniform2f(uniforms["uRadius"], radiusX, radiusY);
    renderingContext.uniform4f(uniforms["uColor"], r, g, b, a);
  }

}
*/
