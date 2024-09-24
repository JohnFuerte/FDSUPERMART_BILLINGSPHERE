import 'package:billingsphere/data/models/ledger/ledger_model.dart';
import 'package:billingsphere/data/repository/item_repository.dart';
import 'package:beep_player/beep_player.dart';
import 'package:billingsphere/data/repository/ledger_repository.dart';
import 'package:billingsphere/data/repository/sales_man_repository.dart';
import 'package:billingsphere/views/SE_widgets/SE_desktop_appbar.dart';
import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/models/customer/new_customer_model.dart';
import '../../data/models/item/item_model.dart';
import '../../data/models/measurementLimit/measurement_limit_model.dart';
import '../../data/models/salesMan/sales_man_model.dart';
import '../../data/models/salesPos/sales_pos_model.dart';
import '../../data/models/taxCategory/tax_category_model.dart';
import '../../data/repository/barcode_repository.dart';
import '../../data/repository/measurement_limit_repository.dart';
import '../../data/repository/new_customer_repository.dart';
import '../../data/repository/sales_pos_repository.dart';
import '../../data/repository/tax_category_repository.dart';
import '../CUSTOMERS/new_customer_desktop.dart';
import '../SALESMAN/sales_man_desktopbody.dart';
import '../SE_common/SE_top_text.dart';
import '../SE_common/SE_top_textfield.dart';
import '../sumit_screen/sumit_responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'SE_Multimode_POS.dart';
import 'SE_master_POS.dart';

class SalesReturn extends StatefulWidget {
  const SalesReturn({super.key});

  @override
  State<SalesReturn> createState() => _SalesReturnState();
}

class _SalesReturnState extends State<SalesReturn> {
  late AudioCache _audioCache;

  final AudioPlayer _audioPlayer = AudioPlayer();

  late TextEditingController _controller;
  late TextEditingController _controller2;
  String _selectedState = 'Gujarat';
  String? selectedItemId;
  String? selectedItemName;

  String selectedState = 'Gujarat';
  late bool visible;
  bool isLoading = false;
  List<Item> itemList = [];
  List<TaxRate> taxLists = [];
  late List<TableRow> tables = [];
  late List<TableRow> Ctables = [];
  late List<TableRow> Ctables2 = [];
  List<SalesPos> salesPosList = [];
  List<SalesMan> salesManList = [];
  List<Ledger> ledgerList = [];
  // Give me a map to save the values
  List<Map<String, dynamic>> values = [];
  List<MeasurementLimit> measurement = [];
  List<NewCustomerModel> customerList = [];
  Map<String, dynamic> _multiModeValues = {};
  ItemsService itemsService = ItemsService();
  TaxRateService taxRateService = TaxRateService();
  MeasurementLimitService measurementService = MeasurementLimitService();
  BarcodeRepository barcodeService = BarcodeRepository();
  SalesPosRepository salesPosRepository = SalesPosRepository();
  LedgerService ledgerService = LedgerService();
  NewCustomerRepository newCustomerRepository = NewCustomerRepository();
  SalesManRepository salesManRepository = SalesManRepository();

  FocusNode _focusNode = FocusNode();

  // Dropdown Select
  String? selectedAC;
  String selectedCustomer = '';
  String selecteSetDiscount = 'No';
  String selectedType = "Cash";
  String? selectedSalesMan;

  UniqueKey tableKey = UniqueKey();
  int? selectedRowIndex;

  Item? selectedItem;

