import 'dart:typed_data';

import 'package:billingsphere/data/models/brand/item_brand_model.dart';
import 'package:billingsphere/data/models/item/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../data/models/itemGroup/item_group_model.dart';
import '../data/repository/item_brand_repository.dart';
import '../data/repository/item_group_repository.dart';
import '../logic/cubits/itemBrand_cubit/itemBrand_cubit.dart';
import 'DB_responsive/DB_desktop_body.dart';

class ItemBrandEdit extends StatefulWidget {
  const ItemBrandEdit({super.key});

  @override
  State<ItemBrandEdit> createState() => _ItemBrandEditState();
}

class _ItemBrandEditState extends State<ItemBrandEdit> {
  List<ItemsBrand> itemBrands = [];
  final List<String> _selectedImages = [];
  final List<Uint8List> _selectedImagesBytes = [];
  List<ItemsGroup> itemGroups = [];
  String _selectedValue = '';
  ItemsBrandsService itemsBrandsService = ItemsBrandsService();
  ItemsGroupService itemsGroupsService = ItemsGroupService();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> fetchItemBrands() async {
    final itemBrands = await itemsBrandsService.fetchItemBrands();
    setState(() {
      this.itemBrands = itemBrands;
    });

    print(itemBrands.length);
  }

  Future<void> fetchItemGroups() async {
    final itemGroups = await itemsGroupsService.fetchItemGroups();
    setState(() {
      this.itemGroups = itemGroups;
      _selectedValue = itemGroups.first.id;
    });

    print(itemGroups.length);
  }

  Future<void> _fetchData() async {
    await Future.wait([
      BlocProvider.of<ItemBrandCubit>(context).getItemBrand(),
    ]);
  }

