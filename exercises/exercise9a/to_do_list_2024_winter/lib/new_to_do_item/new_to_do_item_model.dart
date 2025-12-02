import 'dart:async';
import 'dart:typed_data';

import '/flutter_flow/flutter_flow_util.dart';
import '/backend/backend.dart';
import 'new_to_do_item_widget.dart' show NewToDoItemWidget;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as g;

class NewToDoItemModel extends FlutterFlowModel<NewToDoItemWidget> {
  /// Focus & Form
  final unfocusNode = FocusNode();
  final formKey = GlobalKey<FormState>();

  /// Text inputs
  FocusNode? taskFocusNode;
  TextEditingController? taskTextController;
  String? Function(BuildContext, String?)? taskTextControllerValidator;

  FocusNode? descriptionFocusNode;
  TextEditingController? descriptionTextController;
  String? Function(BuildContext, String?)? descriptionTextControllerValidator;

  /// Address
  FocusNode? addressFocusNode;
  TextEditingController? addressTextController;
  String? Function(BuildContext, String?)? addressTextControllerValidator;

  /// Resolved coordinates
  double? lat;
  double? lng;

  /// Geocoding state
  bool isGeocoding = false;
  String? geocodeError;

  /// Other fields
  DateTime? datePicked;

  /// Upload
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile =
  FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {
    taskTextController ??= TextEditingController();
    descriptionTextController ??= TextEditingController();
    addressTextController ??= TextEditingController();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    taskFocusNode?.dispose();
    taskTextController?.dispose();
    descriptionFocusNode?.dispose();
    descriptionTextController?.dispose();
    addressFocusNode?.dispose();
    addressTextController?.dispose();
  }

  /// Address → coordinates (optional)
  Future<bool> geocodeAddress() async {
    final addr = addressTextController?.text.trim() ?? '';
    if (addr.isEmpty) {
      geocodeError = 'Please enter an address';
      onUpdate();
      return false;
    }
    try {
      isGeocoding = true;
      geocodeError = null;
      onUpdate();

      final list = await g.locationFromAddress(addr);
      if (list.isEmpty) {
        geocodeError = 'Unable to resolve address';
        isGeocoding = false;
        onUpdate();
        return false;
      }
      lat = list.first.latitude;
      lng = list.first.longitude;

      isGeocoding = false;
      geocodeError = null;
      onUpdate();
      return true;
    } catch (e) {
      isGeocoding = false;
      geocodeError = '$e';
      onUpdate();
      return false;
    }
  }
}
