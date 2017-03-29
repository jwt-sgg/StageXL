part of stagexl.resources;

class ResourceManager {

  final Map<String, ResourceManagerResource> _resourceMap =
      new Map<String, ResourceManagerResource>();

  final _progressEvent = new StreamController<num>.broadcast();
  Stream<num> get onProgress => _progressEvent.stream;

  bool _ignoreErrors;
  ResourceManager([this._ignoreErrors = false]);

  //----------------------------------------------------------------------------

  Future<ResourceManager> load() async {
    var futures = this.pendingResources.map((r) => r.complete);
    await Future.wait(futures);
    var errors = this.failedResources.length;
    if (errors > 0 && !_ignoreErrors) {
      throw new StateError("Failed to load $errors resource(s).");
    } else {
      return this;
    }
  }

  void dispose() {
    for (var resource in _resourceMap.values.toList(growable: false)) {
      if (resource.kind == "BitmapData") {
        this.removeBitmapData(resource.name, dispose: true);
      } else if (resource.kind == "TextureAtlas") {
        this.removeTextureAtlas(resource.name, dispose: true);
      } else {
        _removeResource(resource.kind, resource.name);
      }
    }
  }

  //----------------------------------------------------------------------------

  List<ResourceManagerResource> get finishedResources =>
    _resourceMap.values.where((r) => r.value != null).toList();

  List<ResourceManagerResource> get pendingResources =>
    _resourceMap.values.where((r) => r.value == null && r.error == null).toList();

  List<ResourceManagerResource> get failedResources =>
    _resourceMap.values.where((r) => r.error != null).toList();

  List<ResourceManagerResource> get resources =>
    _resourceMap.values.toList();

  //----------------------------------------------------------------------------

  bool containsBitmapData(String name) {
    return _containsResource("BitmapData", name);
  }

  bool bitmapDataLoaded(String name) {
    return _resourceLoaded("BitmapData", name);
  }

  bool bitmapDataHasError(String name) {
    return _resourceHasError("BitmapData", name);
  }

  Future bitmapDataComplete(String name) {
    return _resourceComplete("BitmapData", name);
  }

  void addBitmapData(String name, String url, [BitmapDataLoadOptions options]) {
    var loader = BitmapData.load(url, options);
    _addResource("BitmapData", name, url, loader);
  }

  void removeBitmapData(String name, {bool dispose:true}) {
    var resourceManagerResource = _removeResource("BitmapData", name);
    var bitmapData = resourceManagerResource?.value;
    if (bitmapData is BitmapData && dispose) {
      bitmapData.renderTexture.dispose();
    }
  }

  BitmapData getBitmapData(String name) {
    var value = _getResourceValue("BitmapData", name);
    if (value is! BitmapData) throw "dart2js_hint";
    return value;
  }

  //----------------------------------------------------------------------------

  bool containsTextureAtlas(String name) {
    return _containsResource("TextureAtlas", name);
  }

  bool textureAtlasLoaded(String name) {
    return _resourceLoaded("TextureAtlas", name);
  }

  bool textureAtlasHasError(String name) {
    return _resourceHasError("TextureAtlas", name);
  }

  Future textureAtlasComplete(String name) {
    return _resourceComplete("TextureAtlas", name);
  }

  void addTextureAtlas(String name, String url, [
      TextureAtlasFormat textureAtlasFormat = TextureAtlasFormat.JSONARRAY,
      BitmapDataLoadOptions options = null]) {

    var loader = TextureAtlas.load(url, textureAtlasFormat, options);
    _addResource("TextureAtlas", name, url, loader);
  }

  void removeTextureAtlas(String name, {bool dispose:true}) {
    var resourceManagerResource = _removeResource("TextureAtlas", name);
    var textureAtlas = resourceManagerResource?.value;
    if (textureAtlas is TextureAtlas && dispose) {
      for (var textureAtlasFrame in textureAtlas.frames) {
        textureAtlasFrame.bitmapData.renderTexture.dispose();
      }
    }
  }

  TextureAtlas getTextureAtlas(String name) {
    return _getResourceValue("TextureAtlas", name) as TextureAtlas;
  }

  //----------------------------------------------------------------------------

  bool containsVideo(String name) {
    return _containsResource("Video", name);
  }

  bool videoLoaded(String name) {
    return _resourceLoaded("Video", name);
  }

  bool videoHasError(String name) {
    return _resourceHasError("Video", name);
  }

  Future videoComplete(String name) {
    return _resourceComplete("Video", name);
  }

  void addVideo(String name, String url, [VideoLoadOptions options]) {
    var loader = Video.load(url, options);
    _addResource("Video", name, url, loader);
  }

  void removeVideo(String name) {
    _removeResource("Video", name);
  }

  Video getVideo(String name) {
    return _getResourceValue("Video", name) as Video;
  }

  //----------------------------------------------------------------------------

  bool containsSound(String name) {
    return _containsResource("Sound", name);
  }

  bool soundLoaded(String name) {
    return _resourceLoaded("Sound", name);
  }

  bool soundHasError(String name) {
    return _resourceHasError("Sound", name);
  }

  Future soundComplete(String name) {
    return _resourceComplete("Sound", name);
  }

  void addSound(String name, String url, [SoundLoadOptions options]) {
    var loader = Sound.load(url, options);
    _addResource("Sound", name, url, loader);
  }

  void removeSound(String name) {
    _removeResource("Sound", name);
  }

