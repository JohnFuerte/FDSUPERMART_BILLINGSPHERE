import 'dart:convert';

class ItemsGroup {
  String id;
  String desc;
  String name;
  DateTime createdAt;
  DateTime updatedOn;
  String images;

  ItemsGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedOn,
    required this.desc,
    required this.images,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedOn': updatedOn.millisecondsSinceEpoch,
      'desc': desc,
      'images': images,
    };
  }

  factory ItemsGroup.fromMap(Map<String, dynamic> map) {
    return ItemsGroup(
      id: map['_id'] as String,
      name: map['name'] as String,
      desc: map['desc'] as String,
      createdAt: DateTime.parse(map['createdAt'].toString()),
      updatedOn: DateTime.parse(map['updatedOn'].toString()),
      images: map['images'] as String,
    );
  }
  String toJson() => json.encode(toMap());

  factory ItemsGroup.fromJson(String source) =>
      ItemsGroup.fromMap(json.decode(source) as Map<String, dynamic>);
}
