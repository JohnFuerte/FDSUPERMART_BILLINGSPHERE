// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:billingsphere/data/models/item/item_model.dart';
import 'package:billingsphere/utils/constant.dart';
import 'package:billingsphere/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../views/NI_responsive.dart/NI_home.dart';
import '../../views/SE_responsive/SE_master.dart';
import '../models/user/user_group_model.dart';
import 'user_group_repository.dart';

class ItemsService {
  // Method to retrieve token from SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<List<String>?> getCompanyCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('companies');
  }

  Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('usergroup');
  }

  late int totalPages;

  Future<void> createItem({
    required String itemGroup,
    required String itemBrand,
    required String itemName,
    required String printName,
    required String codeNo,
    required String taxCategory,
    required String hsnCode,
    required String storeLocation,
    required String measurementUnit,
    required String secondaryUnit,
    required int minimumStock,
    required int maximumStock,
    required int monthlySalesQty,
    required String date,
    required double dealer,
    required double subDealer,
    required double retail,
    required double mrp,
    required String openingStock,
    required String barcode,
    required String status,
    required List<String> images,
    required ProductMetadata productMetadata,
    required String companyCode,
    required BuildContext context,
    required double discountAmount,
  }) async {
    try {
      final String? userType = await getUserType();

      UserGroupServices userGroupServices = UserGroupServices();

      final List<UserGroup> usersGroups =
          await userGroupServices.getUserGroups();

      bool canCreateMaster = usersGroups.any((userGroup) =>
          userGroup.userGroupName == userType && userGroup.sales == "Yes");

      if (!canCreateMaster) {
        showSnackBar(
            context, "You do not have permission to create Ledger data.");
        return;
      } else {
        final Uri uri = Uri.parse('${Constants.baseUrl}/items/create-item');

        Item item = Item(
          id: '',
          companyCode: companyCode,
          itemGroup: itemGroup,
          itemBrand: itemBrand,
          itemName: itemName,
          printName: printName,
          codeNo: codeNo,
          taxCategory: taxCategory,
          hsnCode: hsnCode,
          storeLocation: storeLocation,
          measurementUnit: measurementUnit,
          secondaryUnit: secondaryUnit,
          minimumStock: minimumStock,
          maximumStock: maximumStock,
          monthlySalesQty: monthlySalesQty,
          status: status,
          openingStock: openingStock,
          dealer: dealer,
          subDealer: subDealer,
          retail: retail,
          mrp: mrp,
          date: date,
          images: images,
          price: 0.0,
          barcode: barcode,
          productMetadata: productMetadata,
          discountAmount: discountAmount,
        );

        // Get the token from SharedPreferences
        String? token = await getToken();

        final http.Response response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': '$token',
          },
          body: item.toJson(),
        );
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        httpErrorHandle(
            response: response,
            context: context,
            onSuccess: () {
              Fluttertoast.showToast(
                msg: 'Item created successfully',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER_LEFT,
                backgroundColor: Colors.purple,
                textColor: Colors.white,
              );

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ItemHome(),
                ),
              );
            });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<List<Item>> fetchITEMS() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/items/get-items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
    );
    final responseData = json.decode(response.body);

    if (responseData['success'] == true) {
      final itemEntriesData = responseData['data'];

      final List<Item> itemEntry =
          List.from(itemEntriesData.map((entry) => Item.fromMap(entry)));

      return itemEntry;
    } else {
      throw Exception('${responseData['message']}');
    }
  }

  Future<List<Item>> fetchItems() async {
    try {
      final String? token = await getToken();
      final List<String>? code = await getCompanyCode();

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/items/get-items/${code![0]}'),
        headers: {
          'Authorization': '$token',
        },
      );

      final responseData = json.decode(response.body);

      print('Response Data: $responseData'); // Debugging: check the structure

      if (responseData['success'] == true) {
        final itemData = responseData['data'];
        final List<Item> items = List.from(itemData.map((entry) {
          // Check if 'images' is a string and convert it to a list
          if (entry['images'] is String) {
            entry['images'] = [
              entry['images']
            ]; // Convert string to list of one element
          } else if (entry['images'] == null) {
            entry['images'] = []; // Handle null case
          }
          return Item.fromMap(entry);
        }));

        // Ensure itemData is a List
        if (itemData is List) {
          totalPages = responseData['totalPages'];

          final List<Item> items = List.from(itemData.map((entry) {
            return Item.fromMap(entry);
          }));
          return items;
        } else {
          print('Expected a list of items but got: $itemData');
          return [];
        }
      } else {
        print('${responseData['message']}');
        return [];
      }
    } catch (error) {
      print('Error: ${error.toString()}');
      return [];
    }
  }

  Future<List<Item>> fetchItemsWithPagination(int page,
      {int limit = 25}) async {
    try {
      final String? token = await getToken();
      final List<String>? code = await getCompanyCode();

      final response = await http.get(
        Uri.parse(
            '${Constants.baseUrl}/items/get-items/${code![0]}?page=$page&limit=$limit'),
        headers: {
          'Authorization': '$token',
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final itemData = responseData['data'];

        totalPages =
            responseData['totalPages']; // Ensure totalPages is set correctly

        final List<Item> items = List.from(itemData.map((entry) {
          entry.remove('images');
          return Item.fromMap(entry);
        }));
        return items;
      } else {
        print('${responseData['message']}');
      }

      // Return an empty list in case of failure
      return [];
    } catch (error) {
      print(error.toString());
      return [];
    }
  }

  Future<Item?> fetchItemById(String id) async {
    try {
      final String? token = await getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/items/get-item/$id'),
        headers: {
          'Authorization': '$token',
        },
      );

      final responseData = json.decode(response.body);

      // print(responseData);

      if (responseData['success'] == true) {
        var itemData = responseData['data'];

        // itemData.remove('images');

        if (itemData != null) {
          return Item.fromMap(itemData);
        } else {
          return null;
        }
      } else {
        print('${responseData['message']}');
        return null;
      }
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future<Item?> getSingleItem(String id) async {
    return fetchItemById(id);
  }

  Future<void> deleteItem(String id, BuildContext context) async {
    final String? token = await getToken();
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/items/delete-item/$id'),
        headers: {
          'Authorization': '$token',
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Item deleted successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER_LEFT,
          backgroundColor: Colors.purple,
          textColor: Colors.white,
        );
      } else {
        Navigator.of(context).pop();
        print('Failed to delete item: ${responseData['message']}');
      }
    } catch (error) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error deleting ledger: $error');
    }
  }

  Future<void> updateItem({
    required String id, // ID of the item to update
    required String companyCode, // ID of the item to update
    required String itemGroup,
    required String itemBrand,
    required String itemName,
    required String printName,
    required String codeNo,
    required String taxCategory,
    required String hsnCode,
    required String storeLocation,
    required String measurementUnit,
    required String secondaryUnit,
    required int minimumStock,
    required int maximumStock,
    required int monthlySalesQty,
    required String date,
    required String barcode,
    required double dealer,
    required double subDealer,
    required double retail,
    required double mrp,
    required String openingStock,
    required String status,
    required double discountAmount,
    required List<String> images,
    required double price,
    required ProductMetadata productMetadata,
    required BuildContext context,
  }) async {
    try {
      final Uri uri = Uri.parse('${Constants.baseUrl}/items/update-item/$id');

      Item item = Item(
        id: id, // Ensure you pass the ID of the item to update
        itemGroup: itemGroup,
        companyCode: companyCode,
        itemBrand: itemBrand,
        itemName: itemName,
        printName: printName,
        codeNo: codeNo,
        taxCategory: taxCategory,
        hsnCode: hsnCode,
        storeLocation: storeLocation,
        measurementUnit: measurementUnit,
        secondaryUnit: secondaryUnit,
        minimumStock: minimumStock,
        maximumStock: maximumStock,
        monthlySalesQty: monthlySalesQty,
        status: status,
        openingStock: openingStock,
        dealer: dealer,
        subDealer: subDealer,
        retail: retail,
        mrp: mrp,
        date: date,
        images: images,
        price: price,
        barcode: barcode,
        productMetadata: productMetadata,
        discountAmount: discountAmount,
      );
      final String? token = await getToken();

      final http.Response response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: item.toJson(),
      );

      print(response.body);

      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          Alert(
            context: context,
            type: AlertType.success,
            title: "Success",
            desc: "Item has been updated successfully",
            buttons: [
              DialogButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ItemHome(),
                  ),
                ),
                width: 120,
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          ).show();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> updateItem2({
    required String id, // ID of the item to update
    required String companyCode, // ID of the item to update
    required String itemGroup,
    required String itemBrand,
    required String itemName,
    required String printName,
    required String codeNo,
    required String taxCategory,
    required String hsnCode,
    required String storeLocation,
    required String measurementUnit,
    required String secondaryUnit,
    required int minimumStock,
    required int maximumStock,
    required int monthlySalesQty,
    required String date,
    required double dealer,
    required double subDealer,
    required double retail,
    required double mrp,
    required String openingStock,
    required String status,
    required List<String> images,
    required double discountAmount,
    required double price,
    required BuildContext context,
  }) async {
    try {
      final Uri uri = Uri.parse('${Constants.baseUrl}/items/update-item/$id');

      Item item = Item(
        id: id, // Ensure you pass the ID of the item to update
        itemGroup: itemGroup,
        itemBrand: itemBrand,
        itemName: itemName,
        printName: printName,
        codeNo: codeNo,
        taxCategory: taxCategory,
        hsnCode: hsnCode,
        storeLocation: storeLocation,
        measurementUnit: measurementUnit,
        secondaryUnit: secondaryUnit,
        minimumStock: minimumStock,
        maximumStock: maximumStock,
        monthlySalesQty: monthlySalesQty,
        status: status,
        openingStock: openingStock,
        dealer: dealer,
        subDealer: subDealer,
        retail: retail,
        mrp: mrp,
        date: date,
        images: images,
        price: price,
        barcode: 'Add barcode here',
        discountAmount: discountAmount,
      );
      final String? token = await getToken();

      final http.Response response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: item.toJson(),
      );

      print(response.body);

      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          Fluttertoast.showToast(
            msg: 'Item updated successfully',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER_LEFT,
            backgroundColor: Colors.purple,
            textColor: Colors.white,
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SalesHome(
                item: [],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<List<Item>> searchItemsByBarcode(String query) async {
    try {
      final String? token = await getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/items/get-item-by-barcode/$query'),
        headers: {
          'Authorization': '$token',
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final itemData = responseData['data'];

        final List<Item> items = List.from(itemData.map((entry) {
          entry.remove('images');
          return Item.fromMap(entry);
        }));

        return items;
      } else {
        print('${responseData['message']}');
      }

      // Return an empty list in case of failure
      return [];
    } catch (error) {
      print(error.toString());
      return [];
    }
  }
}
