// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:billingsphere/data/models/brand/item_brand_model.dart';
import 'package:billingsphere/data/models/hsn/hsn_model.dart';
import 'package:billingsphere/data/models/item/item_model.dart';
import 'package:billingsphere/data/models/itemGroup/item_group_model.dart';
import 'package:billingsphere/data/models/measurementLimit/measurement_limit_model.dart';
import 'package:billingsphere/data/models/secondaryUnit/secondary_unit_model.dart';
import 'package:billingsphere/data/models/storeLocation/store_location_model.dart';
import 'package:billingsphere/data/models/taxCategory/tax_category_model.dart';
import 'package:billingsphere/data/repository/item_repository.dart';
import 'package:billingsphere/logic/cubits/itemBrand_cubit/itemBrand_state.dart';
import 'package:billingsphere/logic/cubits/itemGroup_cubit/itemGroup_cubit.dart';
import 'package:billingsphere/utils/controllers/items_text_controllers.dart';
import 'package:billingsphere/views/NI_widgets/NI_new_table.dart';
import 'package:billingsphere/views/NI_widgets/NI_singleTextField.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_network/image_network.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repository/barcode_repository.dart';
import '../../data/repository/item_brand_repository.dart';
import '../../data/repository/item_group_repository.dart';
import '../../logic/cubits/hsn_cubit/hsn_cubit.dart';
import '../../logic/cubits/hsn_cubit/hsn_state.dart';
import '../../logic/cubits/itemBrand_cubit/itemBrand_cubit.dart';
import '../../logic/cubits/itemGroup_cubit/itemGroup_state.dart';
import '../../logic/cubits/measurement_cubit/measurement_limit_cubit.dart';
import '../../logic/cubits/measurement_cubit/measurement_limit_state.dart';
import '../../logic/cubits/secondary_unit_cubit/secondary_unit_cubit.dart';
import '../../logic/cubits/secondary_unit_cubit/secondary_unit_state.dart';
import '../../logic/cubits/store_cubit/store_cubit.dart';
import '../../logic/cubits/store_cubit/store_state.dart';
import '../../logic/cubits/taxCategory_cubit/taxCategory_cubit.dart';
import '../../logic/cubits/taxCategory_cubit/taxCategory_state.dart';
import '../sumit_screen/hsn_code/hsn_code.dart';
import '../sumit_screen/measurement_unit/measurement_unit.dart';
import '../sumit_screen/secondary_unit/secondary_unit.dart';
import '../sumit_screen/store_location/store_location.dart';
import 'NI_desktopBody.dart';

class NIMyDesktopBodyE extends StatefulWidget {
  const NIMyDesktopBodyE({super.key, required this.id, required this.name});

  final String name;
  final String id;

  @override
  State<NIMyDesktopBodyE> createState() => _BasicDetailsState();
}

class _BasicDetailsState extends State<NIMyDesktopBodyE> {
  List<List<String>> tableData = [
    // Initial data for the table
    ["Header 1", "Header 2", "Header 3"],
    ["Data 1", "Data 2", "Data 3"],
  ];

  bool _isSaving = false;
  ItemsService items = ItemsService();
  List<String> _selectedImages = [];
  List<String> _selectedImageUrls = [];
  List<Uint8List> _selectedImagesBytes = [];
  Item? _item;
  List<String>? companyCode;
  String selectedBarcode = '';
  List<String> imageUrls = [];

  ProductMetadata? productMetadataObject;

