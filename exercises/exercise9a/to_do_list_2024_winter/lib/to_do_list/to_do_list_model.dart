import 'dart:async';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart'; // Provides FlutterFlowModel
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'to_do_list_widget.dart' show ToDoListWidget;

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class ToDoListModel extends FlutterFlowModel<ToDoListWidget> {
  /// Focus node
  final unfocusNode = FocusNode();

  /// Paging
  PagingController<DocumentSnapshot?, ToDoItemsRecord>? listViewPagingController;
  Query? listViewPagingQuery;
  final List<StreamSubscription?> listViewStreamSubscriptions = [];

  @override
  void initState(BuildContext context) {
    // no-op
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    for (final s in listViewStreamSubscriptions) {
      s?.cancel();
    }
    listViewPagingController?.dispose();
  }

  /// Attach the query to the page and return the paging controller
  PagingController<DocumentSnapshot?, ToDoItemsRecord> setListViewController(
      Query query, {
        DocumentReference<Object?>? parent,
      }) {
    listViewPagingController ??= _createListViewController(query, parent);
    if (listViewPagingQuery != query) {
      listViewPagingQuery = query;
      listViewPagingController?.refresh();
    }
    return listViewPagingController!;
  }

  PagingController<DocumentSnapshot?, ToDoItemsRecord> _createListViewController(
      Query query,
      DocumentReference<Object?>? parent,
      ) {
    final controller =
    PagingController<DocumentSnapshot?, ToDoItemsRecord>(firstPageKey: null);

    controller.addPageRequestListener((nextPageMarker) {
      queryToDoItemsRecordPage(
        queryBuilder: (_) => listViewPagingQuery ??= query,
        nextPageMarker: nextPageMarker,
        streamSubscriptions: listViewStreamSubscriptions,
        controller: controller,
        pageSize: 25,
        isStream: true,
      );
    });

    return controller;
  }
}
