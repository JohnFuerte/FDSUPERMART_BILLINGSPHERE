// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:billingsphere/data/models/brand/item_brand_model.dart';
import 'package:billingsphere/data/models/hsn/hsn_model.dart';
import 'package:billingsphere/data/models/itemGroup/item_group_model.dart';
import 'package:billingsphere/data/models/measurementLimit/measurement_limit_model.dart';
import 'package:billingsphere/data/models/secondaryUnit/secondary_unit_model.dart';
import 'package:billingsphere/data/models/storeLocation/store_location_model.dart';
import 'package:billingsphere/data/models/taxCategory/tax_category_model.dart';
import 'package:billingsphere/data/repository/item_brand_repository.dart';
import 'package:billingsphere/data/repository/item_repository.dart';
import 'package:billingsphere/logic/cubits/itemBrand_cubit/itemBrand_state.dart';
import 'package:billingsphere/logic/cubits/itemGroup_cubit/itemGroup_cubit.dart';
import 'package:billingsphere/utils/controllers/items_text_controllers.dart';
import 'package:billingsphere/views/NI_widgets/NI_new_table.dart';
import 'package:billingsphere/views/NI_widgets/NI_singleTextField.dart';
import 'package:billingsphere/views/sumit_screen/measurement_unit/measurement_unit.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/item/item_model.dart';
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
import '../item_brand_edit.dart';
import '../sumit_screen/hsn_code/hsn_code.dart';
import '../sumit_screen/secondary_unit/secondary_unit.dart';

class NIMyDesktopBody extends StatefulWidget {
  const NIMyDesktopBody({super.key});

  @override
  State<NIMyDesktopBody> createState() => _BasicDetailsState();
}

class _BasicDetailsState extends State<NIMyDesktopBody> {
  List<List<String>> tableData = [
    // Initial data for the table
    ["Header 1", "Header 2", "Header 3"],
    ["Data 1", "Data 2", "Data 3"],
  ];
  ItemsGroupService itemsGroup = ItemsGroupService();
  ItemsBrandsService itemsBrand = ItemsBrandsService();
  ItemsFormControllers controllers = ItemsFormControllers();
  TextEditingController overviewController = TextEditingController();

  bool _isSaving = false;
  ItemsService items = ItemsService();
  String selectedDiscount = 'No';

  List<String> imageUrls = [];
  List<Uint8List> _selectedImages = [];
  int _currentIndex = 0; // Track the current image being displayed
  final int maxImages = 4;
  // Map to save metadata of the product
  Map<String, dynamic> productMetadata = {};
  var savedItem;
  Widget _displayImage() {
    if (_selectedImages.isEmpty) {
      return const Center(child: Text('Image 1 not selected'));
    } else if (_currentIndex >= _selectedImages.length) {
      return Center(child: Text('Image ${_currentIndex + 1} not selected'));
    } else {
      return Image.memory(_selectedImages[_currentIndex]);
    }
  }

  List<String>? companyCode;
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

  // void createItems() async {
  //   setState(() {
  //     _isSaving = true;
  //   });

  //   List<ImageData>? imageList;
  //   if (_selectedImages.isNotEmpty) {
  //     imageList = _selectedImages
  //         .map((image) => ImageData(
  //               data: image,
  //               contentType: 'image/jpeg',
  //               filename: 'filename.jpg',
  //             ))
  //         .toList();
  //   }

  //   items
  //       .createItem(
  //     itemGroup: selectedItemId!,
  //     companyCode: companyCode!.first,
  //     itemBrand: selectedItemId2!,
  //     itemName: controllers.itemNameController.text,
  //     printName: controllers.printNameController.text,
  //     codeNo: controllers.codeNoController.text,
  //     taxCategory: selectedTaxRateId!,
  //     hsnCode: selectedHSNCodeId!,
  //     barcode: controllers.barcodeController.text,
  //     storeLocation: selectedStoreLocationId!,
  //     measurementUnit: selectedMeasurementLimitId!,
  //     secondaryUnit: selectedSecondaryUnitId!,
  //     minimumStock:
  //         int.tryParse(controllers.minimumStockController.text.trim()) ?? 0,
  //     maximumStock:
  //         int.tryParse(controllers.maximumStockController.text.trim()) ?? 0,
  //     monthlySalesQty:
  //         int.tryParse(controllers.monthlySalesQtyController.text.trim()) ?? 0,
  //     dealer: double.parse(controllers.dealerController.text),
  //     subDealer: double.parse(controllers.subDealerController.text),
  //     retail: double.parse(controllers.retailController.text),
  //     mrp: double.parse(controllers.mrpController.text),
  //     openingStock: selectedStock,
  //     status: selectedStatus,
  //     context: context,
  //     date: controllers.dateController.text,
  //     images: imageList ?? [],
  //   )
  //       .then(
  //     (value) {
  //       uploadImageToFirebase(_selectedImages.first).then((imageUrl) {});
  //     },
  //   );

