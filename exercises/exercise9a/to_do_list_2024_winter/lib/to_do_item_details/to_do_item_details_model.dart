import '/flutter_flow/flutter_flow_model.dart';
import 'to_do_item_details_widget.dart' show ToDoItemDetailsWidget;
import 'package:flutter/material.dart';

class ToDoItemDetailsModel extends FlutterFlowModel<ToDoItemDetailsWidget> {
  /// Focus management
  final unfocusNode = FocusNode();

  /// Address text field (used only in edit mode)
  final addressController = TextEditingController();
  final addressFocusNode = FocusNode();

  /// Display fields
  String? drivingDistanceText;
  String? errorText;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    addressController.dispose();
    addressFocusNode.dispose();
  }
}