  Sound getSound(String name) {
    return _getResourceValue("Sound", name) as Sound;
  }

  //----------------------------------------------------------------------------

  bool containsSoundSprite(String name) {
    return _containsResource("SoundSprite", name);
  }

  bool soundSpriteLoaded(String name) {
    return _resourceLoaded("SoundSprite", name);
  }

  bool soundSpriteHasError(String name) {
    return _resourceHasError("SoundSprite", name);
  }

  Future soundSpriteComplete(String name) {
    return _resourceComplete("SoundSprite", name);
  }

  void addSoundSprite(String name, String url, [SoundLoadOptions options]) {
    var loader = SoundSprite.load(url, options);
    _addResource("SoundSprite", name, url, loader);
  }

  void removeSoundSprite(String name) {
    _removeResource("SoundSprite", name);
  }

  SoundSprite getSoundSprite(String name) {
    return _getResourceValue("SoundSprite", name) as SoundSprite;
  }

  //----------------------------------------------------------------------------

  bool containsText(String name) {
    return _containsResource("Text", name);
  }

  bool textLoaded(String name) {
    return _resourceLoaded("Text", name);
  }

  bool textHasError(String name) {
    return _resourceHasError("Text", name);
  }

  Future textComplete(String name) {
    return _resourceComplete("Text", name);
  }

  void addText(String name, String text) {
    _addResource("Text", name, "", new Future.value(text));
  }

  void removeText(String name) {
    _removeResource("Text", name);
  }

  String getText(String name) {
    return _getResourceValue("Text", name) as String;
  }

  //----------------------------------------------------------------------------

  bool containsTextFile(String name) {
    return _containsResource("TextFile", name);
  }

  bool textFileLoaded(String name) {
    return _resourceLoaded("TextFile", name);
  }

  bool textFileHasError(String name) {
    return _resourceHasError("TextFile", name);
  }

  Future textFileComplete(String name) {
    return _resourceComplete("TextFile", name);
  }

  void addTextFile(String name, String url) {
    var loader = HttpRequest.getString(url).then((text) => text, onError: (error) {
      throw new StateError("Failed to load text file.");
    });
    _addResource("TextFile", name, url, loader);
  }

  void removeTextFile(String name) {
    _removeResource("TextFile", name);
  }

  String getTextFile(String name) {
    return _getResourceValue("TextFile", name) as String;
  }

  //----------------------------------------------------------------------------

  bool containsCustomObject(String name) {
    return _containsResource("CustomObject", name);
  }

  bool customObjectLoaded(String name) {
    return _resourceLoaded("CustomObject", name);
  }

  bool customObjectHasError(String name) {
    return _resourceHasError("CustomObject", name);
  }

  Future customObjectComplete(String name) {
    return _resourceComplete("CustomObject", name);
  }

  void addCustomObject(String name, Future loader) {
    _addResource("CustomObject", name, "", loader);
  }

  void removeCustomObject(String name) {
    _removeResource("CustomObject", name);
  }

  dynamic getCustomObject(String name) {
    return _getResourceValue("CustomObject", name);
  }

  //----------------------------------------------------------------------------

  bool _containsResource(String kind, String name) {
    var key = "$kind.$name";
    return _resourceMap.containsKey(key);
  }

  bool _resourceLoaded(String kind, String name) {
    var key = "$kind.$name";
    var resource = _resourceMap[key];
    if (resource == null) {
      if (_ignoreErrors){
        return false;
      }
      throw new StateError("Resource '$name' does not exist.");
    } else {
      return (resource.value != null);
    }
  }

  bool _resourceHasError(String kind, String name) {
    var key = "$kind.$name";
    var resource = _resourceMap[key];
    if (resource == null) {
      if (_ignoreErrors){
        return false;
      }
      throw new StateError("Resource '$name' does not exist.");
    } else {
      return (resource.error != null);
    }
  }

  Future _resourceComplete(String kind, String name) {
    var key = "$kind.$name";
    var resource = _resourceMap[key];
    if (resource == null) {
      if (_ignoreErrors){
        return null;
      }
      throw new StateError("Resource '$name' does not exist.");
    } else {
      return resource.complete;
    }
  }


  ResourceManagerResource _removeResource(String kind, String name) {
    var key = "$kind.$name";
    return _resourceMap.remove(key);
  }

  void _addResource(String kind, String name, String url, Future loader) {
    var key = "$kind.$name";

    if (_resourceMap.containsKey(key)) {
      if (!_ignoreErrors){
        throw new StateError("ResourceManager already contains a resource called '$name'");
      }
    } else {
      var resource = new ResourceManagerResource(kind, name, url, loader);
      _resourceMap[key] = resource;
      resource.complete.then((_) {
        var finished = this.finishedResources.length;
        var progress = finished / _resourceMap.length;
        _progressEvent.add(progress);
      });
    }
  }

  dynamic _getResourceValue(String kind, String name) {
    var key = "$kind.$name";
    var resource = _resourceMap[key];
    if (resource == null) {
      if (_ignoreErrors){
        return null;
      }
      throw new StateError("Resource '$name' does not exist.");
    } else if (resource.value != null) {
      return resource.value;
    } else if (resource.error != null) {
      if (_ignoreErrors){
        return null;
      }
      throw resource.error;
    } else {
      if (_ignoreErrors){
        return null;
      }
      throw new StateError("Resource '$name' has not finished loading yet.");
    }
  }
}
