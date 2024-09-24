import 'dart:typed_data';

import 'package:billingsphere/data/models/item/item_model.dart';
import 'package:billingsphere/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../data/models/itemGroup/item_group_model.dart';
import '../data/repository/item_group_repository.dart';
import '../logic/cubits/itemGroup_cubit/itemGroup_cubit.dart';
import 'DB_responsive/DB_desktop_body.dart';

class ItemGroupEdit extends StatefulWidget {
  const ItemGroupEdit({super.key});

  @override
  State<ItemGroupEdit> createState() => _ItemGroupEditState();
}

class _ItemGroupEditState extends State<ItemGroupEdit> {
  List<ItemsGroup> itemGroups = [];
  final List<String> _selectedImages = [];
  ItemsGroupService itemsGroupsService = ItemsGroupService();
  final List<Uint8List> _selectedImagesBytes = [];

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> fetchItemGroups() async {
    final itemGroups = await itemsGroupsService.fetchItemGroups();
    setState(() {
      this.itemGroups = itemGroups;
    });

    print(itemGroups.length);
  }

  @override
  void initState() {
    super.initState();
    fetchItemGroups();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      BlocProvider.of<ItemGroupCubit>(context).getItemGroups(),
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
    Reference ref = storage.ref().child('itemGroupImages/$timestamp.png');
    UploadTask uploadTask = ref.putData(imageData);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
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
                  'ITEM GROUP MASTER',
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
              itemCount: itemGroups.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: ListTile(
                    title: Text(
                      itemGroups[index].name,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    subtitle: Text(itemGroups[index].name,
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
                            itemsGroupsService
                                .fetchItemGroupById(itemGroups[index].id)
                                .then((value) {
                              TextEditingController nameController =
                                  TextEditingController(text: value!.name);
                              TextEditingController descController =
                                  TextEditingController(text: value!.desc);

                              _selectedImages.add(value.images);

                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Edit Item Group'),
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
                                                  labelText: 'Item Group Name',
                                                ),
                                              ),
                                              TextField(
                                                controller: descController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Item Group Desc.',
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              GestureDetector(
                                                onTap: () async {
                                                  _selectedImages.clear();
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
                                                    // Save the image to firebase storage
                                                    await Future.forEach(
                                                        _selectedImagesBytes,
                                                        (Uint8List
                                                            image) async {
                                                      String imageUrl =
                                                          await uploadImageToFirebase(
                                                              image);
                                                      _selectedImages
                                                          .add(imageUrl);
                                                    });

                                                    final updatedGroup =
                                                        await itemsGroupsService
                                                            .updateItemGroup(
                                                      id: value.id,
                                                      name: nameController.text,
                                                      desc: descController.text,
                                                      images:
                                                          _selectedImages.first,
                                                    );

                                                    DocumentSnapshot
                                                        categoryData =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                "AllCategories")
                                                            .doc(value.id)
                                                            .get();

                                                    if (categoryData.exists) {
                                                      // Update the category document with the new brands array
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              "AllCategories")
                                                          .doc(value.id)
                                                          .update({
                                                        'name':
                                                            updatedGroup!.name,
                                                        'image':
                                                            updatedGroup.images,
                                                      });
                                                    }

                                                    setState(() {
                                                      _selectedImages.clear();
                                                      nameController.clear();
                                                    });
                                                    Navigator.of(context).pop();
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
                                                    Navigator.of(context).pop();
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
                                  title: const Text('Delete Item Group'),
                                  content: const Text(
                                      'Are you sure you want to delete this Item Group?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await itemsGroupsService
                                            .deleteItemGroup(
                                                itemGroups[index].id);
                                        Navigator.of(context).pop();
                                        setState(() {
                                          itemGroups.removeAt(index);
                                        });
                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ItemGroupEdit()));
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

          final TextEditingController catDescController =
              TextEditingController();

          List<Uint8List> selectedImage = [];

          Alert(
              context: context,
              title: "ADD ITEM GROUP",
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      TextField(
                        controller: catNameController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.category),
                          labelText: 'Category Name',
                        ),
                      ),
                      TextField(
                        controller: catDescController,
                        obscureText: false,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.description),
                          labelText: 'Category Description',
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: selectedImage.isEmpty
                                ? const Center(child: Text('No Image Selected'))
                                : Image.memory(selectedImage[0]),
                          ),
                          Positioned(
                            top: 150,
                            right: -10,
                            left: 0,
                            child: GestureDetector(
                              onTap: () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                    'jpg',
                                    'jpeg',
                                    'png',
                                    'gif'
                                  ],
                                );

                                if (result != null) {
                                  List<Uint8List> fileBytesList = [];

                                  for (PlatformFile file in result.files) {
                                    Uint8List fileBytes = file.bytes!;
                                    fileBytesList.add(fileBytes);
                                  }

                                  setState(() {
                                    selectedImage.addAll(fileBytesList);
                                  });

                                  // print(_selectedImages);
                                } else {
                                  // User canceled the picker
                                  print('File picking canceled by the user.');
                                }
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: SizedBox(
                                  height: 50,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.yellow.shade100,
                                    child: const Icon(Icons.upload),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  );
                },
              ),
              buttons: [
                DialogButton(
                  color: Colors.yellow.shade100,
                  onPressed: () async {
                    await Future.forEach(selectedImage,
                        (Uint8List image) async {
                      String imageUrl = await uploadImageToFirebase(image);
                      _selectedImages.add(imageUrl);
                    });

                    if (catNameController.text.isEmpty ||
                        catDescController.text.isEmpty ||
                        _selectedImages.isEmpty) {
                      Fluttertoast.showToast(msg: "Please fill all fields");
                      return;
                    } else {
                      itemsGroupsService
                          .createItemsGroup(
                        name: catNameController.text,
                        desc: catDescController.text,
                        images: _selectedImages.first,
                      )
                          .then(
                        (value) {
                          firestore
                              .collection("AllCategories")
                              .doc(value!.id)
                              .set({
                            'id': value.id,
                            'image': value.images,
                            'name': value.name,
                            'brands': [],
                          }).catchError((error) {
                            print("Failed to add cat: $error");
                          });
                        },
                      );

                      // _fetchData();

                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const ItemGroupEdit()));
                    }
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
        child: Text('Add'),
      ),
    );
  }
}