  //   controllers.itemNameController.clear();
  //   controllers.printNameController.clear();
  //   controllers.codeNoController.clear();
  //   controllers.minimumStockController.clear();
  //   controllers.maximumStockController.clear();
  //   controllers.monthlySalesQtyController.clear();
  //   controllers.dealerController.clear();
  //   controllers.subDealerController.clear();
  //   controllers.retailController.clear();
  //   controllers.mrpController.clear();
  //   controllers.openingStockController.clear();
  //   controllers.barcodeController.clear();
  //   controllers.dateController.clear();
  //   selectedItemId = fetchedItemGroups.first.id;
  //   selectedItemId2 = fetchedItemBrands.first.id;
  //   selectedTaxRateId = fetchedTaxCategories.first.id;
  //   selectedHSNCodeId = fetchedHSNCodes.first.id;
  //   selectedStoreLocationId = fetchedStores.first.id;
  //   selectedMeasurementLimitId = fetchedMLimits.first.id;
  //   selectedSecondaryUnitId = fetchedSUnit.first.id;
  //   imageList = [];
  //   _selectedImages = [];
  //   selectedStatus = 'Active';
  //   selectedStock = 'Yes';
  //   _generateRandomNumber();

  //   await Future.delayed(const Duration(seconds: 2));

  //   setState(() {
  //     _isSaving = false;
  //   });
  // }
  Future<List<String>> uploadImagesToFirebase(List<Uint8List> imageDataList,
      TextEditingController itemNameController) async {
    const String placeholderUrl =
        'https://img.freepik.com/free-vector/illustration-gallery-icon_53876-27002.jpg'; // Placeholder image URL

    if (imageDataList.isEmpty) {
      print("No image data found");
      return [placeholderUrl];
    }

    FirebaseStorage storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];
    String itemName = itemNameController.text.replaceAll(
        RegExp(r'[^a-zA-Z0-9_]'), '_'); // Clean the item name for folder naming

    for (var imageData in imageDataList) {
      try {
        // Create a unique reference for each image within the item's folder
        Reference ref = storage.ref().child(
            'itemImages/$itemName/${DateTime.now().millisecondsSinceEpoch}.png');
        UploadTask uploadTask = ref.putData(imageData);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image: $e");
        // Optionally, you can add the placeholder URL in case of an error
        downloadUrls.add(placeholderUrl);
      }
    }

