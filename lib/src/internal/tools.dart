library stagexl.internal.tools;

int colorGetA(int color) => (color >> 24) & 0xFF;
int colorGetR(int color) => (color >> 16) & 0xFF;
int colorGetG(int color) => (color >>  8) & 0xFF;
int colorGetB(int color) => (color      ) & 0xFF;

String color2rgb(int color) {
  int r = colorGetR(color);
  int g = colorGetG(color);
  int b = colorGetB(color);
  return "rgb($r,$g,$b)";
}

String color2rgba(int color) {
  int r = colorGetR(color);
  int g = colorGetG(color);
  int b = colorGetB(color);
  num a = colorGetA(color) / 255.0;
  return "rgba($r,$g,$b,$a)";
}

//-----------------------------------------------------------------------------

int minInt(int a, int b) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

int maxInt(int a, int b) {
  if (a >= b) {
    return a;
  } else {
    return b;
  }
}

num minNum(num a, num b) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

num maxNum(num a, num b) {
  if (a >= b) {
    return a;
  } else {
    return b;
  }
}

int clampInt(int value, int lower, int upper) {
  if (value <= lower) {
    return lower;
  } else if (value >= upper) {
    return upper;
  } else {
    return value;
  }
}

//-----------------------------------------------------------------------------

bool ensureBool(bool value) {
  if (value is bool) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not a bool.");
  }
}

int ensureInt(int value) {
  if (value is int) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not an int.");
  }
}

num ensureNum(Object value) {
  if (value is num) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not a number.");
  }
}

String ensureString(Object value) {
  if (value is String) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not a string.");
  }
}

//-----------------------------------------------------------------------------

int nextPowerOfTwo( num size )
{
  int start = size.ceil();
  if (start < 0) return 0;

  --start;
  start = start | (start >> 1);
  start = start | (start >> 2);
  start = start | (start >> 4);
  start = start | (start >> 8);
  start = start | (start >> 16);
  return start+1;
}

//-----------------------------------------------------------------------------

bool similar(num a, num b, [num epsilon = 0.0001]) {
  return (a - epsilon < b) && (a + epsilon > b);
}

//-----------------------------------------------------------------------------

String getFilenameWithoutExtension(String filename) {
  RegExp regex = new RegExp(r"(.+?)(\.[^.]*$|$)");
  Match match = regex.firstMatch(filename);
  return match.group(1);
}

//-----------------------------------------------------------------------------

String replaceFilename(String url, String filename) {
  RegExp regex = new RegExp(r"^(.*/)?(?:$|(.+?)(?:(\.[^.]*$)|$))");
  Match match = regex.firstMatch(url);
  String path = match.group(1);
  return (path == null) ? filename : "$path$filename";
}