  Future<List<String>?> getCompanyCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('companies');
  }

  Future<void> setCompanyCode() async {
    List<String>? code = await getCompanyCode();
    setState(() {
      companyCode = code;
    });
  }

  Future<List<String>> uploadImagesToFirebase(
      List<Uint8List> imageDataList, String itemName, String id) async {
    const String placeholderUrl =
        'https://img.freepik.com/free-vector/illustration-gallery-icon_53876-27002.jpg'; // Placeholder image URL

    if (imageDataList.isEmpty) {
      print("No image data found");
      return [placeholderUrl];
    }

    FirebaseStorage storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];
    String cleanedItemName = itemName.replaceAll(
        RegExp(r'[^a-zA-Z0-9_]'), '_'); // Clean the item name for folder naming

    for (var imageData in imageDataList) {
      try {
        // Create a unique reference for each image within the item's folder
        Reference ref = storage.ref().child(
            'itemImages/${widget.name}/${DateTime.now().millisecondsSinceEpoch}.png');
        UploadTask uploadTask = ref.putData(imageData);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image: $e");
        downloadUrls
            .add(placeholderUrl); // Add a placeholder URL in case of an error
      }
    }

    return downloadUrls;
  }

  Future<String> uploadImageToFirebase(Uint8List? imageData, String id) async {
    const String placeholderUrl =
        'https://img.freepik.com/free-vector/illustration-gallery-icon_53876-27002.jpg'; // Set your placeholder image URL

    if (imageData == null || imageData.isEmpty) {
      print("No image data found");
      return placeholderUrl;
    }

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('itemImages/$id.png');
    UploadTask uploadTask = ref.putData(imageData);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  void _showImageDialog(BuildContext context, List<Uint8List> images) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selected Images'),
          content: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.memory(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void createItems() async {
    setState(() {
      _isSaving = true;
    });

    if (_selectedImagesBytes.isNotEmpty) {
      try {
        // Attempt to upload the image to Firebase.

        imageUrls = await uploadImagesToFirebase(
            _selectedImagesBytes, widget.name, widget.id);

        // Check if the image URL is valid.
        if (imageUrls.isEmpty || imageUrls.contains('')) {
          throw Exception('Failed to upload image to Firebase.');
        }
      } catch (e) {
        // Log the error and exit the function if the image upload fails.
        print('Error uploading image: $e');

        // Update the state to indicate the save operation has ended due to error.
        setState(() {
          _isSaving = false;
        });

        return; // Exit the function without updating the item.
      }
    } else {
      imageUrls = _selectedImages;
    }

    print('Image URL: $imageUrls');
    // Print all the fields to be saved for debugging purposes
    print("Company Code: ${companyCode!.first}");
    print("Item Group: $selectedItemId");
    print("Item Brand: $selectedItemId2");
    print("Item Name: ${controllers.itemNameController.text}");
    print("Print Name: ${controllers.printNameController.text}");
    print("Code No: ${controllers.codeNoController.text}");
    print("Tax Category: $selectedTaxRateId");
    print("HSN Code: $selectedHSNCodeId");
    print("Store Location: $selectedStoreLocationId");
    print("Measurement Unit: $selectedMeasurementLimitId");
    print("Secondary Unit: $selectedSecondaryUnitId");
    print("Minimum Stock: ${controllers.minimumStockController.text}");
    print("Maximum Stock: ${controllers.maximumStockController.text}");
    print("Monthly Sales Qty: ${controllers.monthlySalesQtyController.text}");
    print("Dealer: ${controllers.dealerController.text}");
    print("Sub Dealer: ${controllers.subDealerController.text}");
    print("Retail: ${controllers.retailController.text}");
    print("MRP: ${controllers.mrpController.text}");
    print("Opening Stock: $selectedStock");
    print("Barcode: $selectedBarcode");
    print("Status: $selectedStatus");
    print("Date: ${controllers.dateController.text}");
    print("Price: ${controllers.currentPriceController.text}");
    print("Discount Amount: ${controllers.discountController.text}");
    print("Product Metadata: $productMetadataObject");

    items.updateItem(
      companyCode: companyCode!.first,
      id: widget.id,
      itemGroup: selectedItemId!,
      itemBrand: selectedItemId2!,
      itemName: controllers.itemNameController.text,
      printName: controllers.printNameController.text,
      codeNo: controllers.codeNoController.text,
      taxCategory: selectedTaxRateId!,
      hsnCode: selectedHSNCodeId!,
      storeLocation: selectedStoreLocationId!,
      measurementUnit: selectedMeasurementLimitId!,
      secondaryUnit: selectedSecondaryUnitId!,
      minimumStock:
          int.tryParse(controllers.minimumStockController.text.trim()) ?? 0,
      maximumStock:
          int.tryParse(controllers.maximumStockController.text.trim()) ?? 0,
      monthlySalesQty:
          int.tryParse(controllers.monthlySalesQtyController.text.trim()) ?? 0,
      dealer: double.parse(controllers.dealerController.text),
      subDealer: double.parse(controllers.subDealerController.text),
      retail: double.parse(controllers.retailController.text),
      mrp: double.parse(controllers.mrpController.text),
      openingStock: selectedStock,
      barcode: selectedBarcode,
      status: selectedStatus,
      context: context,
      date: controllers.dateController.text,
      price: double.parse(controllers.currentPriceController.text),
      images: imageUrls,
      discountAmount: double.parse(controllers.discountController.text),
      productMetadata: productMetadataObject!,
    );

    controllers.itemNameController.clear();
    controllers.printNameController.clear();
    controllers.codeNoController.clear();
    controllers.minimumStockController.clear();
    controllers.maximumStockController.clear();
    controllers.monthlySalesQtyController.clear();
    controllers.dealerController.clear();
    controllers.subDealerController.clear();
    controllers.retailController.clear();
    controllers.mrpController.clear();
    controllers.openingStockController.clear();
    controllers.barcodeController.clear();
    controllers.dateController.clear();
    selectedItemId = fetchedItemGroups.first.id;
    selectedItemId2 = fetchedItemBrands.first.id;
    selectedTaxRateId = fetchedTaxCategories.first.id;
    selectedHSNCodeId = fetchedHSNCodes.first.id;
    selectedStoreLocationId = fetchedStores.first.id;
    selectedMeasurementLimitId = fetchedMLimits.first.id;
    selectedSecondaryUnitId = fetchedSUnit.first.id;
    _selectedImages = [];
    selectedStatus = 'Active';
    selectedStock = 'Yes';
    setState(() {
      _isSaving = false;
    });
  }

  //  Dropdown Data
  List<ItemsGroup> fetchedItemGroups = [];
  List<ItemsBrand> fetchedItemBrands = [];
  List<TaxRate> fetchedTaxCategories = [];
  List<HSNCode> fetchedHSNCodes = [];
  List<StoreLocation> fetchedStores = [];
  List<MeasurementLimit> fetchedMLimits = [];
  List<SecondaryUnit> fetchedSUnit = [];
  List<String> status = ['Active', 'Inactive'];
  List<String> stock = ['Yes', 'No'];
  List<File> files = [];

  List<MetadataTextfield> productFeaturesWidget = [];
  List<MetadataTextfield> productIngredientsWidget = [];
  List<MetadataTextfield> productBenefitsWidget = [];

  // Variables
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFetched = false;

  // Dropdown Values
  String? selectedItemId;
  String? selectedItemId2;
  String? selectedTaxRateId;
  String? selectedHSNCodeId;
  String? selectedStoreLocationId;
  String? selectedMeasurementLimitId;
  String? selectedSecondaryUnitId;
  String selectedStatus = 'Active';
  String selectedStock = 'Yes';
  String selectedDiscount = 'No';

  // Controllers
  ItemsFormControllers controllers = ItemsFormControllers();
  BarcodeRepository barcodeRepository = BarcodeRepository();
  ItemsGroupService itemsGroup = ItemsGroupService();
  ItemsBrandsService itemsBrand = ItemsBrandsService();

  TextEditingController overviewController = TextEditingController();

  Map<String, dynamic> productMetadata = {};

  @override
  void initState() {
    _allDataInit();
    super.initState();
  }

  Future<void> fetchBarcodeData(String id) async {
    final barcode = await barcodeRepository.fetchBarcodeById(id);
    setState(() {
      controllers.barcodeController.text = barcode!.barcode;
    });
  }

  void _allDataInit() {
    _fetchData();
    setCompanyCode();
    _fetchSingleItem();
  }

  saveMetadata() {
    productMetadata['overview'] = overviewController.text.trim();
    productMetadata['productFeatures'] =
        productFeaturesWidget.map((e) => e.controller.text.trim()).toList();

    productMetadata['productIngredients'] =
        productIngredientsWidget // Product Ingredients
            .map((e) => e.controller.text)
            .toList();

    productMetadata['productBenefits'] =
        productBenefitsWidget.map((e) => e.controller.text.trim()).toList();

    productMetadataObject = ProductMetadata(
      overview: productMetadata['overview'] as String,
      features: productMetadata['productFeatures'] as List<String>,
      ingredients: productMetadata['productIngredients'] as List<String>,
      benefits: productMetadata['productBenefits'] as List<String>,
    );

    // print
    print(productMetadata);

    // Pop the dialog
    Navigator.pop(context);
  }

  Future<void> _fetchSingleItem() async {
    print(widget.id);
    try {
      final item = await items.getSingleItem(widget.id);

      setState(() {
        _item = item;

        DateTime dateTime = DateTime.parse(_item!.date);
        String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

        selectedItemId = _item!.itemGroup;
        selectedItemId2 = _item!.itemBrand;
        selectedTaxRateId = _item!.taxCategory;
        selectedHSNCodeId = _item!.hsnCode;
        selectedStoreLocationId = _item!.storeLocation;
        selectedMeasurementLimitId = _item!.measurementUnit;
        selectedSecondaryUnitId = _item!.secondaryUnit;
        controllers.codeNoController.text = _item!.codeNo;
        controllers.itemNameController.text = _item!.itemName;
        controllers.dateController.text = formattedDate;
        controllers.dealerController.text = _item!.dealer.toString();
        controllers.maximumStockController.text =
            _item!.maximumStock.toString();
        controllers.minimumStockController.text =
            _item!.minimumStock.toString();
        controllers.currentPriceController.text =
            _item!.price!.toStringAsFixed(2).toString();
        controllers.mrpController.text =
            _item!.mrp.toStringAsFixed(2).toString();
        controllers.printNameController.text = _item!.printName.toString();
        controllers.retailController.text =
            _item!.retail.toStringAsFixed(2).toString();
        selectedBarcode = _item!.barcode;
        controllers.subDealerController.text =
            _item!.subDealer.toStringAsFixed(2).toString();
        controllers.monthlySalesQtyController.text =
            _item!.monthlySalesQty.toString();
        controllers.discountController.text = _item!.discountAmount.toString();
        selectedDiscount = _item!.discountAmount <= 0.00 ? 'No' : 'Yes';
        selectedStock = _item!.openingStock;
        selectedStatus = _item!.status;

        // Assuming images is a list of URLs
        _selectedImages = List<String>.from(_item!.images ?? []);

        overviewController.text = _item!.productMetadata!.overview;

        productFeaturesWidget = _item!.productMetadata!.features
            .map((feature) => MetadataTextfield(
                  maxLines: 1,
                  controller: TextEditingController(text: feature),
                ))
            .toList();

        productIngredientsWidget = _item!.productMetadata!.ingredients
            .map((ingredient) => MetadataTextfield(
                  maxLines: 1,
                  controller: TextEditingController(text: ingredient),
                ))
            .toList();

        productBenefitsWidget = _item!.productMetadata!.benefits // Error here
            .map((benefit) => MetadataTextfield(
                  maxLines: 1,
                  controller: TextEditingController(text: benefit),
                ))
            .toList();

        productMetadata = {
          'overview': _item!.productMetadata!.overview,
          'productFeatures': _item!.productMetadata!.features,
          'productIngredients': _item!.productMetadata!.ingredients,
          'productBenefits': _item!.productMetadata!.benefits,
        };

        productMetadataObject = ProductMetadata(
          overview: productMetadata['overview'] as String,
          features: productMetadata['productFeatures'] as List<String>,
          ingredients: productMetadata['productIngredients'] as List<String>,
          benefits: productMetadata['productBenefits'] as List<String>,
        );
      });

      print("IMAGES FROM FIREBASE STORAGE: $_selectedImages");

      await fetchBarcodeData(_item!.barcode.toString());
    } catch (error) {
      // Handle error appropriately, e.g., show a SnackBar or dialog
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Failed to fetch item: $error'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  // Method to fetch data from Cubits
  void _fetchData() async {
    await Future.wait([
      BlocProvider.of<ItemBrandCubit>(context).getItemBrand(),
      BlocProvider.of<ItemGroupCubit>(context).getItemGroups(),
      BlocProvider.of<TaxCategoryCubit>(context).getTaxCategory(),
      BlocProvider.of<HSNCodeCubit>(context).getHSNCodes(),
      BlocProvider.of<CubitStore>(context).getStores(),
      BlocProvider.of<MeasurementLimitCubit>(context).getLimit(),
      BlocProvider.of<SecondaryUnitCubit>(context).getLimit(),
    ]);
  }

  void openProductMetadata() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Dialog(
            alignment: AlignmentDirectional.centerEnd,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        color: const Color(0xFF510986),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                'Product Metadata',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            const SizedBox(height: 10),
                            // Text, Produt description
                            const MetadataText(
                              label: 'Overview',
                            ),
                            const SizedBox(height: 5),
                            // Textfield
                            MetadataTextfield(
                              maxLines: 5,
                              controller: overviewController,
                            ),
                            // Text, Product Features
                            const MetadataText(label: 'Product Features'),
                            // Textfield
                            Column(
                              children: productFeaturesWidget,
                            ),
                            // Button
                            MetadataButton(
                              icon: Icons.add,
                              onPressed: () {
                                setState(() {
                                  productFeaturesWidget.add(MetadataTextfield(
                                    maxLines: 1,
                                    controller: TextEditingController(),
                                  ));
                                });
                              },
                              text: 'Add New Product Features',
                            ),
                            const SizedBox(height: 10),
                            // Text, Product Ingredients
                            const MetadataText(label: 'Product Ingredients'),
                            // Textfield
                            Column(
                              children: productIngredientsWidget,
                            ),
                            // Button
                            MetadataButton(
                              icon: Icons.add,
                              onPressed: () {
                                setState(() {
                                  productIngredientsWidget
                                      .add(MetadataTextfield(
                                    maxLines: 1,
                                    controller: TextEditingController(),
                                  ));
                                });
                              },
                              text: 'Add New Product Ingredients',
                            ),
                            const SizedBox(height: 10),
                            // Text, Product Benefits
                            const MetadataText(label: 'Product Benefits'),
                            // Textfield
                            Column(
                              children: productBenefitsWidget,
                            ),
                            // Button
                            MetadataButton(
                              icon: Icons.add,
                              onPressed: () {
                                setState(() {
                                  productBenefitsWidget.add(MetadataTextfield(
                                    maxLines: 1,
                                    controller: TextEditingController(),
                                  ));
                                });
                              },
                              text: 'Add New Product Benefits',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                fixedSize: Size(
                                    MediaQuery.of(context).size.width * .1, 25),
                                shape: const BeveledRectangleBorder(
                                    side: BorderSide(
                                        color: Colors.black, width: .3)),
                                backgroundColor: Colors.yellow.shade100),
                            onPressed: saveMetadata,
                            child: Text(
                              'SAVE [F4]',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(
                                  0xFF000000,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.1;
    double buttonHeight = MediaQuery.of(context).size.height * 0.03;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('EDIT Item', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ItemBrandCubit, CubitItemBrandStates>(
            listener: (context, state) {
              if (state is CubitItemBrandLoaded) {
                setState(() {
                  fetchedItemBrands = state.itemBrands;
                });
              } else if (state is CubitItemBrandError) {
                print(state.error);
              }
            },
          ),
          BlocListener<ItemGroupCubit, CubitItemGroupStates>(
            listener: (context, state) {
              if (state is CubitItemGroupLoaded) {
                setState(() {
                  fetchedItemGroups = state.itemGroups;
                });
              } else if (state is CubitItemGroupError) {
                print(state.error);
              }
            },
          ),
          BlocListener<TaxCategoryCubit, CubitTaxCategoryStates>(
            listener: (context, state) {
              if (state is CubitTaxCategoryLoaded) {
                setState(() {
                  fetchedTaxCategories = state.taxCategories;
                });
              } else if (state is CubitTaxCategoryError) {
                print(state.error);
              }
            },
          ),
          BlocListener<HSNCodeCubit, CubitHsnStates>(
            listener: (context, state) {
              if (state is CubitHsnLoaded) {
                setState(() {
                  fetchedHSNCodes = state.hsns;
                });
              } else if (state is CubitHsnError) {
                print(state.error);
              }
            },
          ),
          BlocListener<CubitStore, CubitStoreStates>(
            listener: (context, state) {
              if (state is CubicStoreLoaded) {
                setState(() {
                  fetchedStores = state.stores;
                });
              } else if (state is CubitStoreError) {
                print(state.error);
              }
            },
          ),
          BlocListener<MeasurementLimitCubit, CubitMeasurementLimitStates>(
            listener: (context, state) {
              if (state is CubitMeasurementLimitLoaded) {
                setState(() {
                  fetchedMLimits = state.measurementLimits;
                });
              } else if (state is CubitMeasurementLimitError) {
                print(state.error);
              }
            },
          ),
          BlocListener<SecondaryUnitCubit, CubitSecondaryUnitStates>(
            listener: (context, state) {
              if (state is CubitSecondaryUnitLoaded) {
                setState(() {
                  fetchedSUnit = state.secondaryUnits;
                });
              } else if (state is CubitSecondaryUnitError) {
                print(state.error);
              }
            },
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: isFetched == true
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .6,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .44,
                                              decoration: const BoxDecoration(
                                                  border: Border(
                                                top: BorderSide(
                                                    width: 1,
                                                    color: Colors.black),
                                                left: BorderSide(
                                                  width: 1,
                                                  color: Colors.black,
                                                ),
                                              )),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: Container(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            .04,
                                                        width: screenWidth < 900
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                .14
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 14, 63, 147),
                                                        child: Text(
                                                          ' BASIC DETAILS',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  screenWidth <
                                                                          1030
                                                                      ? 11.0
                                                                      : 14.0),
                                                        )),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: Text(
                                                                  'Item Group',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        const Color(
                                                                      0xFF510986,
                                                                    ),
                                                                  )),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 9,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    .055,
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                          .black,
                                                                      // Choose the border color you prefer
                                                                      width:
                                                                          1.0, // Adjust the border width
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            0), // Adjust the border radius
                                                                  ),
                                                                  child:
                                                                      DropdownButtonHideUnderline(
                                                                    child: DropdownButton<
                                                                        String>(
                                                                      value:
                                                                          selectedItemId,
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                      underline:
                                                                          Container(),
                                                                      onChanged:
                                                                          (String?
                                                                              newValue) {
                                                                        setState(
                                                                            () {
                                                                          selectedItemId =
                                                                              newValue;
                                                                        });
                                                                      },
                                                                      items: fetchedItemGroups.map(
                                                                          (ItemsGroup
                                                                              itemGroup) {
                                                                        return DropdownMenuItem<
                                                                            String>(
                                                                          value:
                                                                              itemGroup.id,
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                                            child:
                                                                                Text(itemGroup.name),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Item Brand',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            isExpanded:
                                                                                true,
                                                                            value:
                                                                                selectedItemId2,
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            underline:
                                                                                Container(),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedItemId2 = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedItemBrands.map((ItemsBrand itemBrand) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: itemBrand.id,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.0),
                                                                                  child: Text(itemBrand.name),
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Code No',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          TextFormField(
                                                                        enabled:
                                                                            false,
                                                                        controller:
                                                                            controllers.codeNoController,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      NISingleTextField(
                                                        labelText: 'Item Name',
                                                        flex1: 3,
                                                        flex2: 9,
                                                        controller: controllers
                                                            .itemNameController,
                                                      ),
                                                      NISingleTextField(
                                                        labelText: 'Print Name',
                                                        flex1: 3,
                                                        flex2: 9,
                                                        controller: controllers
                                                            .printNameController,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 6,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: Text(
                                                                'Is Discount',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          2.0),
                                                              child: SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    .055,
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          2),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: Colors
                                                                            .black,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              0),
                                                                    ),
                                                                    child:
                                                                        DropdownButtonHideUnderline(
                                                                      child: DropdownButton<
                                                                          String>(
                                                                        isExpanded:
                                                                            true,
                                                                        value:
                                                                            selectedDiscount,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        underline:
                                                                            Container(),
                                                                        onChanged:
                                                                            (String?
                                                                                newValue) {
                                                                          setState(
                                                                              () {
                                                                            controllers.discountController.text =
                                                                                '';
                                                                            selectedDiscount =
                                                                                newValue!;
                                                                          });
                                                                        },
                                                                        items: [
                                                                          'No',
                                                                          'Yes',
                                                                        ].map((String
                                                                            discountSelect) {
                                                                          return DropdownMenuItem<
                                                                              String>(
                                                                            value:
                                                                                discountSelect,
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                                              child: Text(
                                                                                discountSelect,
                                                                                style: const TextStyle(fontSize: 15),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: Text(
                                                                'Discount Rps',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 6,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: SizedBox(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    .055,
                                                                child:
                                                                    TextFormField(
                                                                  enabled:
                                                                      selectedDiscount ==
                                                                          'Yes',
                                                                  controller:
                                                                      controllers
                                                                          .discountController,
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        const Color(
                                                                      0xFF000000,
                                                                    ),
                                                                  ),
                                                                  cursorHeight:
                                                                      21,
                                                                  textAlignVertical:
                                                                      TextAlignVertical
                                                                          .top,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              0),
                                                                      borderSide:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Tax Category',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedTaxRateId,
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            underline:
                                                                                Container(),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedTaxRateId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedTaxCategories.map((TaxRate taxRate) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: taxRate.id,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                                                  child: Text('${taxRate.rate}%'),
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'HSN Code',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedHSNCodeId,
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            underline:
                                                                                Container(),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedHSNCodeId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedHSNCodes.map((HSNCode hsnCode) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: hsnCode.id,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.all(8.0),
                                                                                      child: Text(
                                                                                        hsnCode.hsn,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Spacer(),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Responsive_NewHSNCommodity(),
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                'Add HSN Code',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: SizedBox(
                                                        height: 50,
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed:
                                                              openProductMetadata,
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                              0xFF510986,
                                                            ),
                                                            foregroundColor: Colors
                                                                .white, // foreground  = text color
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                          ),
                                                          label: Text(
                                                            'Add Product Meta Data',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                0xFFFFFFFF,
                                                              ),
                                                            ),
                                                          ),
                                                          icon: const Icon(
                                                              Icons.add),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .65,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .44,
                                              decoration: const BoxDecoration(
                                                  border: Border(
                                                left: BorderSide(
                                                    color: Colors.black),
                                                bottom: BorderSide(
                                                    color: Colors.black),
                                              )),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const DottedLine(
                                                    direction: Axis.horizontal,
                                                    lineLength: double.infinity,
                                                    lineThickness: 1.0,
                                                    dashLength: 4.0,
                                                    dashColor: Colors.black,
                                                    dashRadius: 0.0,
                                                    dashGapLength: 4.0,
                                                    dashGapColor:
                                                        Colors.transparent,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4, top: 4),
                                                    child: Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              .04,
                                                      width: screenWidth < 900
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              .14
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 14, 63, 147),
                                                      child: Text(
                                                        ' STOCK OPTIONS',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                screenWidth <
                                                                        1030
                                                                    ? 11.0
                                                                    : 14.0),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Store Location',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedStoreLocationId,
                                                                            underline:
                                                                                Container(),
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedStoreLocationId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedStores.map((StoreLocation storeLocation) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: storeLocation.id,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.all(8.0),
                                                                                      child: Text(storeLocation.location),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Barcode Sr',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .1,
                                                                      child:
                                                                          TextFormField(
                                                                        enabled:
                                                                            false,
                                                                        controller:
                                                                            controllers.barcodeController,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width: screenWidth *
                                                                0.12,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Responsive_StoreLocation(),
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                'Add Store Location',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Measurement Unit',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedMeasurementLimitId,
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            underline:
                                                                                Container(),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedMeasurementLimitId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedMLimits.map((MeasurementLimit measurementLimit) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: measurementLimit.id,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.all(8.0),
                                                                                      child: Text(measurementLimit.measurement),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Secondary Unit',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                            // Choose the border color you prefer
                                                                            width:
                                                                                1.0, // Adjust the border width
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0), // Adjust the border radius
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedSecondaryUnitId,
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                            underline:
                                                                                Container(),
                                                                            onChanged:
                                                                                (String? newValue) {
                                                                              setState(() {
                                                                                selectedSecondaryUnitId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedSUnit.map((SecondaryUnit secondaryUnit) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: secondaryUnit.id,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.all(8.0),
                                                                                      child: Text(secondaryUnit.secondaryUnit),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  .11),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Responsive_measurementunit(),
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                'Add Measurement Unit',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Responsive_NewItemUnit(),
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                'Add Secondary Unit',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                        'Minimum Stock',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF510986,
                                                                          ),
                                                                        )),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            controllers.minimumStockController,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Maximum Stock',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF510986,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            controllers.maximumStockController,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                        'Monthly Sale Qty',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF510986,
                                                                          ),
                                                                        )),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  flex: 6,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            controllers.monthlySalesQtyController,
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              const Color(
                                                                            0xFF000000,
                                                                          ),
                                                                        ),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Visibility(
                                                              visible: false,
                                                              child: Row(
                                                                children: [
                                                                  const Expanded(
                                                                    flex: 6,
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              4.0),
                                                                      child:
                                                                          Text(
                                                                        'Maximum Stock',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              14,
                                                                              63,
                                                                              147),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    flex: 6,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          4.0),
                                                                      child:
                                                                          SizedBox(
                                                                        height: MediaQuery.of(context).size.height *
                                                                            .055,
                                                                        child:
                                                                            TextFormField(
                                                                          style:
                                                                              const TextStyle(fontWeight: FontWeight.bold),
                                                                          cursorHeight:
                                                                              21,
                                                                          textAlignVertical:
                                                                              TextAlignVertical.top,
                                                                          decoration:
                                                                              InputDecoration(
                                                                            border:
                                                                                OutlineInputBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                              borderSide: const BorderSide(
                                                                                color: Colors.black,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .6,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .44,
                                              decoration: const BoxDecoration(
                                                  border: Border(
                                                      top: BorderSide(
                                                          color: Colors.black),
                                                      right: BorderSide(
                                                          color: Colors.black),
                                                      left: BorderSide(
                                                          color:
                                                              Colors.black))),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4),
                                                    child: Container(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            .04,
                                                        width: screenWidth < 900
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                .14
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 14, 63, 147),
                                                        child: Text(
                                                          ' PRICE DETAILS',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  screenWidth <
                                                                          1030
                                                                      ? 11.0
                                                                      : 14.0),
                                                        )),
                                                  ),
                                                  // NIEditableTable()
                                                  NInewTable(
                                                    dealerController:
                                                        controllers
                                                            .dealerController,
                                                    subDealerController:
                                                        controllers
                                                            .subDealerController,
                                                    retailController:
                                                        controllers
                                                            .retailController,
                                                    mrpController: controllers
                                                        .mrpController,
                                                    dateController: controllers
                                                        .dateController,
                                                    currentPriceController:
                                                        controllers
                                                            .currentPriceController,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .65,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .44,
                                              decoration: const BoxDecoration(
                                                  border: Border(
                                                      right: BorderSide(
                                                        color: Colors.black,
                                                      ),
                                                      bottom: BorderSide(
                                                          color: Colors.black),
                                                      left: BorderSide(
                                                          color:
                                                              Colors.black))),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const DottedLine(
                                                    direction: Axis.horizontal,
                                                    lineLength: double.infinity,
                                                    lineThickness: 1.0,
                                                    dashLength: 4.0,
                                                    dashColor: Colors.black,
                                                    dashRadius: 0.0,
                                                    dashGapLength: 4.0,
                                                    dashGapColor:
                                                        Colors.transparent,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4, top: 4),
                                                    child: Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              .04,
                                                      width: screenWidth < 900
                                                          ? MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              .14
                                                          : MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 14, 63, 147),
                                                      child: Text(
                                                        ' ITEM IMAGES',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                screenWidth <
                                                                        1030
                                                                    ? 11.0
                                                                    : 14.0),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              'Update Image ? :',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                                color:
                                                                    const Color(
                                                                  0xFF510986,
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  .01,
                                                            ),
                                                            SizedBox(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    .13,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    .055,
                                                                child:
                                                                    TextField(
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        const Color(
                                                                      0xFF000000,
                                                                    ),
                                                                  ),
                                                                  cursorHeight:
                                                                      21,
                                                                  textAlignVertical:
                                                                      TextAlignVertical
                                                                          .top,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ))
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            .01,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 8),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.29,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.22,
                                                              child: _selectedImagesBytes
                                                                      .isEmpty
                                                                  ? const Center(
                                                                      child: Text(
                                                                          'No Image Selected'))
                                                                  : GridView
                                                                      .builder(
                                                                      gridDelegate:
                                                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                                                        crossAxisCount:
                                                                            3,
                                                                        crossAxisSpacing:
                                                                            4.0,
                                                                        mainAxisSpacing:
                                                                            4.0,
                                                                      ),
                                                                      itemCount:
                                                                          _selectedImagesBytes
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        return Image
                                                                            .memory(
                                                                          _selectedImagesBytes[
                                                                              index],
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        );
                                                                      },
                                                                    ),
                                                            ),
                                                            Column(
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      FilePickerResult?
                                                                          result =
                                                                          await FilePicker
                                                                              .platform
                                                                              .pickFiles(
                                                                        type: FileType
                                                                            .custom,
                                                                        allowedExtensions: [
                                                                          'jpg',
                                                                          'jpeg',
                                                                          'png',
                                                                          'gif'
                                                                        ],
                                                                        allowMultiple:
                                                                            true, // Allow multiple file selection
                                                                      );

                                                                      if (result !=
                                                                          null) {
                                                                        List<Uint8List>
                                                                            fileBytesList =
                                                                            [];
                                                                        List<String>
                                                                            fileUrlsList =
                                                                            [];

                                                                        for (PlatformFile file
                                                                            in result.files) {
                                                                          Uint8List
                                                                              fileBytes =
                                                                              file.bytes!;
                                                                          fileBytesList
                                                                              .add(fileBytes);
                                                                          fileUrlsList
                                                                              .add(file.name); // Store file names for preview
                                                                        }

                                                                        setState(
                                                                            () {
                                                                          _selectedImagesBytes
                                                                              .addAll(fileBytesList);
                                                                          _selectedImageUrls =
                                                                              fileUrlsList; // Update with file names or URLs
                                                                        });

                                                                        _showImageDialog(
                                                                            context,
                                                                            fileBytesList);
                                                                      } else {
                                                                        print(
                                                                            'File picking canceled by the user.');
                                                                      }
                                                                    },
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .black,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      fixedSize: Size(
                                                                          buttonWidth,
                                                                          buttonHeight),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0),
                                                                      ),
                                                                      side:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      'Add',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {},
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .black,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      fixedSize: Size(
                                                                          buttonWidth,
                                                                          buttonHeight),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0),
                                                                      ),
                                                                      side:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    child: Center(
                                                                        child: Text(
                                                                      'Delete',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                    )),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {},
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .black,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      fixedSize: Size(
                                                                          buttonWidth,
                                                                          buttonHeight),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0),
                                                                      ),
                                                                      side:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      'Next',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {},
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .black,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      fixedSize: Size(
                                                                          buttonWidth,
                                                                          buttonHeight),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0),
                                                                      ),
                                                                      side:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      'Previous',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {},
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .black,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      fixedSize: Size(
                                                                          buttonWidth,
                                                                          buttonHeight),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(0),
                                                                      ),
                                                                      side:
                                                                          const BorderSide(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      'Zoom',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            const Color(
                                                                          0xFF000000,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        // Map the selected images and return a list of image widgets
                                                        children: [
                                                          for (int i = 0;
                                                              i <
                                                                  _selectedImages
                                                                      .length;
                                                              i++)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0),
                                                              child: Column(
                                                                children: [
                                                                  ImageNetwork(
                                                                    image:
                                                                        _selectedImages[
                                                                            i],
                                                                    height: 100,
                                                                    width: 100,
                                                                    duration:
                                                                        300,
                                                                    curve: Curves
                                                                        .easeIn,
                                                                    onPointer:
                                                                        true,
                                                                    debugPrint:
                                                                        false,
                                                                    fullScreen:
                                                                        false,
                                                                    fitAndroidIos:
                                                                        BoxFit
                                                                            .cover,
                                                                    fitWeb:
                                                                        BoxFitWeb
                                                                            .cover,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            70),
                                                                    onLoading:
                                                                        const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .indigoAccent,
                                                                    ),
                                                                    onError:
                                                                        const Icon(
                                                                      Icons
                                                                          .error,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                    onTap: () {
                                                                      debugPrint(
                                                                          "©gabriel_patrick_souza");
                                                                    },
                                                                  ),

                                                                  // Text Button, with text Delete
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                        () {
                                                                          _selectedImages
                                                                              .removeAt(i);
                                                                        },
                                                                      );
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      'Delete',
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.red),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                        ]),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              .1,
                                      width: MediaQuery.of(context).size.width *
                                          .88,
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              right: BorderSide(
                                                color: Colors.black,
                                              ),
                                              bottom: BorderSide(
                                                color: Colors.black,
                                              ),
                                              left: BorderSide(
                                                  color: Colors.black))),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Opening Stock (F7) :',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: const Color(
                                                  0xFF510986,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .01,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .13,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .055,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    // Choose the border color you prefer
                                                    width:
                                                        1.0, // Adjust the border width
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          0), // Adjust the border radius
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: selectedStock,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFF000000,
                                                      ),
                                                    ),
                                                    underline: Container(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        selectedStock =
                                                            newValue!;
                                                      });
                                                    },
                                                    items: stock
                                                        .map((String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text(value),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .03,
                                            ),
                                            Text(
                                              'Is Active :',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: const Color(
                                                  0xFF510986,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .01,
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .13,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .055,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    // Choose the border color you prefer
                                                    width:
                                                        1.0, // Adjust the border width
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          0), // Adjust the border radius
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: selectedStatus,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFF000000,
                                                      ),
                                                    ),
                                                    underline: Container(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        selectedStatus =
                                                            newValue!;
                                                      });
                                                    },
                                                    items: status
                                                        .map((String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text(value),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .01,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          fixedSize: Size(
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  .1,
                                                              25),
                                                          shape: const BeveledRectangleBorder(
                                                              side: BorderSide(
                                                                  color: Colors
                                                                      .black,
                                                                  width: .3)),
                                                          backgroundColor:
                                                              Colors.yellow
                                                                  .shade100),
                                                      onPressed: createItems,
                                                      child: Text(
                                                        'Save [F4]',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: const Color(
                                                            0xFF000000,
                                                          ),
                                                        ),
                                                      )),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .002,
                                                  ),
                                                  ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          fixedSize: Size(
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  .1,
                                                              25),
                                                          shape: const BeveledRectangleBorder(
                                                              side: BorderSide(
                                                                  color: Colors
                                                                      .black,
                                                                  width: .3)),
                                                          backgroundColor:
                                                              Colors.yellow
                                                                  .shade100),
                                                      onPressed: () {},
                                                      child: Text(
                                                        'Cancel',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: const Color(
                                                            0xFF000000,
                                                          ),
                                                        ),
                                                      )),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .002,
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        fixedSize: Size(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                .1,
                                                            25),
                                                        shape:
                                                            const BeveledRectangleBorder(
                                                                side: BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: .3)),
                                                        backgroundColor: Colors
                                                            .yellow.shade100),
                                                    onPressed: () {
                                                      final TextEditingController
                                                          catNameController =
                                                          TextEditingController();

                                                      final TextEditingController
                                                          catDescController =
                                                          TextEditingController();

                                                      List<Uint8List>
                                                          selectedImage = [];

                                                      Alert(
                                                          context: context,
                                                          title:
                                                              "ADD ITEM GROUP",
                                                          content:
                                                              StatefulBuilder(
                                                            builder: (BuildContext
                                                                    context,
                                                                StateSetter
                                                                    setState) {
                                                              return Column(
                                                                children: <Widget>[
                                                                  TextField(
                                                                    controller:
                                                                        catNameController,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .category),
                                                                      labelText:
                                                                          'Category Name',
                                                                    ),
                                                                  ),
                                                                  TextField(
                                                                    controller:
                                                                        catDescController,
                                                                    obscureText:
                                                                        false,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .description),
                                                                      labelText:
                                                                          'Category Description',
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Stack(
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            200,
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.4,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.white10,
                                                                          border: Border.all(
                                                                              color: Colors.black,
                                                                              width: 2),
                                                                        ),
                                                                        child: selectedImage.isEmpty
                                                                            ? const Center(child: Text('No Image Selected'))
                                                                            : Image.memory(selectedImage[0]),
                                                                      ),
                                                                      Positioned(
                                                                        top:
                                                                            150,
                                                                        right:
                                                                            -10,
                                                                        left: 0,
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () async {
                                                                            FilePickerResult?
                                                                                result =
                                                                                await FilePicker.platform.pickFiles(
                                                                              type: FileType.custom,
                                                                              allowedExtensions: [
                                                                                'jpg',
                                                                                'jpeg',
                                                                                'png',
                                                                                'gif'
                                                                              ],
                                                                            );

                                                                            if (result !=
                                                                                null) {
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
                                                                          child:
                                                                              MouseRegion(
                                                                            cursor:
                                                                                SystemMouseCursors.click,
                                                                            child:
                                                                                SizedBox(
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
                                                              color: Colors
                                                                  .yellow
                                                                  .shade100,
                                                              onPressed: () {
                                                                itemsGroup
                                                                    .createItemsGroup(
                                                                  name:
                                                                      catNameController
                                                                          .text,
                                                                  desc:
                                                                      catDescController
                                                                          .text,
                                                                  images: '',
                                                                );

                                                                _fetchData();

                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                "CREATE",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ),
                                                            DialogButton(
                                                              color: Colors
                                                                  .yellow
                                                                  .shade100,
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: const Text(
                                                                "CANCEL",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ),
                                                          ]).show();
                                                    },
                                                    child: Text(
                                                      'ADD GROUP',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: const Color(
                                                          0xFF000000,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .002,
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        fixedSize: Size(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                .1,
                                                            25),
                                                        shape:
                                                            const BeveledRectangleBorder(
                                                                side: BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: .3)),
                                                        backgroundColor: Colors
                                                            .yellow.shade100),
                                                    onPressed: () {
                                                      final TextEditingController
                                                          catNameController =
                                                          TextEditingController();
                                                      final TextEditingController
                                                          catBrandController =
                                                          TextEditingController();

                                                      final TextEditingController
                                                          catDescController =
                                                          TextEditingController();

                                                      List<Uint8List>
                                                          selectedImage = [];

                                                      Alert(
                                                          context: context,
                                                          title: "ADD BRAND",
                                                          content:
                                                              StatefulBuilder(
                                                            builder: (BuildContext
                                                                    context,
                                                                StateSetter
                                                                    setState) {
                                                              return Column(
                                                                children: <Widget>[
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  TextField(
                                                                    controller:
                                                                        catBrandController,
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .category),
                                                                      labelText:
                                                                          'Brand Name',
                                                                    ),
                                                                  ),
                                                                  // TextField(
                                                                  //   controller:
                                                                  //       catDescController,
                                                                  //   obscureText:
                                                                  //       false,
                                                                  //   decoration:
                                                                  //       const InputDecoration(
                                                                  //     icon: Icon(Icons
                                                                  //         .description),
                                                                  //     labelText:
                                                                  //         'Category Description',
                                                                  //   ),
                                                                  // ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  // Stack(
                                                                  //   children: [
                                                                  //     Container(
                                                                  //       height: 200,
                                                                  //       width: MediaQuery.of(context)
                                                                  //               .size
                                                                  //               .width *
                                                                  //           0.4,
                                                                  //       decoration:
                                                                  //           BoxDecoration(
                                                                  //         color: Colors
                                                                  //             .white10,
                                                                  //         border: Border.all(
                                                                  //             color: Colors
                                                                  //                 .black,
                                                                  //             width:
                                                                  //                 2),
                                                                  //       ),
                                                                  //       child: selectedImage
                                                                  //               .isEmpty
                                                                  //           ? const Center(
                                                                  //               child: Text(
                                                                  //                   'No Image Selected'))
                                                                  //           : Image.memory(
                                                                  //               selectedImage[0]),
                                                                  //     ),
                                                                  //     Positioned(
                                                                  //       top: 150,
                                                                  //       right: -10,
                                                                  //       left: 0,
                                                                  //       child:
                                                                  //           GestureDetector(
                                                                  //         onTap:
                                                                  //             () async {
                                                                  //           FilePickerResult?
                                                                  //               result =
                                                                  //               await FilePicker.platform.pickFiles(
                                                                  //             type:
                                                                  //                 FileType.custom,
                                                                  //             allowedExtensions: [
                                                                  //               'jpg',
                                                                  //               'jpeg',
                                                                  //               'png',
                                                                  //               'gif'
                                                                  //             ],
                                                                  //           );

                                                                  //           if (result !=
                                                                  //               null) {
                                                                  //             List<Uint8List>
                                                                  //                 fileBytesList =
                                                                  //                 [];

                                                                  //             for (PlatformFile file
                                                                  //                 in result.files) {
                                                                  //               Uint8List
                                                                  //                   fileBytes =
                                                                  //                   file.bytes!;
                                                                  //               fileBytesList.add(fileBytes);
                                                                  //             }

                                                                  //             setState(
                                                                  //                 () {
                                                                  //               selectedImage.addAll(fileBytesList);
                                                                  //             });

                                                                  //             // print(_selectedImages);
                                                                  //           } else {
                                                                  //             // User canceled the picker
                                                                  //             print(
                                                                  //                 'File picking canceled by the user.');
                                                                  //           }
                                                                  //         },
                                                                  //         child:
                                                                  //             MouseRegion(
                                                                  //           cursor:
                                                                  //               SystemMouseCursors.click,
                                                                  //           child:
                                                                  //               SizedBox(
                                                                  //             height:
                                                                  //                 50,
                                                                  //             child:
                                                                  //                 CircleAvatar(
                                                                  //               radius:
                                                                  //                   50,
                                                                  //               backgroundColor:
                                                                  //                   Colors.yellow.shade100,
                                                                  //               child:
                                                                  //                   const Icon(Icons.upload),
                                                                  //             ),
                                                                  //           ),
                                                                  //         ),
                                                                  //       ),
                                                                  //     )
                                                                  //   ],
                                                                  // ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                          buttons: [
                                                            DialogButton(
                                                              color: Colors
                                                                  .yellow
                                                                  .shade100,
                                                              onPressed: () {
                                                                itemsBrand
                                                                    .createItemBrand(
                                                                  name:
                                                                      catBrandController
                                                                          .text,
                                                                  images: '',
                                                                );

                                                                _fetchData();

                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                "CREATE",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ),
                                                            DialogButton(
                                                              color: Colors
                                                                  .yellow
                                                                  .shade100,
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: const Text(
                                                                "CANCEL",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ),
                                                          ]).show();
                                                    },
                                                    child: Text(
                                                      'ADD BRAND',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: const Color(
                                                          0xFF000000,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
