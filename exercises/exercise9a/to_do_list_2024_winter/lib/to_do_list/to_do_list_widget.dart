import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'to_do_list_model.dart';
export 'to_do_list_model.dart';

class ToDoListWidget extends StatefulWidget {
  const ToDoListWidget({super.key});

  @override
  State<ToDoListWidget> createState() => _ToDoListWidgetState();
}

class _ToDoListWidgetState extends State<ToDoListWidget> {
  late ToDoListModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = ToDoListModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Firestore query: only fetch current user's todos, ordered by createdAt desc
  Query<Map<String, dynamic>> _query() {
    final col = FirebaseFirestore.instance.collection('ToDoItems');

    // currentUserUid comes from auth_util.dart; assume user is logged in
    final uid = currentUserUid;

    if (uid.isEmpty) {
      // In theory this should not happen (user shouldn't reach this page when logged out),
      // but return a query that will never match anything to avoid errors.
      return col.where('createdBy', isEqualTo: '__no_user__');
    }

    return col
        .where('createdBy', isEqualTo: uid)          // Filter by current user
        .orderBy('createdAt', descending: true);     // Newest first
  }

  @override
  Widget build(BuildContext context) {
    // Keep compatibility with FlutterFlow paging model (even if not used directly here)
    _model.setListViewController(_query());

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'ToDo List',
            style: FlutterFlowTheme.of(context).displaySmall.override(
              fontFamily: 'Outfit',
              letterSpacing: 0.0,
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: FFButtonWidget(
                onPressed: () async {
                  GoRouter.of(context).prepareAuthEvent();
                  await authManager.signOut();
                  GoRouter.of(context).clearRedirectLocation();
                  // ignore: use_build_context_synchronously
                  context.goNamedAuth('Login', context.mounted);
                },
                text: 'Logout',
                options: FFButtonOptions(
                  height: 40.0,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      24.0, 0.0, 24.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Readex Pro',
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
                  elevation: 3.0,
                  borderSide: const BorderSide(
                      color: Colors.transparent, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),

        // ===== List =====
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _query().snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                  child: Text('Failed to load: ${snap.error}'));
            }
            final docs = snap.data?.docs ?? const [];

            if (docs.isEmpty) {
              return const Center(child: Text('No ToDo items yet'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Simple refresh; StreamBuilder will handle updates
                await Future<void>.delayed(
                    const Duration(milliseconds: 300));
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data();

                  final title = (data['title'] ?? '').toString();
                  final desc = (data['description'] ?? '').toString();
                  final addr = (data['address'] ?? '').toString();

                  final subtitleText =
                  addr.isNotEmpty ? addr : (desc.isNotEmpty ? desc : '');

                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      title.isEmpty ? '(No title)' : title,
                      style: FlutterFlowTheme.of(context)
                          .titleLarge
                          .override(
                        fontFamily: 'Outfit',
                        letterSpacing: 0.0,
                      ),
                    ),
                    subtitle: subtitleText.isEmpty
                        ? null
                        : Text(
                      subtitleText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context)
                          .labelMedium
                          .override(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0.0,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20.0,
                    ),
                    onTap: () {
                      context.pushNamed(
                        'ToDoItemDetails',
                        queryParameters: {
                          'docId':
                          serializeParam(doc.id, ParamType.String),
                          'title':
                          serializeParam(title, ParamType.String),
                        }.withoutNulls,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          elevation: 8.0,
          onPressed: () async {
            final changed = await context.pushNamed('NewToDoItem');
            if (changed == true) {
              _model.listViewPagingController?.refresh();
            }
          },
          child: Icon(
            Icons.add,
            color: FlutterFlowTheme.of(context).info,
            size: 24.0,
          ),
        ),
      ),
    );
  }
}
