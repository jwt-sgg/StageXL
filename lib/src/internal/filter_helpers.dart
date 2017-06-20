library stagexl.internal.filter_helpers;

import 'dart:typed_data';
import 'environment.dart' as env;
import 'tools.dart';

const int BUFFER_SIZE = 2048;
const int BUFFER_SIZE_BITMASK = BUFFER_SIZE-1;
Int32List _buffer = new Int32List(BUFFER_SIZE);

//-----------------------------------------------------------------------------------------------

void premultiplyAlpha(List<int> data) {

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= data.length - 4; i += 4) {
      int alpha = data[i + 3];
      if (alpha > 0 && alpha < 255) {
        data[i + 0] = (data[i + 0] * alpha & 65535) ~/ 255;
        data[i + 1] = (data[i + 1] * alpha & 65535) ~/ 255;
        data[i + 2] = (data[i + 2] * alpha & 65535) ~/ 255;
      }
    }
  } else {
    for(int i = 0; i <= data.length - 4; i += 4) {
      int alpha = data[i + 0];
      if (alpha > 0 && alpha < 255) {
        data[i + 1] = (data[i + 1] * alpha & 65535) ~/ 255;
        data[i + 2] = (data[i + 2] * alpha & 65535) ~/ 255;
        data[i + 3] = (data[i + 3] * alpha & 65535) ~/ 255;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void unpremultiplyAlpha(List<int> data) {

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= data.length - 4; i += 4) {
      int alpha = data[i + 3];
      if (alpha > 0 && alpha < 255) {
        data[i + 0] = (data[i + 0] * 255 & 65535) ~/ alpha;
        data[i + 1] = (data[i + 1] * 255 & 65535) ~/ alpha;
        data[i + 2] = (data[i + 2] * 255 & 65535) ~/ alpha;
      }
    }
  } else {
    for(int i = 0; i <= data.length - 4; i += 4) {
      int alpha = data[i + 0];
      if (alpha > 0 && alpha < 255) {
        data[i + 1] = (data[i + 1] * 255 & 65535) ~/ alpha;
        data[i + 2] = (data[i + 2] * 255 & 65535) ~/ alpha;
        data[i + 3] = (data[i + 3] * 255 & 65535) ~/ alpha;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void clearChannel(List<int> data, int offset, int length) {
  int offsetStart = offset;
  int offsetEnd = offset + length * 4 - 4;
  if (offsetStart < 0) throw new RangeError(offsetStart);
  if (offsetEnd >= data.length) throw new RangeError(offsetEnd);
  for(int i = offsetStart; i <= offsetEnd; i += 4) {
    data[i] = 0;
  }
}

//-----------------------------------------------------------------------------------------------

void setChannel(List<int> data, int offset, int length, int value) {
  int offsetStart = offset;
  int offsetEnd = offset + length * 4 - 4;
  if (offsetStart < 0) throw new RangeError(offsetStart);
  if (offsetEnd >= data.length) throw new RangeError(offsetEnd);
  for(int i = offsetStart; i <= offsetEnd; i += 4) {
    data[i] = value;
  }
}

//-----------------------------------------------------------------------------------------------

void shiftChannel(List<int> data, int channel, int width, int height, int shiftX, int shiftY) {

  if (channel < 0) throw new ArgumentError();
  if (channel > 3) throw new ArgumentError();
  if (shiftX == 0 && shiftY == 0) return;

  if (shiftX.abs() >= width || shiftY.abs() >= height) {
    clearChannel(data, channel, width * height);
    return;
  }

  if (shiftX + width * shiftY < 0) {
    int dst = channel;
    int src = channel - 4 * (shiftX + width * shiftY);
    for(; src < data.length; src += 4, dst += 4) data[dst] = data[src];
  } else {
    int dst = data.length + channel - 4;
    int src = data.length + channel - 4 * (shiftX + width * shiftY);
    for(; src >= 0; src -= 4, dst -= 4) data[dst] = data[src];
  }

  for(int y = 0; y < height; y++) {
    if (y < shiftY || y >= height + shiftY) {
      clearChannel(data, (y * width) * 4 + channel, width);
    } else if (shiftX > 0) {
      clearChannel(data, (y * width) * 4 + channel, shiftX);
    } else if (shiftX < 0) {
      clearChannel(data, (y * width + width + shiftX) * 4 + channel, 0 - shiftX);
    }
  }
}

//-----------------------------------------------------------------------------------------------

void shiftAndInvertChannel(List<int> data, int channel, int width, int height, int shiftX, int shiftY) {

  if (channel < 0) throw new ArgumentError();
  if (channel > 3) throw new ArgumentError();
  if (shiftX == 0 && shiftY == 0)
  {// no shifting, just invert
    for( int src = channel; src < data.length; src += 4) data[src] = 255 - data[src];
    return;
  }

  if (shiftX.abs() >= width || shiftY.abs() >= height) {
    setChannel(data, channel, width * height,255);
    return;
  }

  if (shiftX + width * shiftY < 0) {
    int dst = channel;
    int src = channel - 4 * (shiftX + width * shiftY);
    for(; src < data.length; src += 4, dst += 4) data[dst] = 255 - data[src];
  } else {
    int dst = data.length + channel - 4;
    int src = data.length + channel - 4 * (shiftX + width * shiftY);
    for(; src >= 0; src -= 4, dst -= 4) data[dst] = 255 - data[src];
  }

  for(int y = 0; y < height; y++) {
    if (y < shiftY || y >= height + shiftY) {
      setChannel(data, (y * width) * 4 + channel, width, 255);
    } else if (shiftX > 0) {
      setChannel(data, (y * width) * 4 + channel, shiftX, 255);
    } else if (shiftX < 0) {
      setChannel(data, (y * width + width + shiftX) * 4 + channel, 0 - shiftX, 255);
    }
  }
}

//-----------------------------------------------------------------------------------------------

void shiftAndClampInvertChannel(List<int> data, int channel, int width, int height, int shiftX, int shiftY) {

  if (channel < 0) throw new ArgumentError();
  if (channel > 3) throw new ArgumentError();
  if (shiftX == 0 && shiftY == 0) return;

  if (shiftX.abs() >= width || shiftY.abs() >= height) {
    setChannel(data, channel, width * height,255);
    return;
  }

  if (shiftX + width * shiftY < 0) {
    int dst = channel;
    int src = channel - 4 * (shiftX + width * shiftY);
    for(; src < data.length; src += 4, dst += 4) data[dst] = data[src] > 0 ? 0 : 255;//255 - data[src];
  } else {
    int dst = data.length + channel - 4;
    int src = data.length + channel - 4 * (shiftX + width * shiftY);
    for(; src >= 0; src -= 4, dst -= 4) data[dst] = data[src] > 0 ? 0 : 255;//255 - data[src];
  }

  for(int y = 0; y < height; y++) {
    if (y < shiftY || y >= height + shiftY) {
      setChannel(data, (y * width) * 4 + channel, width, 255);
    } else if (shiftX > 0) {
      setChannel(data, (y * width) * 4 + channel, shiftX, 255);
    } else if (shiftX < 0) {
      setChannel(data, (y * width + width + shiftX) * 4 + channel, 0 - shiftX, 255);
    }
  }
}

//-----------------------------------------------------------------------------------------------

void blur(List<int> data, int offset, int length, int stride, int radius) {

  radius += 1;
  int weight = radius * radius;
  int weightInv = (1 << 22) ~/ weight;
  int sum = 0;//weight ~/ 2;
  int dif = 0;
  int offsetSource = offset;
  int offsetDestination = offset;
  int lastOffsetSource = offsetSource + ((length-1) * stride);
  int radius1 = radius * 1;

  Int32List buffer = _buffer;

  for ( int p = 0; p < radius1; ++p )
  {
    int value = data[offsetSource];
    buffer[p & BUFFER_SIZE_BITMASK] = data[offsetSource];
    sum += dif += value;
  }

  for (int i = 0; i < length + radius1; i++) {

    if (i >= radius1) {
      data[offsetDestination] = ((sum * weightInv) | 0) >> 22;
      offsetDestination += stride;
      dif -= 2 * buffer[i & BUFFER_SIZE_BITMASK] - buffer[(i - radius1) & BUFFER_SIZE_BITMASK];
    }
    else
    {
      dif -= 2 * buffer[i & BUFFER_SIZE_BITMASK];
    }

    if (i < length) {
      int value = data[offsetSource];
      offsetSource += stride;
      buffer[(i + radius1) & BUFFER_SIZE_BITMASK] = value;
      sum += dif += value;
    } else {
      int value = data[lastOffsetSource];
      buffer[(i + radius1) & BUFFER_SIZE_BITMASK] = value;
      sum += dif += value;
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColor(List<int> data, int color) {

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);

  if (env.isLittleEndianSystem) {
    for(var i = 0; i <= data.length - 4; i += 4) {
      data[i + 0] = rColor;
      data[i + 1] = gColor;
      data[i + 2] = bColor;
      data[i + 3] = (aColor * data[i + 3] | 0) >> 8;
    }
  } else {
    for(var i = 0; i <= data.length - 4; i += 4) {
      data[i + 0] = (aColor * data[i + 0] | 0) >> 8;
      data[i + 1] = bColor;
      data[i + 2] = gColor;
      data[i + 3] = rColor;
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorStrength(List<int> data, int color, int strength) {

  if ( strength < 2 )
  {
    setColor(data, color);
    return;
  }

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);
  int invAlpha;
  --strength;
  int startingStrength = strength;

  if (env.isLittleEndianSystem) {
    for(var i = 0; i <= data.length - 4; i += 4) {
      strength = startingStrength;
      data[i + 0] = rColor;
      data[i + 1] = gColor;
      data[i + 2] = bColor;
      invAlpha = 65536 - (aColor * data[i + 3] | 0);
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      data[i + 3] = (65536 - invAlpha) >> 8;
    }
  } else {
    for(var i = 0; i <= data.length - 4; i += 4) {
      strength = startingStrength;
      invAlpha = 65536 - (aColor * data[i + 0] | 0);
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      data[i + 0] = (65536 - invAlpha) >> 8;
      data[i + 1] = bColor;
      data[i + 2] = gColor;
      data[i + 3] = rColor;
    }
  }
}

//-----------------------------------------------------------------------------------------------

void blend(List<int> dstData, List<int> srcData) {

  if (dstData.length != srcData.length) return;

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 3];
      int dstA = dstData[i + 3];
      int srcAX = srcA * 255;
      int dstAX = dstA * (255 - srcA);
      int outAX = srcAX + dstAX;
      if (outAX > 0) {
        dstData[i + 0] = (srcData[i + 0] * srcAX + dstData[i + 0] * dstAX) ~/ outAX;
        dstData[i + 1] = (srcData[i + 1] * srcAX + dstData[i + 1] * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + dstData[i + 2] * dstAX) ~/ outAX;
        dstData[i + 3] = outAX ~/ 255;
      }
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 0];
      int dstA = dstData[i + 0];
      int srcAX = srcA * 255;
      int dstAX = dstA * (255 - srcA);
      int outAX = srcAX + dstAX;
      if (outAX > 0) {
        dstData[i + 0] = outAX ~/ 255;
        dstData[i + 1] = (srcData[i + 1] * srcAX + dstData[i + 1] * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + dstData[i + 2] * dstAX) ~/ outAX;
        dstData[i + 3] = (srcData[i + 3] * srcAX + dstData[i + 3] * dstAX) ~/ outAX;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void knockout(List<int> dstData, List<int> srcData) {

  if (dstData.length != srcData.length) return;

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      dstData[i + 3] = dstData[i + 3] * (255 - srcData[i + 3]) ~/ 255;
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      dstData[i + 0] = dstData[i + 0] * (255 - srcData[i + 0]) ~/ 255;
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorBlend(List<int> dstData, int color, List<int> srcData) {

  // optimized version for:
  //   _setColor(data, this.color, this.alpha);
  //   _blend(data, sourceImageData.data);

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 3];
      int dstA = dstData[i + 3];
      int srcAX = (srcA * 255);
      int dstAX = (dstA * (255 - srcA) * aColor | 0) >> 8;
      int outAX = (srcAX + dstAX);
      if (outAX > 0) {
        dstData[i + 0] = (srcData[i + 0] * srcAX + rColor * dstAX) ~/ outAX;
        dstData[i + 1] = (srcData[i + 1] * srcAX + gColor * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + bColor * dstAX) ~/ outAX;
        dstData[i + 3] = outAX ~/ 255;
      } else {
        dstData[i + 3] = 0;
      }
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 0];
      int dstA = dstData[i + 0];
      int srcAX = (srcA * 255);
      int dstAX = (dstA * (255 - srcA) * aColor | 0) >> 8;
      int outAX = (srcAX + dstAX);
      if (outAX > 0) {
        dstData[i + 0] = outAX ~/ 255;
        dstData[i + 1] = (srcData[i + 1] * srcAX + bColor * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + gColor * dstAX) ~/ outAX;
        dstData[i + 3] = (srcData[i + 3] * srcAX + rColor * dstAX) ~/ outAX;
      } else {
        dstData[i + 0] = 0;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorBlendStrength(List<int> dstData, int color, List<int> srcData, int strength) {

  if ( strength < 2 )
  {
    setColorBlend(dstData, color, srcData);
    return;
  }
  // optimized version for:
  //   _setColor(data, this.color, this.alpha);
  //   _blend(data, sourceImageData.data);

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);
  int invAlpha;
  --strength;
  int startingStrength = strength;

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      int srcA = srcData[i + 3];
      int dstA = dstData[i + 3];
      int srcAX = (srcA * 255);
      int dstAX = (dstA * (255 - srcA) * aColor | 0) >> 8;
      int outAX = (srcAX + dstAX);
      if (outAX > 0) {
        dstData[i + 0] = (srcData[i + 0] * srcAX + rColor * dstAX) ~/ outAX;
        dstData[i + 1] = (srcData[i + 1] * srcAX + gColor * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + bColor * dstAX) ~/ outAX;
        invAlpha = 65536 - outAX;
        while( strength > 0 )
        {
          --strength;
          invAlpha = (invAlpha * invAlpha | 0) >> 16;
        }
        dstData[i + 3] = (65536 - invAlpha) >> 8;
      } else {
        dstData[i + 3] = 0;
      }
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      int srcA = srcData[i + 0];
      int dstA = dstData[i + 0];
      int srcAX = (srcA * 255);
      int dstAX = (dstA * (255 - srcA) * aColor | 0) >> 8;
      int outAX = (srcAX + dstAX);
      if (outAX > 0) {
        invAlpha = 65536 - outAX;
        while( strength > 0 )
        {
          --strength;
          invAlpha = (invAlpha * invAlpha | 0) >> 16;
        }
        dstData[i + 0] = (65536 - invAlpha) >> 8;
        dstData[i + 1] = (srcData[i + 1] * srcAX + bColor * dstAX) ~/ outAX;
        dstData[i + 2] = (srcData[i + 2] * srcAX + gColor * dstAX) ~/ outAX;
        dstData[i + 3] = (srcData[i + 3] * srcAX + rColor * dstAX) ~/ outAX;
      } else {
        dstData[i + 0] = 0;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorBlendDst(List<int> dstData, int color, List<int> srcData) {

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 3];
      int dstA = dstData[i + 3];
      int dstAX = (dstA * aColor | 0) >> 8;
      int srcAX = (255 - dstAX);
      if (srcA > 0) {
        dstData[i + 0] = (srcData[i + 0] * srcAX + rColor * dstAX) ~/ 255;
        dstData[i + 1] = (srcData[i + 1] * srcAX + gColor * dstAX) ~/ 255;
        dstData[i + 2] = (srcData[i + 2] * srcAX + bColor * dstAX) ~/ 255;
        dstData[i + 3] = srcA;
      } else {
        dstData[i + 3] = 0;
      }
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      int srcA = srcData[i + 0];
      int dstA = dstData[i + 0];
      int dstAX = (dstA * aColor | 0) >> 8;
      int srcAX = (255 - dstAX);
      if (srcA > 0) {
        dstData[i + 0] = srcA;
        dstData[i + 1] = (srcData[i + 1] * srcAX + bColor * dstAX) ~/ 255;
        dstData[i + 2] = (srcData[i + 2] * srcAX + gColor * dstAX) ~/ 255;
        dstData[i + 3] = (srcData[i + 3] * srcAX + rColor * dstAX) ~/ 255;
      } else {
        dstData[i + 0] = 0;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorBlendDstStrength(List<int> dstData, int color, List<int> srcData, int strength) {

  if ( strength < 2 )
  {
    setColorBlendDst(dstData, color, srcData);
    return;
  }

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);
  int invAlpha;
  --strength;
  int startingStrength = strength;

  if (env.isLittleEndianSystem) {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      int srcA = srcData[i + 3];
      int dstA = dstData[i + 3];
      invAlpha = 65536 - (dstA * aColor | 0);
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      int dstAX = (65536 - invAlpha) >> 8;
      int srcAX = (255 - dstAX);
      if (srcA > 0) {
        dstData[i + 0] = (srcData[i + 0] * srcAX + rColor * dstAX) ~/ 255;
        dstData[i + 1] = (srcData[i + 1] * srcAX + gColor * dstAX) ~/ 255;
        dstData[i + 2] = (srcData[i + 2] * srcAX + bColor * dstAX) ~/ 255;
        dstData[i + 3] = srcA;
      } else {
        dstData[i + 3] = 0;
      }
    }
  } else {
    for(int i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      int srcA = srcData[i + 0];
      int dstA = dstData[i + 0];
      invAlpha = 65536 - (dstA * aColor | 0);
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      int dstAX = (65536 - invAlpha) >> 8;
      int srcAX = (255 - dstAX);
      if (srcA > 0) {
        dstData[i + 0] = srcA;
        dstData[i + 1] = (srcData[i + 1] * srcAX + bColor * dstAX) ~/ 255;
        dstData[i + 2] = (srcData[i + 2] * srcAX + gColor * dstAX) ~/ 255;
        dstData[i + 3] = (srcData[i + 3] * srcAX + rColor * dstAX) ~/ 255;
      } else {
        dstData[i + 0] = 0;
      }
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorKnockout(List<int> dstData, int color, List<int> srcData) {

  // optimized version for:
  //   _setColor(data, this.color, this.alpha);
  //   _knockout(data, sourceImageData.data);

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);

  if (env.isLittleEndianSystem) {
    for(var i = 0; i <= dstData.length - 4; i += 4) {
      dstData[i + 0] = rColor;
      dstData[i + 1] = gColor;
      dstData[i + 2] = bColor;
      dstData[i + 3] = (aColor * dstData[i + 3] * (255 - srcData[i + 3]) | 0) ~/ (255 * 256);
    }
  } else {
    for(var i = 0; i <= dstData.length - 4; i += 4) {
      dstData[i + 0] = (aColor * dstData[i + 0] * (255 - srcData[i + 0]) | 0) ~/ (255 * 256);
      dstData[i + 1] = bColor;
      dstData[i + 2] = gColor;
      dstData[i + 3] = rColor;
    }
  }
}

//-----------------------------------------------------------------------------------------------

void setColorKnockoutStrength(List<int> dstData, int color, List<int> srcData, int strength) {

  if ( strength < 2 )
  {
    setColorKnockout(dstData, color, srcData);
    return;
  }
  // optimized version for:
  //   _setColor(data, this.color, this.alpha);
  //   _knockout(data, sourceImageData.data);

  if (dstData.length != srcData.length) return;

  int rColor = colorGetR(color);
  int gColor = colorGetG(color);
  int bColor = colorGetB(color);
  int aColor = colorGetA(color);
  int invAlpha;
  --strength;
  int startingStrength = strength;

  if (env.isLittleEndianSystem) {
    for(var i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      dstData[i + 0] = rColor;
      dstData[i + 1] = gColor;
      dstData[i + 2] = bColor;
      invAlpha = 65536 - ((aColor * dstData[i + 3] * (255 - srcData[i + 3]) | 0) >> 8 );
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      dstData[i + 3] = (65536 - invAlpha) >> 8;
    }
  } else {
    for(var i = 0; i <= dstData.length - 4; i += 4) {
      strength = startingStrength;
      invAlpha = 65536 - ((aColor * dstData[i + 0] * (255 - srcData[i + 0]) | 0) >> 8 );
      while( strength > 0 )
      {
        --strength;
        invAlpha = (invAlpha * invAlpha | 0) >> 16;
      }
      dstData[i + 0] = (65536 - invAlpha) >> 8;
      dstData[i + 1] = bColor;
      dstData[i + 2] = gColor;
      dstData[i + 3] = rColor;
    }
  }
}

//-----------------------------------------------------------------------------------------------

