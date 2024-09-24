import 'dart:convert';

class Item {
  String id;
  String? companyCode;
  String itemGroup;
  String itemBrand;
  String itemName;
  String printName;
  String codeNo;
  String barcode;
  String taxCategory;
  String hsnCode;
  String storeLocation;
  String measurementUnit;
  String secondaryUnit;
  int minimumStock;
  int maximumStock;
  int monthlySalesQty;
  String date;
  double dealer;
  double subDealer;
  double retail;
  double mrp;
  double discountAmount;
  String openingStock;
  String status;
  List<String>? images; // Changed to List<String> to support multiple images
  final double? price;
  ProductMetadata? productMetadata;
  double openingBalanceQty;
  double openingBalanceAmt;

  Item({
    required this.id,
    required this.itemGroup,
    required this.itemBrand,
    required this.itemName,
    required this.printName,
    required this.codeNo,
    required this.barcode,
    required this.taxCategory,
    required this.hsnCode,
    required this.storeLocation,
    required this.measurementUnit,
    required this.secondaryUnit,
    required this.minimumStock,
    required this.maximumStock,
    required this.monthlySalesQty,
    required this.date,
    required this.dealer,
    required this.subDealer,
    required this.retail,
    required this.mrp,
    required this.openingStock,
    required this.status,
    required this.discountAmount,
    this.images, // Optional field for multiple image URLs
    this.companyCode,
    this.productMetadata,
    required this.price,
    this.openingBalanceQty = 0.0,
    this.openingBalanceAmt = 0.0,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      // 'id': id,
      'itemGroup': itemGroup,
      'companyCode': companyCode ?? '',
      'itemBrand': itemBrand,
      'itemName': itemName,
      'printName': printName,
      'codeNo': codeNo,
      'barcode': barcode,
      'taxCategory': taxCategory,
      'hsnCode': hsnCode,
      'storeLocation': storeLocation,
      'measurementUnit': measurementUnit,
      'secondaryUnit': secondaryUnit,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'monthlySalesQty': monthlySalesQty,
      'dealer': dealer,
      'subDealer': subDealer,
      'retail': retail,
      'mrp': mrp,
      'openingStock': openingStock,
      'discountAmount': discountAmount,
      'status': status,
      'images': images,
      'productMetadata': productMetadata?.toMap(),
      'price': price,
      'openingBalanceQty': openingBalanceQty,
      'openingBalanceAmt': openingBalanceAmt,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['_id'] as String,
      itemGroup: map['itemGroup'] as String,
      itemBrand: map['itemBrand'] as String,
      companyCode: map['companyCode'] as String?,
      itemName: map['itemName'] as String,
      printName: map['printName'] as String,
      barcode: map['barcode'] as String,
      codeNo: map['codeNo'] as String,
      taxCategory: map['taxCategory'] as String,
      price: map['price'] as double,
      hsnCode: map['hsnCode'] as String,
      storeLocation: map['storeLocation'] as String,
      measurementUnit: map['measurementUnit'] as String,
      secondaryUnit: map['secondaryUnit'] as String,
      minimumStock: map['minimumStock'] as int,
      maximumStock: map['maximumStock'] as int,
      monthlySalesQty: map['monthlySalesQty'] as int,
      date: map['date'] as String,
      dealer: map['dealer'] as double,
      discountAmount: map['discountAmount'] as double,
      subDealer: map['subDealer'] as double,
      retail: map['retail'] as double,
      mrp: map['mrp'] as double,
      openingStock: map['openingStock'] as String,
      status: map['status'] as String,
      openingBalanceQty: map['openingBalanceQty'] as double,
      openingBalanceAmt: map['openingBalanceAmt'] as double,
      productMetadata: map['productMetadata'] != null
          ? ProductMetadata.fromMap(map['productMetadata'])
          : null, // Handle product metadata
      images: List<String>.from(map['images'] ?? []), // Handle multiple images
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) =>
      Item.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ImageData {
  final String data;
  final String contentType;
  final String filename;

  ImageData({
    required this.data,
    required this.contentType,
    required this.filename,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      data: json['data'],
      contentType: json['contentType'],
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'contentType': contentType,
      'filename': filename,
    };
  }
}

class ProductMetadata {
  final String overview;
  final List<String> features;
  final List<String> ingredients;
  final List<String> benefits;

  ProductMetadata({
    required this.overview,
    required this.features,
    required this.ingredients,
    required this.benefits,
  });

  Map<String, dynamic> toMap() {
    return {
      'overview': overview,
      'features': features,
      'ingredients': ingredients,
      'benefits': benefits,
    };
  }

  factory ProductMetadata.fromMap(Map<String, dynamic> map) {
    return ProductMetadata(
      overview: map['overview'] as String,
      features: List<String>.from(map['features'] ?? []),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
    );
  }
}