    return downloadUrls;
  }

  void createItems() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Upload image if any selected
      if (_selectedImages.isNotEmpty) {
        List<Uint8List> imageDataList =
            _selectedImages.map((image) => image).toList();
        imageUrls = await uploadImagesToFirebase(
            imageDataList, controllers.itemNameController);
      }

      if (productMetadataObject == null) {
        PanaraInfoDialog.show(
          context,
          title: "BillingSphere",
          message: "Please fill in the product metadata",
          buttonText: "Okay",
          onTapDismiss: () {
            Navigator.pop(context);
          },
          panaraDialogType: PanaraDialogType.warning,
          barrierDismissible: false, // optional parameter (default is true)
        );
        return;
      }

      // Create the item in the primary database
      await items.createItem(
        itemGroup: selectedItemId!,
        companyCode: companyCode!.first,
        itemBrand: selectedItemId2!,
        itemName: controllers.itemNameController.text,
        printName: controllers.printNameController.text,
        codeNo: controllers.codeNoController.text,
        taxCategory: selectedTaxRateId!,
        hsnCode: selectedHSNCodeId!,
        barcode: controllers.barcodeController.text,
        storeLocation: selectedStoreLocationId!,
        measurementUnit: selectedMeasurementLimitId!,
        secondaryUnit: selectedSecondaryUnitId!,
        minimumStock: _parseInt(controllers.minimumStockController.text.trim()),
        maximumStock: _parseInt(controllers.maximumStockController.text.trim()),
        monthlySalesQty:
            _parseInt(controllers.monthlySalesQtyController.text.trim()),
        dealer: _parseDouble(controllers.dealerController.text),
        subDealer: _parseDouble(controllers.subDealerController.text),
        retail: _parseDouble(controllers.retailController.text),
        mrp: _parseDouble(controllers.mrpController.text),
        openingStock: selectedStock,
        status: selectedStatus,
        context: context,
        productMetadata: productMetadataObject!,
        date: controllers.dateController.text,
        images: imageUrls,
        discountAmount: double.parse(controllers.discountController.text),
      );

      print('Item created successfully');
      _resetControllersAndSelections();
    } catch (error) {
      print("Error saving item: $error");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

// Helper method to parse integers with a fallback
  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

// Helper method to parse doubles
  double _parseDouble(String value) {
    return double.parse(value);
  }

// Method to reset all controllers and selected values
  void _resetControllersAndSelections() {
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
    _generateRandomNumber();
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
  int _generatedNumber = 0;
  Random random = Random();
  bool isFetched = false;

  ProductMetadata? productMetadataObject;

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

  void _generateRandomNumber() {
    setState(() {
      int seed = DateTime.now().millisecondsSinceEpoch;
      Random random = Random(seed);
      _generatedNumber = random.nextInt(900) + 100;
      controllers.codeNoController.text = _generatedNumber.toString();
    });
  }

  void _generateBarcode() {
    setState(() {
      int firstPart = Random().nextInt(1000000000);
      int secondPart = Random().nextInt(1000);
      _generatedNumber = int.parse('$firstPart$secondPart');
      controllers.barcodeController.text = _generatedNumber.toString();
    });
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchData(),
      setCompanyCode(),
    ]);
  }

  void _initControllers() {
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    controllers.dateController.text = formattedDate;
    controllers.maximumStockController.text = '0';
    controllers.minimumStockController.text = '0';
    controllers.monthlySalesQtyController.text = '0';
    controllers.dealerController.text = '0';
    controllers.subDealerController.text = '0';
    controllers.retailController.text = '0';
    controllers.mrpController.text = '0';
    controllers.currentPriceController.text = '0.0';
  }

  void _allDataInit() {
    _initializeData();
    _generateRandomNumber();
    _generateBarcode();
    _initControllers();

    productFeaturesWidget.add(MetadataTextfield(
      maxLines: 1,
      controller: TextEditingController(),
    ));
    productIngredientsWidget.add(MetadataTextfield(
      maxLines: 1,
      controller: TextEditingController(),
    ));
    productBenefitsWidget.add(MetadataTextfield(
      maxLines: 1,
      controller: TextEditingController(),
    ));
  }

  @override
  void initState() {
    _allDataInit();
    super.initState();
  }

  // Method to fetch data from Cubits
  Future<void> _fetchData() async {
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

    return _isSaving
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              title:
                  const Text('NEW ITEM', style: TextStyle(color: Colors.white)),
              centerTitle: true,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: () {
                    _fetchData();
                  },
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),
            body: MultiBlocListener(
              listeners: [
                BlocListener<ItemBrandCubit, CubitItemBrandStates>(
                  listener: (context, state) {
                    if (state is CubitItemBrandLoaded) {
                      setState(() {
                        fetchedItemBrands = state.itemBrands;
                        selectedItemId2 = fetchedItemBrands.first.id;
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
                        selectedItemId = fetchedItemGroups.first.id;
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
                        selectedTaxRateId = fetchedTaxCategories.first.id;
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
                        selectedHSNCodeId = fetchedHSNCodes.first.id;
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
                        selectedStoreLocationId = fetchedStores.first.id;
                      });
                    } else if (state is CubitStoreError) {
                      print(state.error);
                    }
                  },
                ),
                BlocListener<MeasurementLimitCubit,
                    CubitMeasurementLimitStates>(
                  listener: (context, state) {
                    if (state is CubitMeasurementLimitLoaded) {
                      setState(() {
                        fetchedMLimits = state.measurementLimits;
                        selectedMeasurementLimitId = fetchedMLimits.first.id;
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
                        selectedSecondaryUnitId = fetchedSUnit.first.id;
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
                                          const Row(
                                            children: [
                                              // Give me 5 buttons in a row
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Column(
                                                children: [
                                                  Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .6,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .44,
                                                    decoration:
                                                        const BoxDecoration(
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
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
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
                                                              color: const Color(
                                                                  0xFF510986),
                                                              child: Text(
                                                                ' BASIC DETAILS',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: screenWidth <
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
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Item Group',
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
                                                                  flex: 9,
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
                                                                                Colors.black, // Choose the border color you prefer
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
                                                                                selectedItemId,
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
                                                                                selectedItemId = newValue;
                                                                              });
                                                                            },
                                                                            items:
                                                                                fetchedItemGroups.map((ItemsGroup itemGroup) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: itemGroup.id,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                                                  child: Text(itemGroup.name),
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
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            2.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                2),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            border:
                                                                                Border.all(
                                                                              color: Colors.black,
                                                                              width: 1.0,
                                                                            ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                          ),
                                                                          child:
                                                                              DropdownButtonHideUnderline(
                                                                            child:
                                                                                DropdownButton<String>(
                                                                              isExpanded: true,
                                                                              value: selectedItemId2,
                                                                              style: GoogleFonts.poppins(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 14,
                                                                                color: const Color(
                                                                                  0xFF000000,
                                                                                ),
                                                                              ),
                                                                              underline: Container(),
                                                                              onChanged: (String? newValue) {
                                                                                setState(() {
                                                                                  selectedItemId2 = newValue;
                                                                                });
                                                                              },
                                                                              items: fetchedItemBrands.map((ItemsBrand itemBrand) {
                                                                                return DropdownMenuItem<String>(
                                                                                  value: itemBrand.id,
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                                                    child: Text(
                                                                                      itemBrand.name,
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
                                                                            true,
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
                                                            NISingleTextField(
                                                              labelText:
                                                                  'Item Name',
                                                              flex1: 3,
                                                              flex2: 9,
                                                              controller:
                                                                  controllers
                                                                      .itemNameController,
                                                            ),
                                                            NISingleTextField(
                                                              labelText:
                                                                  'Print Name',
                                                              flex1: 3,
                                                              flex2: 9,
                                                              controller:
                                                                  controllers
                                                                      .printNameController,
                                                            ),
                                                            Row(
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
                                                                      'Is Discount',
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
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            2.0),
                                                                    child:
                                                                        SizedBox(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          .055,
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                2),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            border:
                                                                                Border.all(
                                                                              color: Colors.black,
                                                                              width: 1.0,
                                                                            ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                          ),
                                                                          child:
                                                                              DropdownButtonHideUnderline(
                                                                            child:
                                                                                DropdownButton<String>(
                                                                              isExpanded: true,
                                                                              value: selectedDiscount,
                                                                              style: GoogleFonts.poppins(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 14,
                                                                                color: const Color(
                                                                                  0xFF000000,
                                                                                ),
                                                                              ),
                                                                              underline: Container(),
                                                                              onChanged: (String? newValue) {
                                                                                setState(() {
                                                                                  controllers.discountController.text = '';
                                                                                  selectedDiscount = newValue!;
                                                                                });
                                                                              },
                                                                              items: [
                                                                                'No',
                                                                                'Yes',
                                                                              ].map((String discountSelect) {
                                                                                return DropdownMenuItem<String>(
                                                                                  value: discountSelect,
                                                                                  child: Padding(
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
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      'Discount Rps',
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
                                                                            selectedDiscount ==
                                                                                'Yes',
                                                                        controller:
                                                                            controllers.discountController,
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
                                                            Row(
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
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0),
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
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0),
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
                                                            Row(
                                                              children: [
                                                                const Spacer(),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child:
                                                                      InkWell(
                                                                    onTap: () {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              const Responsive_NewHSNCommodity(),
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      'Add HSN Code',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            12,
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
                                                        // Button......
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: SizedBox(
                                                              height: 50,
                                                              child:
                                                                  ElevatedButton
                                                                      .icon(
                                                                onPressed:
                                                                    openProductMetadata,
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      const Color(
                                                                    0xFF510986,
                                                                  ),
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white, // foreground  = text color
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(6),
                                                                  ),
                                                                ),
                                                                label: Text(
                                                                  'Add Product Meta Data',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
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
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .65,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .44,
                                                    decoration:
                                                        const BoxDecoration(
                                                            border: Border(
                                                      left: BorderSide(
                                                          color: Colors.black),
                                                      bottom: BorderSide(
                                                          color: Colors.black),
                                                    )),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const DottedLine(
                                                          direction:
                                                              Axis.horizontal,
                                                          lineLength:
                                                              double.infinity,
                                                          lineThickness: 1.0,
                                                          dashLength: 4.0,
                                                          dashColor:
                                                              Colors.black,
                                                          dashRadius: 0.0,
                                                          dashGapLength: 4.0,
                                                          dashGapColor: Colors
                                                              .transparent,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 4,
                                                                  top: 4),
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
                                                            color: const Color(
                                                                0xFF510986),
                                                            child: Text(
                                                              ' STOCK OPTIONS',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
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
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0),
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
                                                                          .055,
                                                                      child:
                                                                          TextFormField(
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
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          focusedBorder:
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
                                                            Row(
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
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0),
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedMeasurementLimitId,
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
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(0),
                                                                        ),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownButton<String>(
                                                                            value:
                                                                                selectedSecondaryUnitId,
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
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        .11),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        InkWell(
                                                                      onTap:
                                                                          () {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                const Responsive_measurementunit(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Add Measurement Unit',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              const Color(
                                                                            0xFF510986,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child:
                                                                      InkWell(
                                                                    onTap: () {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              const Responsive_NewItemUnit(),
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      'Add Secondary Unit',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            12,
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
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          focusedBorder:
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
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          focusedBorder:
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
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.11,
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
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.11,
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
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          focusedBorder:
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
                                                                Visibility(
                                                                  visible:
                                                                      false,
                                                                  child:
                                                                      Expanded(
                                                                    flex: 3,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          4.0),
                                                                      child:
                                                                          Text(
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
                                                                ),
                                                                Visibility(
                                                                  visible:
                                                                      false,
                                                                  child:
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
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .6,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .44,
                                                    decoration: const BoxDecoration(
                                                        border: Border(
                                                            top: BorderSide(
                                                                color: Colors
                                                                    .black),
                                                            right: BorderSide(
                                                                color: Colors
                                                                    .black),
                                                            left: BorderSide(
                                                                color: Colors
                                                                    .black))),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
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
                                                              color: const Color(
                                                                  0xFF510986),
                                                              child: Text(
                                                                ' PRICE DETAILS',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: screenWidth <
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
                                                          mrpController:
                                                              controllers
                                                                  .mrpController,
                                                          dateController:
                                                              controllers
                                                                  .dateController,
                                                          currentPriceController:
                                                              controllers
                                                                  .currentPriceController,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .65,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .44,
                                                    decoration:
                                                        const BoxDecoration(
                                                            border: Border(
                                                                right:
                                                                    BorderSide(
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                bottom: BorderSide(
                                                                    color: Colors
                                                                        .black),
                                                                left: BorderSide(
                                                                    color: Colors
                                                                        .black))),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const DottedLine(
                                                          direction:
                                                              Axis.horizontal,
                                                          lineLength:
                                                              double.infinity,
                                                          lineThickness: 1.0,
                                                          dashLength: 4.0,
                                                          dashColor:
                                                              Colors.black,
                                                          dashRadius: 0.0,
                                                          dashGapLength: 4.0,
                                                          dashGapColor: Colors
                                                              .transparent,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 4,
                                                                  top: 4),
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
                                                              color: const Color(
                                                                  0xFF510986),
                                                              child: Text(
                                                                ' ITEM IMAGES',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: screenWidth <
                                                                            1030
                                                                        ? 11.0
                                                                        : 14.0),
                                                              )),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
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
                                                                      fontSize:
                                                                          14,
                                                                      color:
                                                                          const Color(
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
                                                                      child:
                                                                          TextField(
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        cursorHeight:
                                                                            21,
                                                                        textAlignVertical:
                                                                            TextAlignVertical.top,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          border:
                                                                              const OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          focusedBorder:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0),
                                                                            borderSide:
                                                                                const BorderSide(
                                                                              color: Colors.black,
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
                                                                      .only(
                                                                      left: 8),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                            border:
                                                                                Border.all(color: Colors.black)),
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .height *
                                                                        0.29,
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.22,
                                                                    child:
                                                                        _displayImage(),
                                                                  ),
                                                                  Column(
                                                                    children: [
                                                                      // Image selection buttons
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            1.0),
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (_selectedImages.length >=
                                                                                maxImages) {
                                                                              // Show message if max images are selected
                                                                              Fluttertoast.showToast(msg: "You can only select $maxImages images.");
                                                                              return;
                                                                            }

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
                                                                                _selectedImages.addAll(fileBytesList);
                                                                              });
                                                                            } else {
                                                                              print('File picking canceled by the user.');
                                                                            }
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.black,
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            fixedSize:
                                                                                Size(buttonWidth, buttonHeight),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                            ),
                                                                            side:
                                                                                const BorderSide(color: Colors.black),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Add',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            1.0),
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              if (_selectedImages.isNotEmpty) {
                                                                                _selectedImages.removeAt(_currentIndex);
                                                                                if (_currentIndex >= _selectedImages.length) {
                                                                                  _currentIndex = _selectedImages.length - 1;
                                                                                }
                                                                              }
                                                                            });
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.black,
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            fixedSize:
                                                                                Size(buttonWidth, buttonHeight),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                            ),
                                                                            side:
                                                                                const BorderSide(color: Colors.black),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Delete',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            1.0),
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              if (_currentIndex < _selectedImages.length - 1) {
                                                                                _currentIndex++;
                                                                              }
                                                                            });
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.black,
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            fixedSize:
                                                                                Size(buttonWidth, buttonHeight),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                            ),
                                                                            side:
                                                                                const BorderSide(color: Colors.black),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Next',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            1.0),
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              if (_currentIndex > 0) {
                                                                                _currentIndex--;
                                                                              }
                                                                            });
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.black,
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            fixedSize:
                                                                                Size(buttonWidth, buttonHeight),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                            ),
                                                                            side:
                                                                                const BorderSide(color: Colors.black),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Previous',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            1.0),
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            // Add zoom functionality here
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.black,
                                                                            backgroundColor:
                                                                                Colors.white,
                                                                            fixedSize:
                                                                                Size(buttonWidth, buttonHeight),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(0),
                                                                            ),
                                                                            side:
                                                                                const BorderSide(color: Colors.black),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Zoom',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF000000,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                // Map the selected images and return a list of image widgets
                                                                children: _selectedImages
                                                                    .map((Uint8List
                                                                        image) {
                                                                  return Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            100,
                                                                        width:
                                                                            100,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        child: Image
                                                                            .memory(
                                                                          image,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                      // Text Button..
                                                                      Align(
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child:
                                                                            TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              _selectedImages.remove(image);
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            'Remove',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 11,
                                                                              color: const Color(
                                                                                0xFF510986,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                }).toList(),
                                                                // children:
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                .1,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
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
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Opening Stock (F7) :',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFF510986,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .01,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .13,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .055,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: Colors
                                                              .black, // Choose the border color you prefer
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
                                                          value: selectedStock,
                                                          underline:
                                                              Container(),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color: const Color(
                                                              0xFF000000,
                                                            ),
                                                          ),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              selectedStock =
                                                                  newValue!;
                                                            });
                                                          },
                                                          items: stock.map(
                                                              (String value) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: value,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child:
                                                                    Text(value),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .03,
                                                  ),
                                                  Text(
                                                    'Is Active :',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFF510986,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .01,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .13,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .055,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: Colors
                                                              .black, // Choose the border color you prefer
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
                                                          value: selectedStatus,
                                                          underline:
                                                              Container(),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color: const Color(
                                                              0xFF000000,
                                                            ),
                                                          ),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              selectedStatus =
                                                                  newValue!;
                                                            });
                                                          },
                                                          items: status.map(
                                                              (String value) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: value,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child:
                                                                    Text(value),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .01,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                                      width:
                                                                          .3)),
                                                              backgroundColor:
                                                                  Colors.yellow
                                                                      .shade100),
                                                          onPressed:
                                                              createItems,
                                                          child: Text(
                                                            'SAVE [F4]',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                0xFF000000,
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
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
                                                                      width:
                                                                          .3)),
                                                              backgroundColor:
                                                                  Colors.yellow
                                                                      .shade100),
                                                          onPressed: () {
                                                            // print productmetadata map
                                                            print(
                                                                productMetadata);
                                                          },
                                                          child: Text(
                                                            'Cancel',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                0xFF000000,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              .002,
                                                        ),
                                                        // Add Category Button
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  fixedSize: Size(
                                                                      MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          .1,
                                                                      25),
                                                                  textStyle:
                                                                      GoogleFonts
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
                                                                  shape: const BeveledRectangleBorder(
                                                                      side: BorderSide(
                                                                          color: Colors
                                                                              .black,
                                                                          width:
                                                                              .3)),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .yellow
                                                                          .shade100),
                                                          onPressed: () {
                                                            final TextEditingController
                                                                catNameController =
                                                                TextEditingController();

                                                            final TextEditingController
                                                                catDescController =
                                                                TextEditingController();

                                                            List<Uint8List>
                                                                selectedImage =
                                                                [];

                                                            Alert(
                                                                context:
                                                                    context,
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
                                                                            icon:
                                                                                Icon(Icons.category),
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
                                                                            icon:
                                                                                Icon(Icons.description),
                                                                            labelText:
                                                                                'Category Description',
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              10,
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
                                                                              child: selectedImage.isEmpty ? const Center(child: Text('No Image Selected')) : Image.memory(selectedImage[0]),
                                                                            ),
                                                                            Positioned(
                                                                              top: 150,
                                                                              right: -10,
                                                                              left: 0,
                                                                              child: GestureDetector(
                                                                                onTap: () async {
                                                                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
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
                                                                    color: Colors
                                                                        .yellow
                                                                        .shade100,
                                                                    onPressed:
                                                                        () {
                                                                      itemsGroup.createItemsGroup(
                                                                          name: catNameController
                                                                              .text,
                                                                          desc: catDescController
                                                                              .text,
                                                                          images:
                                                                              '');

                                                                      _fetchData();

                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        const Text(
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
                                                                    child:
                                                                        const Text(
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
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                0xFF000000,
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
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
                                                                  20),
                                                              shape: const BeveledRectangleBorder(
                                                                  side: BorderSide(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          .3)),
                                                              backgroundColor:
                                                                  Colors.yellow
                                                                      .shade100),
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
                                                                selectedImage =
                                                                [];

                                                            Alert(
                                                                context:
                                                                    context,
                                                                title:
                                                                    "ADD BRAND",
                                                                content:
                                                                    StatefulBuilder(
                                                                  builder: (BuildContext
                                                                          context,
                                                                      StateSetter
                                                                          setState) {
                                                                    return Column(
                                                                      children: <Widget>[
                                                                        const SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                        TextField(
                                                                          controller:
                                                                              catBrandController,
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            icon:
                                                                                Icon(Icons.category),
                                                                            labelText:
                                                                                'Brand Name',
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              10,
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
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .push(
                                                                              MaterialPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                          return const ItemBrandEdit();
                                                                        },
                                                                      ));
                                                                    },
                                                                    // onPressed:
                                                                    //     () {
                                                                    //   itemsBrand.createItemBrand(
                                                                    //       name: catBrandController
                                                                    //           .text,
                                                                    //       images:
                                                                    //           '');

                                                                    //   _fetchData();

                                                                    //   Navigator.pop(
                                                                    //       context);
                                                                    // },

                                                                    child:
                                                                        const Text(
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
                                                                    child:
                                                                        const Text(
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
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
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

class MetadataButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  const MetadataButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: TextButton(
          onPressed: onPressed,
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF510986))),
          // Icon(icon, color: const Color(0xFF510986)),
        ),
      ),
    );
  }
}

class MetadataTextfield extends StatelessWidget {
  final int maxLines;
  final TextEditingController controller;
  const MetadataTextfield(
      {super.key, required this.maxLines, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: const Color(0xFF000000),
        ),
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(
              color: Colors.black,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class MetadataText extends StatelessWidget {
  final String label;

  const MetadataText({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF510986),
        ),
      ),
    );
  }
}
