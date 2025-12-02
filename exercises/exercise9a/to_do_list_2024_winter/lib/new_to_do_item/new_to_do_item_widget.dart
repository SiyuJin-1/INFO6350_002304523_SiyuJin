import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';

import 'package:geocoding/geocoding.dart' as g;

import 'new_to_do_item_model.dart';
export 'new_to_do_item_model.dart';

class NewToDoItemWidget extends StatefulWidget {
  const NewToDoItemWidget({super.key});

  @override
  State<NewToDoItemWidget> createState() => _NewToDoItemWidgetState();
}

class _NewToDoItemWidgetState extends State<NewToDoItemWidget> {
  late NewToDoItemModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NewToDoItemModel());

    _model.taskTextController ??= TextEditingController();
    _model.taskFocusNode ??= FocusNode();

    _model.descriptionTextController ??= TextEditingController();
    _model.descriptionFocusNode ??= FocusNode();

    _model.addressTextController ??= TextEditingController();
    _model.addressFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Run geocoding & show toast
  Future<void> _tryGeocodeAndToast() async {
    final ok = await _model.geocodeAddress();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Address resolved successfully' : (_model.geocodeError ?? 'Failed to resolve address')),
      ),
    );
  }

  /// Save ToDo item
  Future<void> _save() async {
    // Ensure user is logged in
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before adding a ToDo')),
      );
      return;
    }
    final uid = currentUserUid;

    // Validate form
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    // If address is provided but no coordinates, automatically resolve
    final addr = _model.addressTextController?.text.trim() ?? '';
    if (addr.isNotEmpty && (_model.lat == null || _model.lng == null)) {
      final ok = await _model.geocodeAddress();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_model.geocodeError ?? 'Failed to resolve address')),
        );
        return;
      }
    }

    // Build Firestore data
    final data = <String, dynamic>{
      'title': _model.taskTextController?.text.trim(),
      'description': _model.descriptionTextController?.text.trim(),
      'dueDate': _model.datePicked != null ? Timestamp.fromDate(_model.datePicked!) : null,
      'imageURL': _model.uploadedFileUrl.isNotEmpty ? _model.uploadedFileUrl : null,
      'address': addr.isNotEmpty ? addr : null,
      'lat': _model.lat,
      'lng': _model.lng,

      /// key: link ToDo to user
      'createdBy': uid,

      /// Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    }..removeWhere((k, v) => v == null);

    try {
      await ToDoItemsRecord.collection.doc().set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ToDo created successfully')),
      );

      if (mounted) context.pop(true); // notify list page to refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create ToDo',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
              ),
              Text(
                'Please fill out the form below to continue.',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: 'Readex Pro',
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 12, 8),
              child: FlutterFlowIconButton(
                borderColor: FlutterFlowTheme.of(context).alternate,
                borderRadius: 12,
                borderWidth: 1,
                buttonSize: 40,
                fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                icon: Icon(
                  Icons.close_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
                onPressed: () => context.safePop(),
              ),
            ),
          ],
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Form(
            key: _model.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// --- TITLE INPUT ---
                          TextFormField(
                            controller: _model.taskTextController,
                            focusNode: _model.taskFocusNode,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Title...',
                              labelStyle: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                              contentPadding:
                              const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 20),
                            ),
                            style: FlutterFlowTheme.of(context).headlineMedium,
                            validator: _model.taskTextControllerValidator.asValidator(context),
                          ),

                          /// --- DESCRIPTION INPUT ---
                          TextFormField(
                            controller: _model.descriptionTextController,
                            focusNode: _model.descriptionFocusNode,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 9,
                            minLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Description...',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                              contentPadding:
                              const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                            ),
                            style: FlutterFlowTheme.of(context).bodyLarge,
                            validator:
                            _model.descriptionTextControllerValidator.asValidator(context),
                          ),

                          /// --- ADDRESS INPUT ---
                          TextFormField(
                            controller: _model.addressTextController,
                            focusNode: _model.addressFocusNode,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              labelText: 'Address / Location',
                              hintText: 'Example: Costco, 2 Mystic View Rd, Everett, MA',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              suffixIcon: _model.isGeocoding
                                  ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                                  : IconButton(
                                tooltip: 'Resolve to coordinates',
                                icon: const Icon(Icons.place),
                                onPressed: _tryGeocodeAndToast,
                              ),
                            ),
                            onFieldSubmitted: (_) => _tryGeocodeAndToast(),
                          ),

                          /// --- DUE DATE ---
                          const SizedBox(height: 8),
                          Text(
                            'Due Date',
                            style: FlutterFlowTheme.of(context).labelMedium,
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _model.datePicked ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) {
                                setState(() => _model.datePicked = picked);
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding:
                              const EdgeInsetsDirectional.fromSTEB(12.0, 0, 12.0, 0),
                              child: Text(
                                valueOrDefault<String>(
                                  dateTimeFormat('MMMEd', _model.datePicked),
                                  'Select a date',
                                ),
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ),
                          ),

                          /// --- IMAGE UPLOAD ---
                          const SizedBox(height: 12),
                          FFButtonWidget(
                            onPressed: () async {
                              final selectedMedia = await selectMediaWithSourceBottomSheet(
                                context: context,
                                allowPhoto: true,
                              );
                              if (selectedMedia == null ||
                                  !selectedMedia.every(
                                          (m) => validateFileFormat(m.storagePath, context))) {
                                return;
                              }
                              setState(() => _model.isDataUploading = true);

                              showUploadMessage(
                                context,
                                'Uploading image...',
                                showLoading: true,
                              );

                              try {
                                final urls = await Future.wait(
                                  selectedMedia.map(
                                        (m) => uploadData(m.storagePath, m.bytes),
                                  ),
                                );

                                final validUrls = urls.whereType<String>().toList();
                                if (validUrls.isNotEmpty) {
                                  setState(() => _model.uploadedFileUrl = validUrls.first);
                                  showUploadMessage(context, 'Upload successful!');
                                } else {
                                  showUploadMessage(context, 'Failed to upload');
                                }
                              } finally {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                setState(() => _model.isDataUploading = false);
                              }
                            },
                            text: 'Add Image',
                            options: FFButtonOptions(
                              height: 40,
                              padding:
                              const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Readex Pro',
                                color: Colors.white,
                              ),
                              elevation: 3,
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          if (_model.uploadedFileUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _model.uploadedFileUrl,
                                  width: 300,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// --- SUBMIT BUTTON ---
                Container(
                  constraints: const BoxConstraints(maxWidth: 770),
                  padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
                  child: FFButtonWidget(
                    onPressed: _save,
                    text: 'Add New ToDo Item',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      padding:
                      const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Readex Pro',
                        color: Colors.white,
                      ),
                      elevation: 3,
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
