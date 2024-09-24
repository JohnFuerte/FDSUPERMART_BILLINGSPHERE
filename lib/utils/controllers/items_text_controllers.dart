import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ItemsFormControllers {
  // TextEditingController instances
  TextEditingController itemNameController = TextEditingController();
  TextEditingController printNameController = TextEditingController();
  TextEditingController codeNoController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  TextEditingController minimumStockController = TextEditingController();
  TextEditingController maximumStockController = TextEditingController();
  TextEditingController monthlySalesQtyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController dealerController = TextEditingController();
  TextEditingController subDealerController = TextEditingController();
  TextEditingController retailController = TextEditingController();
  TextEditingController mrpController = TextEditingController();
  TextEditingController openingStockController = TextEditingController();
  TextEditingController currentPriceController = TextEditingController();
  TextEditingController discountController =
      TextEditingController(text: '0.00');

  // Dispose method to dispose all controllers
  void dispose() {
    itemNameController.dispose();
    printNameController.dispose();
    codeNoController.dispose();
    barcodeController.dispose();
    minimumStockController.dispose();
    maximumStockController.dispose();
    monthlySalesQtyController.dispose();
    dateController.dispose();
    dealerController.dispose();
    subDealerController.dispose();
    retailController.dispose();
    mrpController.dispose();
    openingStockController.dispose();
    currentPriceController.dispose();
    discountController.dispose();
  }
}