  late int currentIndex;
  void nextRecord() {
    setState(() {
      if (salesPosList.isNotEmpty && currentIndex < salesPosList.length) {
        _noController.text = salesPosList[currentIndex].no.toString();
        selecteSetDiscount = salesPosList[currentIndex].setDiscount;
        selectedType = salesPosList[currentIndex].type;
        selectedAC = salesPosList[currentIndex].ac;
        selectedCustomer = salesPosList[currentIndex].customer;
        _selectedState = salesPosList[currentIndex].place;
        _advanceController.text =
            salesPosList[currentIndex].advance.toStringAsFixed(2);
        _additionController.text =
            salesPosList[currentIndex].addition.toStringAsFixed(2);
        _lessController.text =
            salesPosList[currentIndex].less.toStringAsFixed(2);
        _roundOffController.text =
            salesPosList[currentIndex].roundOff.toStringAsFixed(2);
        _netTotalDiscController.text =
            salesPosList[currentIndex].totalAmount.toStringAsFixed(2);
        _controller.text = salesPosList[currentIndex].date.toString();
        _customerController.text =
            salesPosList[currentIndex].customer.toString();
        _remarkController?.text = salesPosList[currentIndex].remarks.toString();
        _billedToController.text =
            salesPosList[currentIndex].billedTo.toString();

        // _baseController.text = salesPosList[currentIndex].entries[0].base.toString();
        // _mrpController.text = salesPosList[currentIndex].entries[0].mrp.toString();
        // _amountController.text = salesPosList[currentIndex].entries[0].amount.toString();
        // _basicController.text = salesPosList[currentIndex].entries[0].basic.toString();

        tables.clear();

        // Create a list of table rows
        List<TableRow> newRows = salesPosList[currentIndex].entries.map((e) {
          final item = itemList.where((element) {
            return element.id == e.itemName;
          }).first;

          return TableRow(
            key: UniqueKey(),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            children: [
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        (tables.length + 1).toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        item.itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.qty.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.unit,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.base.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.rate.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.mrp.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.basic.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.dis.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.disc.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.tax.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.netAmount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList();

        // Add new rows to the table
        tables.addAll(newRows);

        // Increment the index for the next record
        currentIndex++;
      } else {
        PanaraInfoDialog.show(
          context,
          title: "BillingSphere",
          message: "BillingSphere has reached the end of the list",
          buttonText: "Okay",
          onTapDismiss: () {
            Navigator.pop(context);
          },
          panaraDialogType: PanaraDialogType.normal,
          barrierDismissible: false, // optional parameter (default is true)
        );
      }
    });
  }

  void previousRecord() {
    setState(() {
      // Check if salesPosList is not empty and the currentIndex is within bounds
      if (salesPosList.isNotEmpty && currentIndex > 0) {
        // Decrement the index for the previous record
        currentIndex--;

        // Set the text fields with values from the current index in the list
        _noController.text = salesPosList[currentIndex].no.toString();
        selecteSetDiscount = salesPosList[currentIndex].setDiscount;
        selectedType = salesPosList[currentIndex].type;
        selectedAC = salesPosList[currentIndex].ac;
        selectedCustomer = salesPosList[currentIndex].customer;
        _selectedState = salesPosList[currentIndex].place;
        _advanceController.text =
            salesPosList[currentIndex].advance.toStringAsFixed(2);
        _additionController.text =
            salesPosList[currentIndex].addition.toStringAsFixed(2);
        _lessController.text =
            salesPosList[currentIndex].less.toStringAsFixed(2);
        _roundOffController.text =
            salesPosList[currentIndex].roundOff.toStringAsFixed(2);
        _netTotalDiscController.text =
            salesPosList[currentIndex].totalAmount.toStringAsFixed(2);
        _controller.text = salesPosList[currentIndex].date.toString();
        _customerController.text =
            salesPosList[currentIndex].customer.toString();
        _remarkController?.text = salesPosList[currentIndex].remarks.toString();
        _billedToController.text =
            salesPosList[currentIndex].billedTo.toString();

        // Clear existing table rows if necessary
        tables.clear();

        // Create a list of table rows
        List<TableRow> newRows = salesPosList[currentIndex].entries.map((e) {
          final item = itemList.where((element) {
            return element.id == e.itemName;
          }).first;

          return TableRow(
            key: UniqueKey(),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            children: [
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        (tables.length + 1).toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        item.itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.qty.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.unit,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.base.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.rate.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.mrp.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.basic.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.dis.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.disc.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.tax.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                child: InkWell(
                  child: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        e.netAmount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList();

        // Add new rows to the table
        tables.addAll(newRows);
      } else {
        PanaraInfoDialog.show(
          context,
          title: "BillingSphere",
          message: "BillingSphere has reached the beginning of the list",
          buttonText: "Okay",
          onTapDismiss: () {
            Navigator.pop(context);
          },
          panaraDialogType: PanaraDialogType.normal,
          barrierDismissible: false, // optional parameter (default is true)
        );
      }
    });
  }

  //  Add Listener to focusNode
  // void addListenerToFocusNode() {
  //   _billedToFocusNode.addListener(() {
  //     if (_billedToFocusNode.hasFocus) {
  //       setState(() {
  //         _billedToController.text = selectedCustomer;
  //       });
  //     }
  //   });
  // }

  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discPerController = TextEditingController();
  final TextEditingController _discRsController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _netAmountController = TextEditingController();
  final TextEditingController _basicController = TextEditingController();
  final TextEditingController _noController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _pointController = TextEditingController();
  final TextEditingController _batchNoController = TextEditingController();
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _billedToController = TextEditingController();
  final TextEditingController? _remarkController = TextEditingController();
  final TextEditingController _advanceController =
      TextEditingController(text: '0.00');
  final TextEditingController _pointBalanceController =
      TextEditingController(text: '0.00');
  final TextEditingController _redeemPointController =
      TextEditingController(text: '0.00');
  final TextEditingController _additionController =
      TextEditingController(text: "0.00");
  final TextEditingController _lessController =
      TextEditingController(text: "0.00");
  final TextEditingController _roundOffController =
      TextEditingController(text: "0.00");

  double overralTotal = 0.00;

  // final TextEditingController _rewardDiscController =
  //     TextEditingController(text: "0.00");
  final TextEditingController _netTotalDiscController =
      TextEditingController(text: "0.00");

  // FocusNode
  // final FocusNode _billedToFocusNode = FocusNode();
  // final FocusNode _salesManFocusMode = FocusNode();
  // FocusNode? _currentFocusNode;

  // FocusNode itemFocus = FocusNode();
  // FocusNode qtyFocus = FocusNode();
  // FocusNode unitFocus = FocusNode();
  // FocusNode rateFocus = FocusNode();
  // FocusNode discPerFocus = FocusNode();
  // FocusNode discRsFocus = FocusNode();
  // FocusNode taxFocus = FocusNode();
  // FocusNode netAmountFocus = FocusNode();
  // FocusNode amountFocus = FocusNode();
  // FocusNode perFocus = FocusNode();
  // FocusNode noFocus = FocusNode();
  // FocusNode dateFocus = FocusNode();
  // FocusNode billedToFocus = FocusNode();
  // FocusNode remarkFocus = FocusNode();
  // FocusNode advanceFocus = FocusNode();
  // FocusNode additionFocus = FocusNode();
  // FocusNode lessFocus = FocusNode();
  // FocusNode roundOffFocus = FocusNode();
  // FocusNode netTotalFocus = FocusNode();
  // FocusNode redeemPoints = FocusNode();
  // FocusNode pointBalance = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: DateFormat('MM/dd/yyyy').format(DateTime.now()));
    _controller2 = TextEditingController(
        text: DateFormat('MM/dd/yyyy').format(DateTime.now()));

    _initializeAllData();

    _audioCache = AudioCache(prefix: 'assets/audio/');
    _audioPlayer.audioCache = _audioCache;
    _audioCache.load('beep.mp3');

    //  Request focus for noFocus
    // noFocus.requestFocus();
  }

  Future<void> fetchItems() async {
    final items = await itemsService.fetchItems();
    items.removeWhere((element) => element.maximumStock == 0);
    setState(() {
      itemList = items;
    });
  }

//  Fetch All Sales Man
  Future<void> fetchAllSalesMan() async {
    try {
      final List<SalesMan> salesMan = await salesManRepository.fetchSalesMan();

      setState(() {
        salesManList = salesMan;
        selectedSalesMan = salesMan[0].id;
      });
    } catch (error) {
      print('Failed to fetch Sales');
    }
  }

  // Fetch all POS
  Future<void> fetchAllPOS() async {
    try {
      final List<SalesPos> salesPos = await salesPosRepository.fetchSalesPos();

      setState(() {
        salesPosList = salesPos;
        _noController.text = (salesPos.length + 1).toString();
        currentIndex = salesPosList.length + 1;
      });

      print("Current Index: $currentIndex");
    } catch (error) {
      print('Failed to fetch POS Entries: $error');
    }
  }

  // Fetch all Ledgers
  Future<void> fetchAllLedgers() async {
    try {
      final List<Ledger> ledgers = await ledgerService.fetchLedgers();

      setState(() {
        ledgerList = ledgers;
        selectedAC = ledgers[0].id;
      });
    } catch (error) {
      print('Failed to fetch Ledgers: $error');
    }
  }

  Future<void> fetchAndSetTaxRates() async {
    try {
      final List<TaxRate> taxRates = await taxRateService.fetchTaxRates();

      setState(() {
        taxLists = taxRates;
      });
    } catch (error) {
      print('Failed to fetch Tax Rates: $error');
    }
  }

  Future<void> fetchMeasurementLimit() async {
    try {
      final List<MeasurementLimit> measurements =
          await measurementService.fetchMeasurementLimits();

      setState(() {
        measurement = measurements;
      });
    } catch (error) {
      print('Failed to fetch Tax Rates: $error');
    }
  }

  // Fetch all Customers
  Future<void> fetchAllCustomers() async {
    try {
      final List<NewCustomerModel> customers =
          await newCustomerRepository.getAllCustomers();

      setState(() {
        customerList = customers;
        selectedCustomer = customers[0].id;
      });
    } catch (error) {
      print('Failed to fetch Customers: $error');
    }
  }

  void _saveValues() {
    final newItem = {
      'uniqueKey': tableKey.toString(),
      'itemName': selectedItemId,
      'Item_Name': selectedItemName,
      'discPer': _discPerController.text,
      'discRs': _discRsController.text,
      'tax': _taxController.text,
      'qty': _qtyController.text,
      'unit': _unitController.text,
      'rate': _rateController.text,
      'basic': _basicController.text,
      'base': _baseController.text,
      'mrp': _mrpController.text,
      'amount': _amountController.text,
      'netAmount': _netAmountController.text,
    };

    if (selectedRowIndex != null) {
      // Update the existing item in the list
      values[selectedRowIndex!] = newItem;
    } else {
      // Check if the item already exists in the list
      bool itemExists = false;
      int existingIndex = -1;
      for (int i = 0; i < values.length; i++) {
        if (values[i]['itemName'] == selectedItemId) {
          itemExists = true;
          existingIndex = i;
          break;
        }
      }

      if (itemExists) {
        // Update quantity and calculate net amount
        final qty = int.parse(values[existingIndex]['qty']) +
            int.parse(newItem['qty']!);
        final mrp = double.parse(values[existingIndex]['mrp']);
        final netAmount = qty * mrp;

        // Update values
        values[existingIndex]['qty'] = qty.toString();
        values[existingIndex]['netAmount'] = netAmount.toStringAsFixed(2);
      } else {
        if (newItem['itemName'] != null) {
          // Add new item to the list
          values.add(newItem);
        }
      }
    }
  }

// Calculate the total amount
  void _calculateTotalAmount() {
    double totalAmount = 0.0;
    for (var value in values) {
      totalAmount += double.parse(value['netAmount']);
    }

    setState(() {
      _netTotalDiscController.text = totalAmount.toStringAsFixed(2);
    });

    print(totalAmount);
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

  Future<void> createPOSEntry() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Print all the values before saving
      print('Selected AC: $selectedAC');
      print('Advance: ${_advanceController.text}');
      print('Addition: ${_additionController.text}');
      print('Less: ${_lessController.text}');
      print('Round Off: ${_roundOffController.text}');
      print('Set Discount: $selecteSetDiscount');
      print('Type: $selectedType');
      print('Company Code: ${companyCode![0]}');
      print('Date: ${_controller.text}');
      print('No: ${_noController.text}');
      print('Place: $_selectedState');
      print('Customer: ${_customerController.text}');
      print('Billed To: $_selectedState');
      print('Remarks: ${_remarkController?.text ?? 'No Remarks'}');
      print('Total Amount: ${_netTotalDiscController.text}');
      print('Entries:');
      values.forEach((value) {
        print('Item Name: ${value['itemName']}');
        print('Qty: ${value['qty']}');
        print('Rate: ${value['rate']}');
        print('Unit: ${value['unit']}');
        print('Basic: ${value['basic']}');
        print('Discount Rs: ${value['discRs']}');
        print('Discount %: ${value['discPer']}');
        print('Tax: ${value['tax']}');
        print('Net Amount: ${value['netAmount']}');
      });

      final salesPos = SalesPos(
        id: '',
        ac: selectedAC!,
        advance: double.parse(_advanceController.text),
        addition: double.parse(_additionController.text),
        less: double.parse(_lessController.text),
        roundOff: double.parse(_roundOffController.text),
        setDiscount: selecteSetDiscount,
        type: selectedType,
        noc: 'N/A',
        companyCode: companyCode![0],
        date: _controller.text,
        no: int.parse(_noController.text),
        place: _selectedState,
        entries: values.map((value) {
          return POSEntry(
            itemName: value['itemName'],
            qty: int.parse(value['qty']),
            rate: double.parse(value['rate']),
            unit: value['unit'],
            basic: double.parse(value['basic']),
            dis: double.parse(value['discRs']),
            disc: double.parse(value['discPer']),
            tax: double.parse(value['tax']),
            netAmount: double.parse(value['netAmount']),
            amount: double.parse(value['amount']),
            base: double.parse(value['base']),
            mrp: double.parse(value['mrp']),
          );
        }).toList(),
        customer: selectedCustomer,
        billedTo: _billedToController.text,
        remarks: _remarkController?.text ?? 'No Remarks',
        totalAmount: double.parse(_netTotalDiscController.text),
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      );

      print('Sales POS: $salesPos');

      await salesPosRepository.createPosEntry(salesPos);

      Fluttertoast.showToast(
        msg: 'POS Entry created successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        timeInSecForIosWeb: 3,
      );
    } catch (e) {
      print('Failed to create POS Entry: $e');
    } finally {
      setState(() {
        isLoading = false;
      });

      clearScreen();
    }
  }

  void clearScreen() {
    setState(() {
      _controller.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
      _selectedState = 'Gujarat';
      selectedItemId = null;
      selectedItemName = null;
      _qtyController.text = '';
      _unitController.text = '';
      _rateController.text = '';
      _discPerController.text = '';
      _discRsController.text = '';
      _taxController.text = '';
      _netAmountController.text = '';
      _noController.text = '';
      _customerController.text = '';
      _remarkController?.text = '';
      _additionController.text = '0.00';
      _lessController.text = '0.00';
      _roundOffController.text = '0.00';
      _netTotalDiscController.text = '0.00';
      values.clear();
      tables.clear();
    });
  }

  void _printValues() {
    for (var value in values) {
      print(value);
    }
  }

  void openMultiModeDialog() {
    //  Create a map variable

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 700,
            height: 700,
            child: PopUp2(
              multimodeDetails: _multiModeValues,
              onSaveData: () {},
              totalAmount: double.parse(_netTotalDiscController.text),
              listWidget: Expanded(
                child: ListView.builder(
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> e = values[index];
                    return Row(
                      children: [
                        Container(
                          width: 145,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: SizedBox(
                              width: 100,
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                itemList
                                    .firstWhereOrNull((element) =>
                                        element.id == e['itemName'])!
                                    .itemName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 145,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              '${e['netAmount']}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to delete a row from the table
  void deleteTableRow(int index) {
    setState(() {
      values.removeAt(index);
      tables.removeAt(index);
    });

    _calculateTotalAmount();
  }

  // Function to display the dialog box (Problematic)
  void openDialog({int? rowIndex, Item? item}) {
    if (rowIndex != null) {
      selectedRowIndex = rowIndex;
      final selectedItem = values[rowIndex];
      selectedItemName = selectedItem['Item_Name'];
      _qtyController.text = selectedItem['qty'];
      _unitController.text = selectedItem['unit'];
      _rateController.text = selectedItem['rate'];
      _discPerController.text = selectedItem['discPer'] ?? '';
      _discRsController.text = selectedItem['discRs'] ?? '';
      _taxController.text = selectedItem['tax'] ?? '';
      _netAmountController.text = selectedItem['netAmount'];
      _basicController.text = selectedItem['basic'];
      _baseController.text = selectedItem['base'];
      _mrpController.text = selectedItem['mrp'];
      _amountController.text = selectedItem['amount'];
    } else {
      tableKey = UniqueKey();
      selectedRowIndex = null;
    }
    print('Selected ITEM: ${selectedItem}');
    showDialog(
      context: context,
      builder: (context) {
        // FocusScope.of(context).requestFocus(qtyFocus);
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
                maxHeight: 200,
              ),
              height: 200,
              width: MediaQuery.of(context).size.width * 0.70,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Shortcuts(
                    shortcuts: {
                      LogicalKeySet(LogicalKeyboardKey.space):
                          const ActivateIntent(),
                    },
                    child: Focus(
                      autofocus: true,
                      onKey: (node, event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.space) {
                          print('Pressed Space');
                          _saveValues();
                          _calculateTotalAmount();
                          addTableRow2();
                          Navigator.of(context).pop();

                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 0, 56, 102),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                Text(
                                  "$selectedItemName",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                children: [
                                  CustomTextField(
                                    name: "Qty",
                                    // focusNode: qtyFocus,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(unitFocus);

                                      setState(() {});
                                    },
                                    controller: _qtyController,
                                    onchange: (String value) {
                                      double qty = double.parse(value);

                                      print("Pressed Edit QTY $qty");
                                      print("MRP: ${_mrpController.text}");

                                      double rate =
                                          double.parse(_rateController.text);
                                      double amount = qty * rate;
                                      double netAmount = qty *
                                          double.parse(_mrpController.text);
                                      double tax =
                                          double.parse(_taxController.text);
                                      double finalTax = tax * qty;

                                      setState(() {
                                        _netAmountController.text = netAmount
                                            .toStringAsFixed(2)
                                            .toString();
                                        _amountController.text = amount
                                            .toStringAsFixed(2)
                                            .toString();
                                        _taxController.text =
                                            finalTax.toStringAsFixed(2);
                                      });
                                    },
                                  ),
                                  CustomTextField(
                                    name: "Unit",
                                    // focusNode: unitFocus,
                                    isReadOnly: true,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(rateFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _unitController,
                                    onchange: (String value) {},
                                  ),
                                  CustomTextField(
                                    name: "Rate",
                                    // focusNode: rateFocus,
                                    isReadOnly: true,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(perFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _rateController,
                                    onchange: (String value) {},
                                  ),
                                  CustomTextField(
                                    name: "Per",
                                    // focusNode: perFocus,
                                    isReadOnly: true,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(amountFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _unitController,
                                    onchange: (String value) {},
                                  ),
                                  CustomTextField(
                                    name: "Amount",
                                    // focusNode: amountFocus,
                                    isReadOnly: true,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(discPerFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _amountController,
                                    textAlign: TextAlign.right,
                                    onchange: (String value) {},
                                  ),
                                  CustomTextField(
                                    name: "Disc.%",
                                    // focusNode: discPerFocus,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(discRsFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _discPerController,
                                    textAlign: TextAlign.right,
                                    onchange: (String value) {
                                      // Get Controller and parse to double
                                      double disc = double.parse(value);

                                      double discPer = disc / 100;
                                      double discRs = discPer *
                                          double.parse(_amountController.text);

                                      double netAmount =
                                          double.parse(_amountController.text) -
                                              discRs;

                                      // Set discRs to the controller
                                      setState(() {
                                        _discRsController.text =
                                            discRs.toStringAsFixed(2);
                                        _netAmountController.text =
                                            netAmount.toStringAsFixed(2);
                                      });

                                      print('Rate: ${_rateController.text}');
                                      print(
                                          'Amount: ${_amountController.text}');
                                      print(
                                          'Disc Rs: ${_discRsController.text}');
                                      print(
                                          'Disc %: ${_discPerController.text}');
                                    },
                                  ),
                                  CustomTextField(
                                    name: "DiscRs",
                                    // focusNode: discRsFocus,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(taxFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _discRsController,
                                    textAlign: TextAlign.right,
                                    onchange: (String value) {
                                      // Get Controller and parse to double
                                      double discRs = double.parse(value);
                                      double discountPercentage = (discRs /
                                              double.parse(
                                                  _amountController.text)) *
                                          100;

                                      double netAmount =
                                          double.parse(_amountController.text) -
                                              discRs;

                                      // Set discRs to the controller
                                      setState(() {
                                        _discPerController.text =
                                            discountPercentage
                                                .toStringAsFixed(2);
                                        _netAmountController.text =
                                            netAmount.toStringAsFixed(2);
                                      });
                                    },
                                  ),
                                  CustomTextField(
                                    name: "Tax",
                                    isReadOnly: true,
                                    // focusNode: taxFocus,
                                    onEditingComplete: () {
                                      // FocusScope.of(context)
                                      //     .requestFocus(netAmountFocus);

                                      // REBUILD UI
                                      setState(() {});
                                    },
                                    controller: _taxController,
                                    textAlign: TextAlign.right,
                                    onchange: (String value) {},
                                  ),
                                  CustomTextField(
                                    name: "Net Amount",
                                    isReadOnly: true,
                                    // focusNode: netAmountFocus,
                                    onEditingComplete: () {
                                      // Unfocus the current focus node
                                      // netAmountFocus.unfocus();

                                      // Rebuild UI
                                      setState(() {});
                                    },
                                    controller: _netAmountController,
                                    textAlign: TextAlign.right,
                                    onchange: (String value) {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            thickness: 2,
                            height: 40,
                            color: Colors.black,
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10, left: 5, right: 5),
                                child: Buttons(
                                  onTap: () {
                                    // Pop
                                    Navigator.of(context).pop();

                                    _saveValues();
                                    _calculateTotalAmount();
                                    addTableRow2();
                                  },
                                  name: "Save",
                                  Skey: "[space]",
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Buttons(
                                  onTap: () => Navigator.pop(context),
                                  name: "Cancel",
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10, left: 5, right: 5),
                                child: Buttons(
                                  name: "Delete",
                                  onTap: () {
                                    deleteTableRow(selectedRowIndex!);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              )),
        );
      },
    );
  }

  void openDialog2({int? rowIndex, Item? item}) {
    if (rowIndex != null) {
      selectedRowIndex = rowIndex;
      final selectedItem = values[rowIndex];
      selectedItemName = selectedItem['Item_Name'];
      _qtyController.text = selectedItem['qty'];
      _unitController.text = selectedItem['unit'];
      _rateController.text = selectedItem['rate'];
      _discPerController.text = selectedItem['discPer'] ?? '';
      _basicController.text = selectedItem['basic'];
      _discRsController.text = selectedItem['discRs'] ?? '';
      _taxController.text = selectedItem['tax'] ?? '';
      _netAmountController.text = selectedItem['netAmount'];
      _baseController.text = selectedItem['base'];
      _mrpController.text = selectedItem['mrp'];
      _amountController.text = selectedItem['amount'];
    } else {
      tableKey = UniqueKey();
      selectedRowIndex = null;
    }
    print('Selected ITEM: ${selectedItem}');
    showDialog(
      context: context,
      builder: (context) {
        // Request Focus to Qty
        // FocusScope.of(context).requestFocus(qtyFocus);
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: 200,
                ),
                height: 200,
                width: MediaQuery.of(context).size.width * 0.70,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Shortcuts(
                  shortcuts: {
                    LogicalKeySet(LogicalKeyboardKey.space):
                        const ActivateIntent(),
                  },
                  child: Focus(
                    autofocus: true,
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.space) {
                        print('Pressed Space');
                        _saveValues();
                        _calculateTotalAmount();
                        addTableRow1();
                        Navigator.of(context).pop();

                        // FocusScope.of(context).requestFocus(billedToFocus);

                        setState(() {});

                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 0, 56, 102),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Text(
                                "$selectedItemName",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                CustomTextField(
                                  name: "Qty",
                                  // focusNode: qtyFocus,
                                  controller: _qtyController,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // qtyFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(unitFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {
                                    double qty = double.parse(value);
                                    print('Qty: $qty');
                                    print(
                                        'Selected Item Max: ${item!.maximumStock}');
                                    if (qty <= 0) {
                                      _qtyController.text = '1';
                                      qty = 1;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Quantity cannot be less than 1',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      if (qty > item.maximumStock) {
                                        _qtyController.text =
                                            item.maximumStock.toString();
                                        // qty = selectedItem!.maximumStock.toDouble();

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Quantity cannot be greater than Maximum Stock',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );

                                        // For Net Amount, multiply qty with rate
                                        double rate =
                                            double.parse(_rateController.text);
                                        double netAmount = qty * rate;

                                        setState(() {
                                          _netAmountController.text = netAmount
                                              .toStringAsFixed(2)
                                              .toString();
                                        });
                                      } else {
                                        // For Net Amount, multiply qty with rate
                                        double rate =
                                            double.parse(_rateController.text);
                                        double amount = qty * rate;
                                        double netAmount = qty *
                                            double.parse(_mrpController.text);
                                        double tax =
                                            double.parse(_taxController.text);
                                        double finalTax = tax * qty;

                                        setState(() {
                                          _netAmountController.text = netAmount
                                              .toStringAsFixed(2)
                                              .toString();
                                          _amountController.text = amount
                                              .toStringAsFixed(2)
                                              .toString();
                                          _taxController.text =
                                              finalTax.toStringAsFixed(2);
                                        });
                                      }
                                    }
                                  },
                                ),
                                CustomTextField(
                                  name: "Unit",
                                  // focusNode: unitFocus,
                                  isReadOnly: true,
                                  controller: _unitController,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // unitFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(rateFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {},
                                ),
                                CustomTextField(
                                  name: "Rate",
                                  isReadOnly: true,
                                  // focusNode: rateFocus,
                                  controller: _rateController,
                                  onchange: (String value) {},
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // rateFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(perFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                ),
                                CustomTextField(
                                  name: "Per",
                                  // focusNode: perFocus,
                                  isReadOnly: true,
                                  controller: _unitController,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // perFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(amountFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {},
                                ),
                                CustomTextField(
                                  name: "Amount",
                                  // focusNode: amountFocus,
                                  isReadOnly: true,
                                  controller: _amountController,
                                  textAlign: TextAlign.right,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // amountFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(discPerFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {},
                                ),
                                CustomTextField(
                                  name: "Disc.%",
                                  // focusNode: discPerFocus,
                                  controller: _discPerController,
                                  textAlign: TextAlign.right,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // discPerFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(discRsFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {
                                    // Get Controller and parse to double
                                    double disc = double.parse(value);
                                    double discPer = disc / 100;
                                    double discRs = discPer *
                                        double.parse(_amountController.text);
                                    double netAmount =
                                        double.parse(_amountController.text) -
                                            discRs;

                                    // Set discRs to the controller
                                    setState(() {
                                      _discRsController.text =
                                          discRs.toStringAsFixed(2);
                                      _netAmountController.text =
                                          netAmount.toStringAsFixed(2);
                                    });

                                    // Get the rate
                                  },
                                ),
                                CustomTextField(
                                  name: "DiscRs",
                                  // focusNode: discRsFocus,
                                  controller: _discRsController,
                                  textAlign: TextAlign.right,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // discRsFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(taxFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {
                                    // Get Controller and parse to double
                                    double discRs = double.parse(value);
                                    double discountPercentage = (discRs /
                                            double.parse(
                                                _amountController.text)) *
                                        100;

                                    double netAmount =
                                        double.parse(_amountController.text) -
                                            discRs;

                                    // Set discRs to the controller
                                    setState(() {
                                      _discPerController.text =
                                          discountPercentage.toStringAsFixed(2);
                                      _netAmountController.text =
                                          netAmount.toStringAsFixed(2);
                                    });
                                  },
                                ),
                                CustomTextField(
                                  name: "Tax",
                                  // focusNode: taxFocus,
                                  isReadOnly: true,
                                  controller: _taxController,
                                  textAlign: TextAlign.right,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // taxFocus.unfocus();

                                    // FocusScope.of(context)
                                    //     .requestFocus(netAmountFocus);

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  onchange: (String value) {},
                                ),
                                CustomTextField(
                                  name: "Net Amount",
                                  // focusNode: netAmountFocus,
                                  isReadOnly: true,
                                  controller: _netAmountController,
                                  onEditingComplete: () {
                                    // Unfocus the current focus node
                                    // netAmountFocus.unfocus();

                                    // Rebuild UI
                                    setState(() {});
                                  },
                                  textAlign: TextAlign.right,
                                  onchange: (String value) {},
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                          thickness: 2,
                          height: 40,
                          color: Colors.black,
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10, left: 5, right: 5),
                              child: Buttons(
                                onTap: () {
                                  // Pop
                                  Navigator.of(context).pop();

                                  _saveValues();
                                  _calculateTotalAmount();
                                  addTableRow1();
                                },
                                name: "Save",
                                Skey: "[space]",
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Buttons(
                                onTap: () => Navigator.pop(context),
                                name: "Cancel",
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(
                                  bottom: 10, left: 5, right: 5),
                              child: Buttons(
                                name: "Delete",
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _initializeAllData() async {
    await Future.wait([
      fetchAllPOS(),
      fetchAllSalesMan(),
      fetchAllLedgers(),
      fetchAllCustomers(),
      fetchItems(),
      fetchAndSetTaxRates(),
      fetchMeasurementLimit(),
      setCompanyCode(),
    ]);
  }

  void updateselectedTable(int index) {
    final key = tables[index].key;
    final rowIndex = tables.indexWhere((row) => row.key == key);
    openDialog(rowIndex: rowIndex);
  }

  void addTableRow1() {
    int existingIndex = tables.indexWhere((row) {
      final isTableCell = row.children[1] is TableCell;
      final tableCell = isTableCell ? row.children[1] as TableCell : null;
      final isInkWell = tableCell?.child is InkWell;
      final inkWell = isInkWell ? tableCell!.child as InkWell : null;
      final isSizedBox = inkWell?.child is SizedBox;
      final sizedBox = isSizedBox ? inkWell!.child as SizedBox : null;
      final isAlign = sizedBox?.child is Align;
      final align = isAlign ? sizedBox!.child as Align : null;
      final isTextChild = align?.child is Text;
      final childData =
          isTextChild ? ((align!.child as Text).data ?? 'N/A') : 'N/A';

      return childData == selectedItemName;
    });

    print('ADD TABLE ROW 1 Existing Index: $existingIndex');

    if (existingIndex != -1) {
      final isTableCell = tables[existingIndex].children[4] is TableCell;
      final tableCell =
          isTableCell ? tables[existingIndex].children[4] as TableCell : null;
      final isInkWell = tableCell?.child is InkWell;
      final inkWell = isInkWell ? tableCell!.child as InkWell : null;
      final isSizedBox = inkWell?.child is SizedBox;
      final sizedBox = isSizedBox ? inkWell!.child as SizedBox : null;
      final isAlign = sizedBox?.child is Align;
      final align = isAlign ? sizedBox!.child as Align : null;
      final isTextChild = align?.child is Text;
      final childData =
          isTextChild ? ((align!.child as Text).data ?? 'N/A') : 'N/A';

      print("CHILD DATA: $childData");
      final qty =
          int.parse(_qtyController.text) + int.parse(childData.toString());
      // final qty = int.parse(_qtyController.text);
      final rate = double.parse(_mrpController.text);
      final netAmount = qty * rate;

      // Update the TableCell widgets
      tables[existingIndex].children[4] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                qty.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      tables[existingIndex].children[13] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                netAmount.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      setState(() {
        tables = tables;
      });

      return;
    }

    int index = tables.length;

    setState(() {
      tables.add(
        TableRow(
          key: tableKey,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          children: [
            // Index
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      (tables.length + 1).toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  width: 100,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      selectedItemName!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  width: 100,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      '0',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  width: 100,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _qtyController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _unitController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _baseController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _rateController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _mrpController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _basicController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _discPerController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _discRsController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _taxController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _netAmountController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void addTableRow2() {
    int existingIndex = tables.indexWhere((row) {
      final isTableCell = row.children[1] is TableCell;
      final tableCell = isTableCell ? row.children[1] as TableCell : null;
      final isInkWell = tableCell?.child is InkWell;
      final inkWell = isInkWell ? tableCell!.child as InkWell : null;
      final isSizedBox = inkWell?.child is SizedBox;
      final sizedBox = isSizedBox ? inkWell!.child as SizedBox : null;
      final isAlign = sizedBox?.child is Align;
      final align = isAlign ? sizedBox!.child as Align : null;
      final isTextChild = align?.child is Text;
      final childData =
          isTextChild ? ((align!.child as Text).data ?? 'N/A') : 'N/A';

      print("SELECTED ITEM NAME " + selectedItemName!);
      print("CHILD DATA " + childData);

      return childData == selectedItemName;
    });

    print('ADD TABLE ROW 2 Existing Index: $existingIndex');

    if (existingIndex != -1) {
      final isTableCell = tables[existingIndex].children[4] is TableCell;
      final tableCell =
          isTableCell ? tables[existingIndex].children[4] as TableCell : null;
      final isInkWell = tableCell?.child is InkWell;
      final inkWell = isInkWell ? tableCell!.child as InkWell : null;
      final isSizedBox = inkWell?.child is SizedBox;
      final sizedBox = isSizedBox ? inkWell!.child as SizedBox : null;
      final isAlign = sizedBox?.child is Align;
      final align = isAlign ? sizedBox!.child as Align : null;
      final isTextChild = align?.child is Text;
      final childData =
          isTextChild ? ((align!.child as Text).data ?? 'N/A') : 'N/A';

      print("CHILD DATA 2 " + childData);
      // final qty =
      //     int.parse(_qtyController.text) + int.parse(childData.toString());
      final qty = int.parse(_qtyController.text);
      // Check Net Amount
      final rate = double.parse(_mrpController.text);
      final netAmount = qty * rate;

      // Update the TableCell widgets
      tables[existingIndex].children[4] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                qty.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      tables[existingIndex].children[10] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                _discPerController.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      tables[existingIndex].children[11] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                _discRsController.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      tables[existingIndex].children[13] = TableCell(
        child: InkWell(
          child: SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                netAmount.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      setState(() {
        tables = tables;
      });

      return;
    }

    int index = tables.length;

    setState(() {
      tables.add(
        TableRow(
          key: tableKey,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          children: [
            // Index
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      (tables.length + 1).toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  width: 100,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      selectedItemName!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '0',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _qtyController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _unitController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _baseController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _rateController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _mrpController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _basicController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _discPerController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _discRsController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _taxController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            TableCell(
              child: InkWell(
                onTap: () => updateselectedTable(index),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _netAmountController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _additionController.dispose();
    _controller.dispose();
    _customerController.dispose();
    _discPerController.dispose();
    _discRsController.dispose();
    _basicController.dispose();
    _netAmountController.dispose();
    _netTotalDiscController.dispose();
    _noController.dispose();
    _rateController.dispose();
    _rateController.dispose();
    _remarkController?.dispose();
    _roundOffController.dispose();
    _unitController.dispose();
    _taxController.dispose();
    values.clear();
    tables.clear();
    _audioPlayer.dispose();
  }

  void _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      print('Error playing beep sound: $e');
    }
  }

  String extractDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String extractTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  List<TableRow> _buildTableRows(Map<String, List<SalesPos>> groupedData) {
    return groupedData.entries.map((entry) {
      String key = entry.key;
      List<SalesPos> value = entry.value;

      double totalAmountForGroup =
          value.fold(0, (sum, salesPos) => sum + salesPos.totalAmount);

      overralTotal = totalAmountForGroup;

      return TableRow(
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                key,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '1.00',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                totalAmountForGroup.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  //  Show Customer History Pop-up....
  void showCustomerHistory() {
    final List<SalesPos> selectedCustomerData = salesPosList
        .where((element) => element.customer == selectedCustomer)
        .toList();

    Map<String, List<SalesPos>> groupedData = groupBy(
      selectedCustomerData,
      (SalesPos salesPos) {
        final DateTime createdAt = DateTime.parse(salesPos.createdAt!);
        final String month = getMonthName(createdAt.month);
        final String year = createdAt.year.toString().substring(2);
        return '$month-$year';
      },
    );

    // Construct table rows from the map data

    final List<TableRow> tableRows =
        selectedCustomerData.expand((data) => data.entries).map((entry) {
      final item = itemList.firstWhere((item) => item.id == entry.itemName);

      return TableRow(
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                item.itemName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                entry.qty.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                entry.rate.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                entry.netAmount.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                '0',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      );
    }).toList();

    setState(() {
      Ctables2 = tableRows;
    });

    // Construct table data
    final List<TableRow> tableData = selectedCustomerData.map((data) {
      return TableRow(
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                extractDate(data.createdAt!),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                extractTime(data.createdAt!),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'TI-${data.no}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data.totalAmount.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data.entries.length.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '0',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      );
    }).toList();

    setState(() {
      Ctables = tableData;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          alignment: AlignmentDirectional.bottomEnd,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Container(
                  // height: MediaQuery.of(context).size.height * 0.9,
                  width: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.85,
                            color: const Color(0xFF4169E1),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    'Customer History',
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
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.70,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          SETopText(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                            height: 30,
                                            text: 'Customer',
                                            padding: EdgeInsets.only(
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.00),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                border: Border.all()),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.20,
                                            height: 40,
                                            padding: const EdgeInsets.all(2.0),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedCustomer,
                                                underline: Container(),
                                                icon: const SizedBox.shrink(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedCustomer =
                                                        newValue!;
                                                  });
                                                },
                                                items: customerList.map<
                                                        DropdownMenuItem<
                                                            String>>(
                                                    (NewCustomerModel value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value.id,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 0,
                                                              left: 5),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            value.fname,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: Text(
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              '(${value.mobile})',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: SETopText(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.06,
                                              height: 40,
                                              text: 'Date From',
                                              padding: EdgeInsets.only(
                                                  top: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.00,
                                                  left: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.0005),
                                            ),
                                          ),
                                          SETopTextfield(
                                              controller: _controller,
                                              // focusNode: FocusNode(),
                                              // onEditingComplete: () {},
                                              onSaved: (newValue) {},
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.09,
                                              height: 40,
                                              padding: const EdgeInsets.only(
                                                  left: 8.0, bottom: 16.0),
                                              hintText: '12/12/12'),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.03,
                                            child: IconButton(
                                                onPressed: () {
                                                  showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  ).then((value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        _controller
                                                            .text = DateFormat(
                                                                'MM/dd/yyyy')
                                                            .format(value);
                                                      });
                                                    }
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.calendar_month)),
                                          ),
                                          SETopText(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
                                            height: 30,
                                            text: ' To',
                                            padding: EdgeInsets.only(
                                                left: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.0005,
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.00),
                                          ),
                                          SETopTextfield(
                                              controller: _controller2,
                                              // focusNode: FocusNode(),
                                              // onEditingComplete: () {},
                                              onSaved: (newValue) {},
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.09,
                                              height: 40,
                                              padding: const EdgeInsets.only(
                                                  left: 8.0, bottom: 16.0),
                                              hintText: '12/12/12'),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.03,
                                            child: IconButton(
                                                onPressed: () {
                                                  showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  ).then((value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        _controller2
                                                            .text = DateFormat(
                                                                'MM/dd/yyyy')
                                                            .format(value);
                                                      });
                                                    }
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.calendar_month)),
                                          ),
                                          InkWell(
                                            onTap: () {},
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFACD),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFFFFACD),
                                                  width: 1,
                                                ),
                                              ),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.08,
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Center(
                                                child: Text(
                                                  'Show',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          InkWell(
                                            onTap: () {},
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFACD),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFFFFACD),
                                                  width: 1,
                                                ),
                                              ),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.08,
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Center(
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.33,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.43,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.black,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Table(
                                                border: TableBorder.all(
                                                    width: 1,
                                                    color: Colors.black),
                                                columnWidths: const {
                                                  0: FlexColumnWidth(4),
                                                  1: FlexColumnWidth(2),
                                                  2: FlexColumnWidth(2),
                                                  3: FlexColumnWidth(3),
                                                  4: FlexColumnWidth(3),
                                                  5: FlexColumnWidth(3),
                                                  6: FlexColumnWidth(3),
                                                },
                                                children: [
                                                  TableRow(children: [
                                                    TableCell(
                                                        child: SizedBox(
                                                      height: 40,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          "Date",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: const Color(
                                                                0xff4B0082),
                                                          ),
                                                        ),
                                                      ),
                                                    )),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            "Time",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xff4B0082),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            "No",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xff4B0082),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: Text(
                                                              "Amount",
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: Text(
                                                              "Items",
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: Text(
                                                              "Points",
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4.0),
                                                            child: Text(
                                                              "Redeem",
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]),
                                                  ...Ctables,
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.30,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.40,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.black,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Table(
                                                border: TableBorder.all(
                                                    width: 1,
                                                    color: Colors.black),
                                                columnWidths: const {
                                                  0: FlexColumnWidth(3),
                                                  1: FlexColumnWidth(2),
                                                  2: FlexColumnWidth(2),
                                                  3: FlexColumnWidth(2),
                                                  4: FlexColumnWidth(2),
                                                },
                                                children: [
                                                  TableRow(
                                                    children: [
                                                      TableCell(
                                                          child: SizedBox(
                                                        height: 40,
                                                        child: Align(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            "Month",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xff4B0082),
                                                            ),
                                                          ),
                                                        ),
                                                      )),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 40,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "Bill",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 40,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "Amount",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 40,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "Points",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 40,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              "Redeem",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: const Color(
                                                                    0xff4B0082),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ..._buildTableRows(
                                                      groupedData),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.65,
                                    width: MediaQuery.of(context).size.width *
                                        0.40,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Table(
                                          border: TableBorder.all(
                                              width: 1, color: Colors.black),
                                          columnWidths: const {
                                            0: FlexColumnWidth(5),
                                            1: FlexColumnWidth(2),
                                            2: FlexColumnWidth(2),
                                            3: FlexColumnWidth(3),
                                            4: FlexColumnWidth(2),
                                          },
                                          children: [
                                            TableRow(children: [
                                              TableCell(
                                                  child: SizedBox(
                                                height: 40,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: Text(
                                                      "Item Name",
                                                      textAlign:
                                                          TextAlign.start,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                            0xff4B0082),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                              TableCell(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "Qty",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                            0xff4B0082),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "Rate",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                            0xff4B0082),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: Text(
                                                        "Total Amount",
                                                        textAlign:
                                                            TextAlign.end,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                              0xff4B0082),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: Text(
                                                        "Points",
                                                        textAlign:
                                                            TextAlign.end,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                              0xff4B0082),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ]),
                                            ...Ctables2,
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          //  Total Amount Here....
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          'Total Amount: ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '₹ ${overralTotal.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Text(
                                          'Total Points: ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '0',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () {},
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFACD),
                                              border: Border.all(
                                                color: const Color(0xFFFFFACD),
                                                width: 1,
                                              ),
                                            ),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.08,
                                            height: 40,
                                            padding: const EdgeInsets.all(2.0),
                                            child: Center(
                                              child: Text(
                                                'XLS',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () {},
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFACD),
                                              border: Border.all(
                                                color: const Color(0xFFFFFACD),
                                                width: 1,
                                              ),
                                            ),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.08,
                                            height: 40,
                                            padding: const EdgeInsets.all(2.0),
                                            child: Center(
                                              child: Text(
                                                'Print',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return isLoading
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
              LogicalKeySet(LogicalKeyboardKey.f2):
                  const NavigateToListIntent(),
              LogicalKeySet(LogicalKeyboardKey.f3):
                  const NavigateToNewCustomer(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (ActivateIntent intent) {
                    Navigator.of(context).pop();
                    return null;
                  },
                ),
                NavigateToListIntent: CallbackAction<NavigateToListIntent>(
                  onInvoke: (NavigateToListIntent intent) {
                    PanaraConfirmDialog.showAnimatedGrow(
                      context,
                      title: "BillingSphere",
                      message: "Are you sure you want to cancel this entry?",
                      confirmButtonText: "Confirm",
                      cancelButtonText: "Cancel",
                      onTapCancel: () {
                        Navigator.pop(context);
                      },
                      onTapConfirm: () {
                        // pop screen
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) {
                            return PosMaster(
                              fetchedLedger: ledgerList,
                            );
                          },
                        ));
                      },
                      panaraDialogType: PanaraDialogType.warning,
                    );

                    return null;
                  },
                ),
                NavigateToNewCustomer: CallbackAction<NavigateToNewCustomer>(
                  onInvoke: (NavigateToNewCustomer intent) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const NewCustomer()),
                    );

                    return null;
                  },
                ),
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                body: FocusScope(
                  child: Responsive(
                    mobile: Container(),
                    tablet: Container(),
                    desktop: GestureDetector(
                      onTap: () {
                        //  Request Focus....
                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                      child: SingleChildScrollView(
                        child: VisibilityDetector(
                          onVisibilityChanged: (VisibilityInfo info) {
                            visible = info.visibleFraction > 0;
                          },
                          key: const Key('visible-detector-key'),
                          child: BarcodeKeyboardListener(
                            bufferDuration: const Duration(milliseconds: 200),
                            onBarcodeScanned: (barcode) {
                              if (!visible) return;
                              itemsService
                                  .searchItemsByBarcode(barcode)
                                  .then((value) => {
                                        setState(() {
                                          selectedItem = value.first;
                                          selectedItemId = value.first.id;
                                          selectedItemName =
                                              value.first.itemName;
                                          _qtyController.text = "1";
                                          _rateController.text =
                                              value.first.mrp.toString();
                                          _discPerController.text = "0.00";
                                          _discRsController.text = "0.00";
                                          _basicController.text = "0.00";
                                          _netAmountController.text =
                                              (1 * value.first.mrp)
                                                  .toStringAsFixed(2);
                                        }),
                                        openDialog(),
                                      });
                            },
                            useKeyDownEvent: kIsWeb,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: SEDesktopAppbar(
                                    text1: 'Tax Invoice GST',
                                    text2: 'SALES ENTRY POS',
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Rows....
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8,
                                                left: 10,
                                                bottom: 8.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.85,
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          SETopText(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.05,
                                                            height: 30,
                                                            text: 'No',
                                                            padding: EdgeInsets.only(
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00),
                                                          ),
                                                          SETopTextfield(
                                                            controller:
                                                                _noController,
                                                            onSaved:
                                                                (newValue) {},
                                                            onTap: () {
                                                              // FocusScope.of(
                                                              //         context)
                                                              //     .requestFocus(
                                                              //         noFocus);

                                                              setState(() {});
                                                            },
                                                            // focusNode: noFocus,
                                                            // onEditingComplete:
                                                            //     () {
                                                            //   FocusScope.of(
                                                            //           context)
                                                            //       .requestFocus(
                                                            //           dateFocus);

                                                            //   setState(() {});
                                                            // },
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.07,
                                                            height: 40,
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 8.0,
                                                                    bottom:
                                                                        16.0),
                                                            hintText: '',
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 8.0),
                                                            child: SETopText(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.04,
                                                              height: 40,
                                                              text: 'Date',
                                                              padding: EdgeInsets.only(
                                                                  top: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.00,
                                                                  left: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.0005),
                                                            ),
                                                          ),
                                                          SETopTextfield(
                                                              onTap: () {
                                                                // FocusScope.of(
                                                                //         context)
                                                                //     .requestFocus(
                                                                //         dateFocus);

                                                                setState(() {});
                                                              },
                                                              controller:
                                                                  _controller,
                                                              // focusNode:
                                                              //     dateFocus,
                                                              // onEditingComplete:
                                                              //     () {
                                                              //   FocusScope.of(
                                                              //           context)
                                                              //       .requestFocus(
                                                              //           billedToFocus);

                                                              //   setState(() {});
                                                              // },
                                                              onSaved:
                                                                  (newValue) {},
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.09,
                                                              height: 40,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left: 8.0,
                                                                      bottom:
                                                                          16.0),
                                                              hintText:
                                                                  '12/12/12'),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03,
                                                            child: IconButton(
                                                                onPressed:
                                                                    () {},
                                                                icon: const Icon(
                                                                    Icons
                                                                        .calendar_month)),
                                                          ),
                                                          SETopText(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.04,
                                                            height: 30,
                                                            text: ' Place',
                                                            padding: EdgeInsets.only(
                                                                left: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.0005,
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                    border: Border
                                                                        .all()),
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.1,
                                                            height: 40,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(2.0),
                                                            child:
                                                                DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownMenu<
                                                                      String>(
                                                                requestFocusOnTap:
                                                                    true,
                                                                initialSelection:
                                                                    <String>[
                                                                  'Gujarat',
                                                                  'Maharashtra',
                                                                  'Karnataka',
                                                                  'Tamil Nadu'
                                                                ].first,
                                                                enableSearch:
                                                                    true,
                                                                // enableFilter: true,
                                                                // leadingIcon: const SizedBox.shrink(),
                                                                trailingIcon:
                                                                    const SizedBox
                                                                        .shrink(),
                                                                textStyle:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .none,
                                                                ),
                                                                selectedTrailingIcon:
                                                                    const SizedBox
                                                                        .shrink(),

                                                                inputDecorationTheme:
                                                                    InputDecorationTheme(
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  contentPadding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          16),
                                                                  isDense: true,
                                                                  activeIndicatorBorder:
                                                                      const BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                  ),
                                                                  counterStyle:
                                                                      GoogleFonts
                                                                          .poppins(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                                expandedInsets:
                                                                    EdgeInsets
                                                                        .zero,
                                                                onSelected:
                                                                    (String?
                                                                        value) {
                                                                  setState(() {
                                                                    selectedState =
                                                                        value!;
                                                                  });
                                                                },
                                                                dropdownMenuEntries:
                                                                    <String>[
                                                                  'Gujarat',
                                                                  'Maharashtra',
                                                                  'Karnataka',
                                                                  'Tamil Nadu'
                                                                ].map<DropdownMenuEntry<String>>(
                                                                        (String
                                                                            value) {
                                                                  return DropdownMenuEntry<
                                                                          String>(
                                                                      value:
                                                                          value,
                                                                      label:
                                                                          value,
                                                                      style:
                                                                          ButtonStyle(
                                                                        textStyle:
                                                                            WidgetStateProperty.all(
                                                                          GoogleFonts
                                                                              .poppins(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                      ));
                                                                }).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0,
                                                top: 2.0,
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SETopText(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                        height: 30,
                                                        text: 'Item[F8]',
                                                        padding: EdgeInsets.only(
                                                            right: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.00,
                                                            top: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.00),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                border: Border
                                                                    .all()),
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.377,
                                                        height: 40,
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                          child: DropdownMenu<
                                                              Item>(
                                                            requestFocusOnTap:
                                                                true,
                                                            // focusNode:
                                                            //     itemFocus,
                                                            initialSelection:
                                                                null,
                                                            enableSearch: true,
                                                            trailingIcon:
                                                                const SizedBox
                                                                    .shrink(),
                                                            textStyle:
                                                                GoogleFonts
                                                                    .poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xff000000),
                                                              decoration:
                                                                  TextDecoration
                                                                      .none,
                                                            ),
                                                            menuHeight: 300,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.19,
                                                            selectedTrailingIcon:
                                                                const SizedBox
                                                                    .shrink(),
                                                            inputDecorationTheme:
                                                                const InputDecorationTheme(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          16),
                                                              isDense: true,
                                                              activeIndicatorBorder:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                            ),
                                                            expandedInsets:
                                                                EdgeInsets.zero,
                                                            onSelected:
                                                                (Item? value) {
                                                              _playBeep();
                                                              setState(() {
                                                                final selectedItem =
                                                                    value;

                                                                selectedItemName =
                                                                    selectedItem!
                                                                        .itemName;

                                                                selectedItemId =
                                                                    selectedItem
                                                                        .id;

                                                                String newId =
                                                                    '';
                                                                String newId2 =
                                                                    '';

                                                                for (Item item
                                                                    in itemList) {
                                                                  if (item.id ==
                                                                      selectedItemId) {
                                                                    newId = item
                                                                        .taxCategory;
                                                                    newId2 = item
                                                                        .measurementUnit;
                                                                  }
                                                                }

                                                                for (TaxRate tax
                                                                    in taxLists) {
                                                                  if (tax.id ==
                                                                      newId) {
                                                                    setState(
                                                                        () {
                                                                      _taxController
                                                                              .text =
                                                                          tax.rate;
                                                                    });
                                                                  }
                                                                }
                                                                for (MeasurementLimit meu
                                                                    in measurement) {
                                                                  if (meu.id ==
                                                                      newId2) {
                                                                    setState(
                                                                        () {
                                                                      _unitController.text = meu
                                                                          .measurement
                                                                          .toString();
                                                                    });
                                                                  }
                                                                }

                                                                // Calculate the Rate
                                                                double
                                                                    ratepercent =
                                                                    (double.parse(
                                                                            _taxController.text) /
                                                                        100);

                                                                ratepercent +=
                                                                    1.00;

                                                                print(
                                                                    ratepercent);

                                                                double mpr =
                                                                    selectedItem
                                                                        .mrp;

                                                                double rate = mpr /
                                                                    ratepercent;

                                                                _qtyController
                                                                    .text = "1";
                                                                _rateController
                                                                        .text =
                                                                    rate.toStringAsFixed(
                                                                        2);
                                                                _discPerController
                                                                        .text =
                                                                    "0.00";
                                                                _discRsController
                                                                        .text =
                                                                    "0.00";
                                                                _basicController
                                                                        .text =
                                                                    rate.toStringAsFixed(
                                                                        2);

                                                                _amountController
                                                                        .text =
                                                                    rate.toStringAsFixed(
                                                                        2);

                                                                _mrpController
                                                                        .text =
                                                                    selectedItem
                                                                        .mrp
                                                                        .toStringAsFixed(
                                                                            2);
                                                                _baseController
                                                                        .text =
                                                                    selectedItem
                                                                        .mrp
                                                                        .toStringAsFixed(
                                                                            2);

                                                                final tax =
                                                                    selectedItem
                                                                            .mrp -
                                                                        rate;

                                                                // Change to taxAmountController

                                                                _taxController
                                                                        .text =
                                                                    tax.toStringAsFixed(
                                                                        2);

                                                                // For Net Amount, multiply qty with real rate
                                                                double qty =
                                                                    double.parse(
                                                                        _qtyController
                                                                            .text);
                                                                double rate2 =
                                                                    double.parse(
                                                                        selectedItem
                                                                            .mrp
                                                                            .toString());

                                                                double
                                                                    netAmount =
                                                                    qty * rate2;

                                                                _netAmountController
                                                                        .text =
                                                                    netAmount
                                                                        .toStringAsFixed(
                                                                            2)
                                                                        .toString();

                                                                openDialog2(
                                                                    item:
                                                                        value);
                                                              });
                                                            },
                                                            dropdownMenuEntries:
                                                                itemList.map<
                                                                    DropdownMenuEntry<
                                                                        Item>>((Item
                                                                    value) {
                                                              return DropdownMenuEntry<
                                                                  Item>(
                                                                value: value,
                                                                label: value
                                                                    .itemName,
                                                                trailingIcon:
                                                                    Text(
                                                                  'Qty: ${value.maximumStock}',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                                style:
                                                                    ButtonStyle(
                                                                  textStyle:
                                                                      WidgetStateProperty
                                                                          .all(
                                                                    GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10, left: 10),
                                            child: Container(
                                              height: 350,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                    color: Colors.purple[900] ??
                                                        Colors.purple,
                                                    width: 1),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Table(
                                                        border: TableBorder.all(
                                                            width: 1,
                                                            color:
                                                                Colors.black),
                                                        columnWidths: const {
                                                          0: FlexColumnWidth(1),
                                                          1: FlexColumnWidth(5),
                                                          2: FlexColumnWidth(3),
                                                          3: FlexColumnWidth(3),
                                                          4: FlexColumnWidth(3),
                                                          5: FlexColumnWidth(3),
                                                          6: FlexColumnWidth(3),
                                                          7: FlexColumnWidth(3),
                                                          8: FlexColumnWidth(3),
                                                          9: FlexColumnWidth(3),
                                                          10: FlexColumnWidth(
                                                              3),
                                                          11: FlexColumnWidth(
                                                              3),
                                                          12: FlexColumnWidth(
                                                              3),
                                                          13: FlexColumnWidth(
                                                              3),
                                                          14: FlexColumnWidth(
                                                              3),
                                                        },
                                                        children: [
                                                          TableRow(children: [
                                                            TableCell(
                                                                child: SizedBox(
                                                              height: 40,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  "Sr",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: const Color(
                                                                        0xff4B0082),
                                                                  ),
                                                                ),
                                                              ),
                                                            )),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Item Name(^F8)",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Points",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      "Batch No",
                                                                      textAlign:
                                                                          TextAlign
                                                                              .left,
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: const Color(
                                                                            0xff4B0082),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Qty",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Unit",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Base",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Rate",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "MRP",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Basic",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Dis%",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Disc",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Tax",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            TableCell(
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Text(
                                                                    "Net.Amt",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color(
                                                                          0xff4B0082),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ]),
                                                          ...tables,
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10, left: 10),
                                            child: Container(
                                              // height: 280,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                    color: Colors.purple[900] ??
                                                        Colors.purple,
                                                    width: 1),
                                              ),
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const SizedBox(
                                                            height: 10),
                                                        SizedBox(
                                                          width: w * 0.32,
                                                          // height: 190,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            2),
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.08,
                                                                            child:
                                                                                Text(
                                                                              "Set Discount",
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 15,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.deepPurple,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                BoxDecoration(border: Border.all()),
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.05,
                                                                            height:
                                                                                40,
                                                                            padding:
                                                                                const EdgeInsets.all(2.0),
                                                                            child:
                                                                                DropdownButtonHideUnderline(
                                                                              child: DropdownButton<String>(
                                                                                value: selecteSetDiscount,
                                                                                underline: Container(),
                                                                                icon: const SizedBox.shrink(),
                                                                                onChanged: (String? newValue) {
                                                                                  setState(() {
                                                                                    selecteSetDiscount = newValue!;
                                                                                  });
                                                                                },
                                                                                items: [
                                                                                  "No",
                                                                                  "Yes",
                                                                                ].map<DropdownMenuItem<String>>((String value) {
                                                                                  return DropdownMenuItem<String>(
                                                                                    value: value,
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.only(bottom: 0, left: 5),
                                                                                      child: Text(
                                                                                        value,
                                                                                        style: GoogleFonts.poppins(
                                                                                          color: Colors.black,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.04,
                                                                            child:
                                                                                Text(
                                                                              "Type",
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 15,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.deepPurple,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                BoxDecoration(border: Border.all()),
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.1,
                                                                            height:
                                                                                40,
                                                                            padding:
                                                                                const EdgeInsets.all(2.0),
                                                                            child:
                                                                                DropdownButtonHideUnderline(
                                                                              child: DropdownButton<String>(
                                                                                value: selectedType,
                                                                                underline: Container(),
                                                                                icon: const SizedBox.shrink(),
                                                                                onChanged: (String? newValue) {
                                                                                  setState(() {
                                                                                    selectedType = newValue!;
                                                                                  });

                                                                                  if (selectedType == 'Multimode') {
                                                                                    openMultiModeDialog();
                                                                                  }
                                                                                },
                                                                                items: [
                                                                                  "Cash",
                                                                                  "Credit",
                                                                                  "Multimode",
                                                                                  "UPI",
                                                                                  "CARD",
                                                                                  "PAYMENT",
                                                                                  "CHECQUE",
                                                                                ].map<DropdownMenuItem<String>>((String value) {
                                                                                  return DropdownMenuItem<String>(
                                                                                    value: value,
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.only(bottom: 0, left: 5),
                                                                                      child: Text(
                                                                                        value,
                                                                                        style: GoogleFonts.poppins(
                                                                                          color: Colors.black,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 10.0),
                                                              Row(
                                                                children: [
                                                                  SizedBox(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.08,
                                                                    child: Text(
                                                                      "A/c",
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Colors
                                                                            .deepPurple,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                            border:
                                                                                Border.all()),
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.2,
                                                                    height: 40,
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            2.0),
                                                                    child:
                                                                        DropdownButtonHideUnderline(
                                                                      child: DropdownMenu<
                                                                          Ledger>(
                                                                        width:
                                                                            400,
                                                                        requestFocusOnTap:
                                                                            true,
                                                                        initialSelection: ledgerList.isNotEmpty
                                                                            ? ledgerList.first
                                                                            : null,
                                                                        enableSearch:
                                                                            true,
                                                                        trailingIcon:
                                                                            const SizedBox.shrink(),
                                                                        textStyle:
                                                                            GoogleFonts.poppins(
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.black,
                                                                          decoration:
                                                                              TextDecoration.none,
                                                                        ),
                                                                        menuHeight:
                                                                            300,
                                                                        selectedTrailingIcon:
                                                                            const SizedBox.shrink(),
                                                                        inputDecorationTheme:
                                                                            const InputDecorationTheme(
                                                                          border:
                                                                              InputBorder.none,
                                                                          contentPadding: EdgeInsets.symmetric(
                                                                              horizontal: 8,
                                                                              vertical: 0),
                                                                          isDense:
                                                                              true,
                                                                          activeIndicatorBorder:
                                                                              BorderSide(
                                                                            color:
                                                                                Colors.transparent,
                                                                          ),
                                                                        ),
                                                                        expandedInsets:
                                                                            EdgeInsets.zero,
                                                                        onSelected:
                                                                            (Ledger?
                                                                                value) {
                                                                          if (value !=
                                                                              null) {
                                                                            setState(() {
                                                                              selectedAC = value.id;
                                                                            });
                                                                          }
                                                                        },
                                                                        dropdownMenuEntries: ledgerList.map<
                                                                            DropdownMenuEntry<
                                                                                Ledger>>((Ledger
                                                                            value) {
                                                                          return DropdownMenuEntry<
                                                                              Ledger>(
                                                                            value:
                                                                                value,
                                                                            label:
                                                                                value.name,
                                                                            style:
                                                                                ButtonStyle(
                                                                              textStyle: WidgetStateProperty.all(
                                                                                GoogleFonts.poppins(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Colors.black,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 5),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.08,
                                                                      child:
                                                                          Text(
                                                                        "Customer/Mob.",
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.deepPurple,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                              border: Border.all()),
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.18,
                                                                      height:
                                                                          40,
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          2.0),
                                                                      child:
                                                                          DropdownButtonHideUnderline(
                                                                        child: DropdownMenu<
                                                                            NewCustomerModel>(
                                                                          width:
                                                                              400,
                                                                          requestFocusOnTap:
                                                                              true,
                                                                          initialSelection: customerList.isNotEmpty
                                                                              ? customerList.first
                                                                              : null,
                                                                          enableSearch:
                                                                              true,
                                                                          trailingIcon:
                                                                              const SizedBox.shrink(),
                                                                          textStyle:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black,
                                                                            decoration:
                                                                                TextDecoration.none,
                                                                          ),
                                                                          menuHeight:
                                                                              300,
                                                                          selectedTrailingIcon:
                                                                              const SizedBox.shrink(),
                                                                          inputDecorationTheme:
                                                                              const InputDecorationTheme(
                                                                            border:
                                                                                InputBorder.none,
                                                                            contentPadding:
                                                                                EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                                            isDense:
                                                                                true,
                                                                            activeIndicatorBorder:
                                                                                BorderSide(
                                                                              color: Colors.transparent,
                                                                            ),
                                                                          ),
                                                                          expandedInsets:
                                                                              EdgeInsets.zero,
                                                                          onSelected:
                                                                              (NewCustomerModel? value) {
                                                                            setState(() {
                                                                              selectedCustomer = value!.id;

                                                                              for (NewCustomerModel customer in customerList) {
                                                                                if (customer.id.contains(value.id)) {
                                                                                  _billedToController.text = '${customer.fname} M.(${customer.mobile})';
                                                                                }
                                                                              }
                                                                            });
                                                                          },
                                                                          dropdownMenuEntries:
                                                                              customerList.map<DropdownMenuEntry<NewCustomerModel>>((NewCustomerModel value) {
                                                                            return DropdownMenuEntry<NewCustomerModel>(
                                                                              value: value,
                                                                              label: value.fname,
                                                                              style: ButtonStyle(
                                                                                textStyle: WidgetStateProperty.all(
                                                                                  GoogleFonts.poppins(
                                                                                    fontSize: 16,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.black,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    InkWell(
                                                                      onTap:
                                                                          showCustomerHistory,
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            40,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            const Center(
                                                                          child:
                                                                              Icon(
                                                                            Icons.more_horiz,
                                                                            size:
                                                                                40.0,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 5),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.08,
                                                                      child:
                                                                          Text(
                                                                        "Billed to",
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.deepPurple,
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    // Billed To
                                                                    SETopTextfield(
                                                                      onTap:
                                                                          () {
                                                                        // FocusScope.of(context)
                                                                        //     .requestFocus(billedToFocus);
                                                                        // setState(
                                                                        //     () {});
                                                                      },
                                                                      // focusNode:
                                                                      //     billedToFocus,
                                                                      // onEditingComplete:
                                                                      //     () {
                                                                      //   FocusScope.of(context)
                                                                      //       .requestFocus(remarkFocus);
                                                                      //   setState(
                                                                      //       () {});
                                                                      // },
                                                                      controller:
                                                                          _billedToController,
                                                                      onSaved:
                                                                          (newValue) {},
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3,
                                                                      height:
                                                                          40,
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0,
                                                                          bottom:
                                                                              16.0),
                                                                      hintText:
                                                                          '',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 5),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.08,
                                                                      child:
                                                                          Text(
                                                                        "Remarks",
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.deepPurple,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SETopTextfield(
                                                                      onTap:
                                                                          () {
                                                                        // FocusScope.of(context)
                                                                        //     .requestFocus(remarkFocus);
                                                                        // setState(
                                                                        //     () {});
                                                                      },
                                                                      controller:
                                                                          _remarkController,
                                                                      // focusNode:
                                                                      //     remarkFocus,
                                                                      // onEditingComplete:
                                                                      //     () {
                                                                      //   FocusScope.of(context)
                                                                      //       .requestFocus(advanceFocus);
                                                                      //   setState(
                                                                      //       () {});
                                                                      // },
                                                                      onSaved:
                                                                          (newValue) {},
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.3,
                                                                      height:
                                                                          40,
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8.0,
                                                                          bottom:
                                                                              16.0),
                                                                      hintText:
                                                                          '',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: w * 0.35,
                                                          // height: 170,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 50),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const SizedBox(
                                                                  height: 5,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      w * 0.30,
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "S. Man",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      Container(
                                                                        decoration:
                                                                            BoxDecoration(border: Border.all()),
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.1,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            2.0),
                                                                        child:
                                                                            DropdownButtonHideUnderline(
                                                                          child:
                                                                              DropdownMenu<SalesMan>(
                                                                            width:
                                                                                400,
                                                                            requestFocusOnTap:
                                                                                true,
                                                                            initialSelection: salesManList.isNotEmpty
                                                                                ? salesManList.first
                                                                                : null,
                                                                            enableSearch:
                                                                                true,
                                                                            trailingIcon:
                                                                                const SizedBox.shrink(),
                                                                            textStyle:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black,
                                                                              decoration: TextDecoration.none,
                                                                            ),
                                                                            menuHeight:
                                                                                300,
                                                                            selectedTrailingIcon:
                                                                                const SizedBox.shrink(),
                                                                            inputDecorationTheme:
                                                                                const InputDecorationTheme(
                                                                              border: InputBorder.none,
                                                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                                              isDense: true,
                                                                              activeIndicatorBorder: BorderSide(
                                                                                color: Colors.transparent,
                                                                              ),
                                                                            ),
                                                                            expandedInsets:
                                                                                EdgeInsets.zero,
                                                                            onSelected:
                                                                                (SalesMan? value) {
                                                                              setState(() {
                                                                                // FocusScope.of(context).requestFocus(_salesManFocusMode);
                                                                                setState(() {
                                                                                  selectedSalesMan = value!.id;
                                                                                });
                                                                              });
                                                                            },
                                                                            dropdownMenuEntries:
                                                                                salesManList.map<DropdownMenuEntry<SalesMan>>((SalesMan value) {
                                                                              return DropdownMenuEntry<SalesMan>(
                                                                                value: value,
                                                                                label: value.name,
                                                                                style: ButtonStyle(
                                                                                  textStyle: WidgetStateProperty.all(
                                                                                    GoogleFonts.poppins(
                                                                                      fontSize: 16,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: Colors.black,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                          ),
                                                                        ),
                                                                      ),

                                                                      // SETopTextfield(
                                                                      //   controller:
                                                                      //       _salesManController,
                                                                      //   onSaved:
                                                                      //       (newValue) {},
                                                                      //   width: MediaQuery.of(
                                                                      //               context)
                                                                      //           .size
                                                                      //           .width *
                                                                      //       0.1,
                                                                      //   height: 40,
                                                                      //   padding: const EdgeInsets
                                                                      //       .only(
                                                                      //       left: 8.0,
                                                                      //       bottom:
                                                                      //           16.0),
                                                                      //   hintText: '',
                                                                      //   alignment:
                                                                      //       TextAlign
                                                                      //           .end,
                                                                      // ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      w * 0.25,
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Advance",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(advanceFocus);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     advanceFocus,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(pointBalance);

                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _advanceController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.1,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      w * 0.30,
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Point Balance",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(pointBalance);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     pointBalance,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(redeemPoints);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _pointBalanceController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.1,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                SizedBox(
                                                                  width:
                                                                      w * 0.30,
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Redeem Points",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(redeemPoints);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     redeemPoints,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(additionFocus);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        controller:
                                                                            _redeemPointController,
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.1,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 100,
                                                                  child: Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .bottomRight,
                                                                    child: Text(
                                                                      'Profit Check',
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Colors
                                                                            .blue,
                                                                        decoration:
                                                                            TextDecoration.underline,
                                                                        decorationColor:
                                                                            Colors.blue, // Change underline color
                                                                        decorationThickness:
                                                                            2.0, // Change underline thickness
                                                                        decorationStyle:
                                                                            TextDecorationStyle.solid, // Change underline style
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 0),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                width: w * 0.2,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Addition(F6)",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(additionFocus);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     additionFocus,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(lessFocus);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _additionController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.15,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: w * 0.2,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Less(F7)",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(lessFocus);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     lessFocus,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(roundOffFocus);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _lessController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.15,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: w * 0.2,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Round off",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(roundOffFocus);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     roundOffFocus,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(netTotalFocus);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _roundOffController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.15,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: w * 0.2,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child: Row(
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.08,
                                                                        child:
                                                                            Text(
                                                                          "Net Total",
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.deepPurple,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SETopTextfield(
                                                                        onTap:
                                                                            () {
                                                                          // FocusScope.of(context)
                                                                          //     .requestFocus(netTotalFocus);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        // focusNode:
                                                                        //     netTotalFocus,
                                                                        // onEditingComplete:
                                                                        //     () {
                                                                        //   FocusScope.of(context)
                                                                        //       .requestFocus(noFocus);
                                                                        //   setState(
                                                                        //       () {});
                                                                        // },
                                                                        alignment:
                                                                            TextAlign.end,
                                                                        controller:
                                                                            _netTotalDiscController,
                                                                        onSaved:
                                                                            (newValue) {},
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.15,
                                                                        height:
                                                                            40,
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                8.0,
                                                                            bottom:
                                                                                16.0),
                                                                        hintText:
                                                                            '',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              // const SizedBox(
                                                              //   height: 35,
                                                              // ),
                                                            ],
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  ]),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10, left: 10, top: 10),
                                            child: Row(
                                              children: [
                                                const Button(
                                                  name: "Hold",
                                                ),
                                                const Button(
                                                  name: "Hold List",
                                                ),
                                                const Spacer(),
                                                Button(
                                                  name: "Save",
                                                  Skey: "[F4]",
                                                  onTap: createPOSEntry,
                                                ),
                                                const Button(
                                                  name: "Cancel",
                                                ),
                                                const Button(
                                                  name: "Delete",
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Shortcuts(
                                      shortcuts: {
                                        LogicalKeySet(LogicalKeyboardKey.f3):
                                            const ActivateIntent(),
                                        LogicalKeySet(LogicalKeyboardKey.f4):
                                            const ActivateIntent(),
                                      },
                                      child: Focus(
                                        autofocus: true,
                                        focusNode: _focusNode,
                                        onKey: (node, event) {
                                          if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.f3) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const NewCustomer()),
                                            );
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.f6) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const SalesManDesktopbody(),
                                              ),
                                            );
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.escape) {
                                            Navigator.of(context).pop();
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.f2) {
                                            PanaraConfirmDialog
                                                .showAnimatedGrow(
                                              context,
                                              title: "BillingSphere",
                                              message:
                                                  "Are you sure you want to cancel this entry?",
                                              confirmButtonText: "Confirm",
                                              cancelButtonText: "Cancel",
                                              onTapCancel: () {
                                                Navigator.pop(context);
                                              },
                                              onTapConfirm: () {
                                                // pop screen
                                                Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .push(MaterialPageRoute(
                                                  builder: (context) {
                                                    return PosMaster(
                                                      fetchedLedger: ledgerList,
                                                    );
                                                  },
                                                ));
                                              },
                                              panaraDialogType:
                                                  PanaraDialogType.warning,
                                            );

                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.keyN) {
                                            PanaraConfirmDialog
                                                .showAnimatedGrow(
                                              context,
                                              title: "BillingSphere",
                                              message:
                                                  "Are you sure you want to create a new entry?",
                                              confirmButtonText: "Confirm",
                                              cancelButtonText: "Cancel",
                                              onTapCancel: () {
                                                Navigator.pop(context);
                                              },
                                              onTapConfirm: () {
                                                // pop screen
                                                Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                        MaterialPageRoute(
                                                  builder: (context) {
                                                    return const SalesReturn();
                                                  },
                                                ));
                                              },
                                              panaraDialogType:
                                                  PanaraDialogType.warning,
                                            );
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.pageUp) {
                                            previousRecord();
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.pageDown) {
                                            nextRecord();
                                            return KeyEventResult.handled;
                                          } else if (event is RawKeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.f4) {
                                            createPOSEntry();
                                            return KeyEventResult.handled;
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: Container(
                                          height: 700,
                                          width: w * 0.1,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                  width: 1,
                                                  color: Colors.purple[900] ??
                                                      Colors.purple),
                                              right: BorderSide(
                                                  width: 1,
                                                  color: Colors.purple[900] ??
                                                      Colors.purple),
                                              bottom: BorderSide(
                                                  width: 1,
                                                  color: Colors.purple[900] ??
                                                      Colors.purple),
                                              left: BorderSide(
                                                  width: 1,
                                                  color: Colors.purple[900] ??
                                                      Colors.purple),
                                            ),
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Column(
                                              children: [
                                                List2(
                                                  Skey: "F2",
                                                  name: "List",
                                                  onTap: () {
                                                    PanaraConfirmDialog
                                                        .showAnimatedGrow(
                                                      context,
                                                      title: "BillingSphere",
                                                      message:
                                                          "Are you sure you want to cancel this entry?",
                                                      confirmButtonText:
                                                          "Confirm",
                                                      cancelButtonText:
                                                          "Cancel",
                                                      onTapCancel: () {
                                                        Navigator.pop(context);
                                                      },
                                                      onTapConfirm: () {
                                                        // pop screen
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .push(
                                                                MaterialPageRoute(
                                                          builder: (context) {
                                                            return PosMaster(
                                                              fetchedLedger:
                                                                  ledgerList,
                                                            );
                                                          },
                                                        ));
                                                      },
                                                      panaraDialogType:
                                                          PanaraDialogType
                                                              .warning,
                                                    );
                                                  },
                                                ),
                                                List2(
                                                  Skey: "F3",
                                                  name: "New Customer",
                                                  onTap: () {
                                                    final result =
                                                        Navigator.of(context)
                                                            .push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const NewCustomer(),
                                                      ),
                                                    );

                                                    result.then((value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          customerList
                                                              .add(value);
                                                        });
                                                      }
                                                    });

                                                    print('Result: $result');
                                                  },
                                                ),
                                                List2(
                                                  Skey: "F6",
                                                  name: "New S. Man",
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const SalesManDesktopbody(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                List2(
                                                  Skey: "N",
                                                  name: "New",
                                                  onTap: () {
                                                    PanaraConfirmDialog
                                                        .showAnimatedGrow(
                                                      context,
                                                      title: "BillingSphere",
                                                      message:
                                                          "Are you sure you want to create a new entry?",
                                                      confirmButtonText:
                                                          "Confirm",
                                                      cancelButtonText:
                                                          "Cancel",
                                                      onTapCancel: () {
                                                        Navigator.pop(context);
                                                      },
                                                      onTapConfirm: () {
                                                        // pop screen
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .pushReplacement(
                                                                MaterialPageRoute(
                                                          builder: (context) {
                                                            return const SalesReturn();
                                                          },
                                                        ));
                                                      },
                                                      panaraDialogType:
                                                          PanaraDialogType
                                                              .warning,
                                                    );
                                                  },
                                                ),
                                                // const List2(
                                                //   Skey: "P",
                                                //   name: "Print",
                                                // ),
                                                // const List2(
                                                //   Skey: "A",
                                                //   name: "Alt Print",
                                                // ),
                                                // const List2(
                                                //   Skey: "F5",
                                                //   name: "Change Type",
                                                // ),
                                                // const List2(),
                                                // const List2(
                                                //   Skey: "B",
                                                //   name: "Prn Barcode",
                                                // ),
                                                // const List2(),
                                                // const List2(
                                                //   Skey: "N",
                                                //   name: "Search No",
                                                // ),
                                                // const List2(
                                                //   Skey: "M",
                                                //   name: "Search Item",
                                                // ),
                                                // const List2(),
                                                // const List2(
                                                //   name: "Discount",
                                                //   Skey: "F12",
                                                // ),
                                                // const List2(
                                                //   Skey: "F12",
                                                //   name: "Audit Trail",
                                                // ),
                                                List2(
                                                  Skey: "Pg Up",
                                                  name: "Previous",
                                                  onTap: previousRecord,
                                                ),
                                                List2(
                                                  Skey: "Pg Dn",
                                                  name: "Next",
                                                  onTap: nextRecord,
                                                ),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                const List2(),
                                                // const List2(
                                                //   Skey: "G",
                                                //   name: "Attach. Img",
                                                // ),
                                                // const List2(),
                                                // const List2(
                                                //   Skey: "G",
                                                //   name: "Vch Setup",
                                                // ),
                                                // const List2(
                                                //   Skey: "T",
                                                //   name: "Print Setup",
                                                // ),
                                                // const List2(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}

class NavigateToNewCustomer extends Intent {
  const NavigateToNewCustomer();
}

class NavigateToListIntent extends Intent {
  const NavigateToListIntent();
}

Widget Values() {
  return AlertDialog(
    content: Container(
      height: 50,
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                          flex: 1,
                          child: Text(
                            "No",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          )),
                      Expanded(
                          flex: 2,
                          child: TextFormField(
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[500] ?? Colors.grey,
                                    width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[500] ?? Colors.grey,
                                    width: 2),
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          )),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    ),
  );
}

class List2 extends StatelessWidget {
  final String? name;
  final String? Skey;
  final VoidCallback? onTap;
  const List2({super.key, this.name, this.Skey, this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        splashColor: Colors.grey[350],
        onTap: onTap,
        child: Container(
          height: 32,
          width: w * 0.1,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  width: 1, color: Colors.purple[900] ?? Colors.purple),
              right: BorderSide(
                  width: 1, color: Colors.purple[900] ?? Colors.purple),
              bottom: BorderSide(
                  width: 1, color: Colors.purple[900] ?? Colors.purple),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Text(
                              Skey ?? "",
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name ?? " ",
                        style: GoogleFonts.poppins(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Button extends StatelessWidget {
  const Button({super.key, this.name, this.Skey, this.onTap});
  final VoidCallback? onTap;
  final String? name;
  final String? Skey;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        splashColor: Colors.grey[350],
        onTap: onTap,
        child: Container(
          height: 32,
          width: w * 0.07,
          decoration: BoxDecoration(
              color: Colors.yellow[200],
              border:
                  Border.all(color: const Color.fromARGB(255, 234, 211, 3))),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: Text(
                        name ?? " ",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      Skey ?? "",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  final String name;
  final TextEditingController controller;
  final ValueChanged<String>
      onchange; // Changed VoidCallback to ValueChanged<String>
  final TextAlign? textAlign;
  final VoidCallback? onEditingComplete;
  final bool? isReadOnly;

  const CustomTextField({
    required this.name,
    required this.controller,
    super.key,
    required this.onchange,
    this.textAlign,
    this.isReadOnly,
    this.onEditingComplete,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.name,
                    style: GoogleFonts.poppins(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: widget.controller,
                    readOnly: widget.isReadOnly ?? false,
                    textAlign: widget.textAlign ?? TextAlign.center,
                    onChanged: widget.onchange,
                    onEditingComplete: () {
                      widget.onEditingComplete
                          ?.call(); // Updated to call function if not null

                      setState(() {}); // Force rebuild on focus change
                    },
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 5),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  final String? name;
  final String? Skey;
  final VoidCallback? onTap; // Nullable onTap function
  const Buttons({Key? key, this.name, this.Skey, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        splashColor: Colors.grey[350],
        onTap: onTap, // Use onTap function here
        child: Container(
          height: 32,
          width: w * 0.1,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(color: const Color.fromARGB(255, 234, 211, 3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                child: Text(
                  name ?? " ",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                Skey ?? "",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
