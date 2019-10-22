import 'package:geoflutterfire/geoflutterfire.dart';

class CardModel {
  int id;
  String imageUrl;
  String title;
  String description;
  int rarity;
  List<String> collections;
  GeoFirePoint location;

  CardModel(this.id, this.imageUrl, this.title, this.rarity, this.collections, this.location);

  CardModel.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    imageUrl = parsedJson['thumbnailUrl'];
    title = parsedJson['title'].substring(0, 6).trim();
    description = parsedJson['description'];
    rarity = parsedJson['rarity'];
    collections = parsedJson['collections'] as List<String>;
    location = parsedJson['location'] as GeoFirePoint;
  }

  // for parsing Cards from a Users or Packs document, where not all data is included
  CardModel.fromPeripheralDocument(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    imageUrl = parsedJson['imageUrl'];
    title = parsedJson['title'];
    rarity = parsedJson['rarity'];
  }

  Map<String, dynamic> toMapPartial() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'rarity': rarity
    };
  }
  
  @override
  String toString() {
    return '$title';
  }
}