  Future<String> uploadImageToFirebase(Uint8List? imageData) async {
    const String placeholderUrl =
        'https://img.freepik.com/free-vector/illustration-gallery-icon_53876-27002.jpg'; // Set your placeholder image URL

    if (imageData == null || imageData.isEmpty) {
      print("No image data found");
      return placeholderUrl;
    }

    FirebaseStorage storage = FirebaseStorage.instance;
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    Reference ref = storage.ref().child('itemBrandImages/$timestamp.png');
    UploadTask uploadTask = ref.putData(imageData);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  void initState() {
    super.initState();
    fetchItemBrands();
    fetchItemGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.cyan,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DBMyDesktopBody(),
                      ),
                    );
                  },
                  icon: const Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.45),
                Text(
                  'ITEM BRAND MASTER',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
              child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white10,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: itemBrands.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: ListTile(
                    title: Text(
                      itemBrands[index].name,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    subtitle: Text(itemBrands[index].name,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            itemsBrandsService
                                .fetchItemBrandById(itemBrands[index].id)
                                .then((value) {
                              TextEditingController nameController =
                                  TextEditingController(text: value.name);
                              _selectedImages.add(value.images);
                              // _selectedImages =
                              //     value.images!.map((e) => e.data).toList();
                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Edit Item Brand'),
                                    content: SizedBox(
                                      width: 300,
                                      height: 350,
                                      child: StatefulBuilder(
                                        builder: (context, setState) {
                                          return Column(
                                            children: [
                                              TextField(
                                                controller: nameController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Item Brand Name',
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  const Icon(CupertinoIcons
                                                      .square_stack_3d_up_fill),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  DropdownButton<String>(
                                                    value: _selectedValue,
                                                    icon: const Icon(
                                                        Icons.arrow_drop_down),
                                                    iconSize: 24,
                                                    elevation: 16,
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        _selectedValue =
                                                            newValue!;
                                                      });
                                                    },
                                                    items: itemGroups
                                                        .map((ItemsGroup item) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: item.id,
                                                        child: Text(item
                                                            .name), // Display item name
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  FilePickerResult? result =
                                                      await FilePicker.platform
                                                          .pickFiles(
                                                    type: FileType.custom,
                                                    allowedExtensions: [
                                                      'jpg',
                                                      'jpeg',
                                                      'png',
                                                      'gif'
                                                    ],
                                                  );

                                                  if (result != null) {
                                                    List<Uint8List>
                                                        fileBytesList = [];

                                                    for (PlatformFile file
                                                        in result.files) {
                                                      Uint8List fileBytes =
                                                          file.bytes!;
                                                      fileBytesList
                                                          .add(fileBytes);
                                                    }

                                                    setState(() {
                                                      _selectedImagesBytes
                                                          .addAll(
                                                              fileBytesList);
                                                    });
                                                  }
                                                },
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: Container(
                                                    width: double.infinity,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white10,
                                                      border: Border.all(
                                                        color: Colors.white54,
                                                        width: 1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.white10,
                                                          blurRadius: 2,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: _selectedImages
                                                            .isNotEmpty
                                                        ? Center(
                                                            child:
                                                                Image.network(
                                                              _selectedImages[
                                                                  0],
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : const Center(
                                                            child: Icon(
                                                              CupertinoIcons
                                                                  .camera,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    String imageUrl = '';
                                                    await Future.forEach(
                                                        _selectedImagesBytes,
                                                        (Uint8List
                                                            image) async {
                                                      imageUrl =
                                                          await uploadImageToFirebase(
                                                              image);
                                                      _selectedImages
                                                          .add(imageUrl);
                                                    });

                                                    final brandData =
                                                        await itemsBrandsService
                                                            .updateItemBrand(
                                                      id: value.id,
                                                      name: nameController.text,
                                                      images: imageUrl,
                                                    );

                                                    if (brandData == null) {
                                                      throw Exception(
                                                          'Brand creation failed');
                                                    }

                                                    // Fetch the category document from Firestore
                                                    DocumentSnapshot
                                                        categoryData =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                "AllCategories")
                                                            .doc(_selectedValue)
                                                            .get();

                                                    if (categoryData.exists) {
                                                      Map<String, dynamic>
                                                          data =
                                                          categoryData.data()
                                                              as Map<String,
                                                                  dynamic>;
                                                      List<dynamic> brands =
                                                          data['brands'] ?? [];

                                                      // Add the new brand to the array
                                                      brands.add({
                                                        'id': brandData
                                                            .id, // Use the actual brand ID
                                                        'name': brandData.name,
                                                        'image':
                                                            brandData.images,
                                                      });

                                                      // Update the category document with the new brands array
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              "AllCategories")
                                                          .doc(_selectedValue)
                                                          .update({
                                                        'brands': brands
                                                      });
                                                    }
                                                    setState(() {
                                                      _selectedImages.clear();
                                                      nameController.clear();
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.cyan,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 2,
                                                    animationDuration:
                                                        const Duration(
                                                            seconds: 2),
                                                  ),
                                                  child: const Text('Submit'),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedImages.clear();
                                                      nameController.clear();
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 2,
                                                    animationDuration:
                                                        const Duration(
                                                            seconds: 2),
                                                  ),
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
                          },
                          icon: const Icon(
                            CupertinoIcons.eye,
                            color: Colors.cyan,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Delete Item Brand'),
                                  content: const Text(
                                      'Are you sure you want to delete this Item Brand?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await itemsBrandsService
                                            .deleteItemBrands(
                                                itemBrands[index].id);
                                        Navigator.of(context).pop();
                                        setState(() {
                                          itemBrands.removeAt(index);
                                        });
                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ItemBrandEdit()));
                                      },
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController catNameController =
              TextEditingController();
          final TextEditingController catBrandController =
              TextEditingController();

          final TextEditingController catDescController =
              TextEditingController();

          List<Uint8List> selectedImage = [];

          Alert(
              context: context,
              title: "ADD BRAND",
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: catBrandController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.category),
                          labelText: 'Brand Name',
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Dropdown button with itemGroup
                      Row(
                        children: [
                          const Icon(CupertinoIcons.square_stack_3d_up_fill),
                          const SizedBox(
                            width: 10,
                          ),
                          DropdownButton<String>(
                            value: _selectedValue,
                            icon: const Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedValue = newValue!;
                              });
                            },
                            items: itemGroups.map((ItemsGroup item) {
                              return DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.name), // Display item name
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
                          );

                          if (result != null) {
                            List<Uint8List> fileBytesList = [];

                            for (PlatformFile file in result.files) {
                              Uint8List fileBytes = file.bytes!;
                              fileBytesList.add(fileBytes);
                            }

                            setState(() {
                              _selectedImagesBytes.addAll(fileBytesList);
                            });
                          }
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(
                                color: Colors.black,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white10,
                                  blurRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _selectedImages.isNotEmpty
                                ? Center(
                                    child: Image.network(
                                      _selectedImages[0],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      CupertinoIcons.camera,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              buttons: [
                DialogButton(
                  color: Colors.yellow.shade100,
                  onPressed: () async {
                    String imageUrl = '';
                    await Future.forEach(_selectedImagesBytes,
                        (Uint8List image) async {
                      imageUrl = await uploadImageToFirebase(image);
                      _selectedImages.add(imageUrl);
                    });

                    if (catBrandController.text.isEmpty || imageUrl.isEmpty) {
                      Fluttertoast.showToast(
                          msg: "Please all fields are required");
                      return;
                    }
                    // Create the item brand with the first image URL
                    final createdBrand =
                        await itemsBrandsService.createItemBrand(
                      name: catBrandController.text,
                      images: imageUrl,
                    );

                    if (createdBrand == null) {
                      throw Exception('Brand creation failed');
                    }

                    // Fetch the category document from Firestore
                    DocumentSnapshot categoryData = await FirebaseFirestore
                        .instance
                        .collection("AllCategories")
                        .doc(_selectedValue)
                        .get();

                    if (categoryData.exists) {
                      Map<String, dynamic> data =
                          categoryData.data() as Map<String, dynamic>;
                      List<dynamic> brands = data['brands'] ?? [];

                      // Add the new brand to the array
                      brands.add({
                        'id': createdBrand.id, // Use the actual brand ID
                        'name': createdBrand.name,
                        'image': createdBrand.images,
                      });

                      // Update the category document with the new brands array
                      await FirebaseFirestore.instance
                          .collection("AllCategories")
                          .doc(_selectedValue)
                          .update({'brands': brands});
                    }

                    // Optionally fetch updated data
                    await _fetchData();

                    // Navigate to the ItemBrandEdit page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ItemBrandEdit(),
                      ),
                    );
                  },
                  child: const Text(
                    "CREATE",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
                DialogButton(
                  color: Colors.yellow.shade100,
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ]).show();
        },
        child: const Text('Add'),
      ),
    );
  }
}
