import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as g;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/flutter_flow/flutter_flow_widgets.dart';

import 'to_do_item_details_model.dart' as details_model;

class ToDoItemDetailsWidget extends StatefulWidget {
  const ToDoItemDetailsWidget({
    super.key,
    required this.docId,          // Firestore document id passed from list page
    required this.title,          // Fallback/AppBar title
    this.description,             // Fallback description before document loads
    this.initialAddress,          // Fallback address
    this.initialLat,              // Fallback coordinates
    this.initialLng,
    this.googleApiKey,            // Optional Distance Matrix API key
  });

  final String docId;
  final String title;
  final String? description;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final String? googleApiKey;

  @override
  State<ToDoItemDetailsWidget> createState() => _ToDoItemDetailsWidgetState();
}

class _ToDoItemDetailsWidgetState extends State<ToDoItemDetailsWidget>
    with TickerProviderStateMixin {
  late details_model.ToDoItemDetailsModel _model;

  bool _editingAddress = false;
  Position? _me;
  gmap.LatLng? _dest;
  gmap.GoogleMapController? _mapCtl;

  /// Cache last doc lat/lng so we don’t recompute on every build
  double? _lastDocLat;
  double? _lastDocLng;
  bool _pendingDestUpdate = false;
  bool _isCalculatingDriving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => details_model.ToDoItemDetailsModel());

    // Use initialAddress/Lat/Lng as placeholders before Firestore finishes loading
    if ((widget.initialAddress ?? '').isNotEmpty) {
      _model.addressController.text = widget.initialAddress!;
    }
    if (widget.initialLat != null && widget.initialLng != null) {
      _dest = gmap.LatLng(widget.initialLat!, widget.initialLng!);
      _lastDocLat = widget.initialLat;
      _lastDocLng = widget.initialLng;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initLocation();
      // If we already have a destination, compute distance + move camera once
      if (_dest != null && mounted) {
        await _recalcDistanceAndCamera();
      }
    });
  }

  @override
  void dispose() {
    _mapCtl?.dispose();
    _model.dispose();
    super.dispose();
  }

  // ===== Location (current device position) =====
  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw 'The location service is not enabled';

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Location permission has not been granted';
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _me = pos;
      });
    } catch (e) {
      _model.errorText = '$e';
      _snack('Positioning failure: $e');
    }
  }

  // ===== Address → coordinates and save to Firestore =====
  Future<void> _geocodeAndSave(String addr) async {
    final trimmed = addr.trim();
    if (trimmed.isEmpty) {
      _snack('Please enter the address first');
      return;
    }
    try {
      final list = await g.locationFromAddress(trimmed);
      if (list.isEmpty) throw 'The address cannot be parsed';
      final loc = list.first;

      await FirebaseFirestore.instance
          .collection('ToDoItems')
          .doc(widget.docId)
          .update({
        'address': trimmed,
        'lat': loc.latitude,
        'lng': loc.longitude,
      });

      if (!mounted) return;

      setState(() {
        _editingAddress = false;
        _dest = gmap.LatLng(loc.latitude, loc.longitude);
        _lastDocLat = loc.latitude;
        _lastDocLng = loc.longitude;
      });

      _snack('Location updated');

      // Re-sync distance + map camera
      await _recalcDistanceAndCamera();
    } catch (e) {
      _model.errorText = '$e';
      _snack('Failed to resolve the address: $e');
    }
  }

  /// Helper: recalc driving/straight-line distance and move camera
  Future<void> _recalcDistanceAndCamera() async {
    if (!mounted) return;
    await _calcDriving();
    if (!mounted) return;
    _moveCameraToDest();
  }

  // ===== Driving distance (fallback to straight-line if Distance Matrix fails) =====
  Future<void> _calcDriving() async {
    if (_me == null || _dest == null) return;
    if (_isCalculatingDriving) return; // avoid multiple concurrent calls

    _isCalculatingDriving = true;
    String? distanceText;

    String _straightLineText() {
      final meters = Geolocator.distanceBetween(
        _me!.latitude,
        _me!.longitude,
        _dest!.latitude,
        _dest!.longitude,
      );
      final km = (meters / 1000).toStringAsFixed(1);
      return 'About $km km (straight-line)';
    }

    final apiKey = widget.googleApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // No API key → straight-line distance only
      distanceText = _straightLineText();
    } else {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
            '?origins=${_me!.latitude},${_me!.longitude}'
            '&destinations=${_dest!.latitude},${_dest!.longitude}'
            '&mode=driving&units=metric&key=$apiKey',
      );

      try {
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final rows = data['rows'] as List?;
          final elements = rows?.first['elements'] as List?;
          final el = elements?.first as Map<String, dynamic>?;
          if (el != null && el['status'] == 'OK') {
            final distance = el['distance']?['text'] as String?;
            final duration = el['duration']?['text'] as String?;
            if (distance != null && duration != null) {
              distanceText = 'Driving: $distance (about $duration)';
            } else {
              distanceText = _straightLineText();
            }
          } else {
            distanceText = _straightLineText();
          }
        } else {
          distanceText = _straightLineText();
        }
      } catch (_) {
        distanceText = _straightLineText();
      }
    }

    if (!mounted) {
      _isCalculatingDriving = false;
      return;
    }

    setState(() {
      _model.drivingDistanceText = distanceText;
      _isCalculatingDriving = false;
    });
  }

  void _moveCameraToDest() {
    if (_dest == null || _mapCtl == null) return;
    _mapCtl!.animateCamera(
      gmap.CameraUpdate.newCameraPosition(
        gmap.CameraPosition(target: _dest!, zoom: 15),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openInMaps() async {
    if (_dest == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_dest!.latitude},${_dest!.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ToDoItems')
          .doc(widget.docId)
          .snapshots(),
      builder: (context, snap) {
        // Firestore document; if null, fall back to values passed via route
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};

        final title = (data['title'] ?? widget.title).toString();

        // Description / address (keep trimmed for description)
        final desc =
        (data['description'] ?? widget.description ?? '').toString().trim();
        final addr =
        (data['address'] ?? widget.initialAddress ?? '').toString();

        final lat = (data['lat'] as num?)?.toDouble() ?? widget.initialLat;
        final lng = (data['lng'] as num?)?.toDouble() ?? widget.initialLng;

        // Detect changes in lat/lng and recalc distance if needed
        if (lat != null && lng != null) {
          final changed = _lastDocLat != lat || _lastDocLng != lng;
          if (changed) {
            _lastDocLat = lat;
            _lastDocLng = lng;
            _dest = gmap.LatLng(lat, lng);

            if (!_pendingDestUpdate) {
              _pendingDestUpdate = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted || !_pendingDestUpdate) return;
                _pendingDestUpdate = false;
                await _recalcDistanceAndCamera();
              });
            }
          }
        }

        final markers = <gmap.Marker>{
          if (_dest != null)
            gmap.Marker(
              markerId: const gmap.MarkerId('todo_dest'),
              position: _dest!,
              infoWindow: gmap.InfoWindow(
                title: title,
                snippet: addr.isNotEmpty ? addr : null,
              ),
              icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
                gmap.BitmapDescriptor.hueRed,
              ),
            ),
        };

        final initialCamera = _dest != null
            ? gmap.CameraPosition(target: _dest!, zoom: 14)
            : const gmap.CameraPosition(
          target: gmap.LatLng(37.422, -122.084),
          zoom: 12,
        );

        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_model.unfocusNode),
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: snap.connectionState == ConnectionState.waiting &&
                (widget.description == null &&
                    widget.initialAddress == null)
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (context, constraints) {
                final mapHeight = constraints.maxHeight * 0.5;

                return Column(
                  children: [
                    // ----- Top half: Description + Address + Distance -----
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large bold text: show description if present, otherwise show title
                            const SizedBox(height: 4),
                            Text(
                              desc.isNotEmpty ? desc : title,
                              style: theme.titleLarge.override(
                                fontFamily: theme.titleLargeFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Address row (always visible)
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.place_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    addr.isNotEmpty
                                        ? addr
                                        : '(No address saved)',
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openInMaps,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Open in Maps'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _editingAddress = !_editingAddress;
                                      if (_editingAddress) {
                                        _model.addressController.text =
                                            addr;
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(
                                    _editingAddress ? 'Cancel' : 'Edit',
                                  ),
                                ),
                              ],
                            ),

                            if (_editingAddress) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller:
                                      _model.addressController,
                                      focusNode:
                                      _model.addressFocusNode,
                                      decoration:
                                      const InputDecoration(
                                        labelText: 'Address / Location',
                                        hintText:
                                        'e.g., 2 Mystic View Rd, Everett, MA',
                                        border: OutlineInputBorder(),
                                      ),
                                      textInputAction:
                                      TextInputAction.search,
                                      onSubmitted: (v) =>
                                          _geocodeAndSave(v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FFButtonWidget(
                                    onPressed: () => _geocodeAndSave(
                                        _model.addressController.text),
                                    text: 'Save',
                                    options: FFButtonOptions(
                                      height: 48,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      color: theme.primary,
                                      textStyle:
                                      theme.titleSmall.override(
                                        fontFamily:
                                        theme.titleSmallFamily,
                                        color: Colors.white,
                                      ),
                                      elevation: 2,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),

                            Text(
                              _model.drivingDistanceText ??
                                  (_me == null
                                      ? 'Getting current location…'
                                      : (_dest == null
                                      ? 'No location for this ToDo'
                                      : 'Calculating driving distance…')),
                              style: theme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ----- Bottom half: Map view -----
                    SizedBox(
                      height: mapHeight,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: gmap.GoogleMap(
                          initialCameraPosition: initialCamera,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          markers: markers,
                          onMapCreated: (c) {
                            _mapCtl = c;
                            if (_dest != null) {
                              _moveCameraToDest();
                            }
                          },
                          gestureRecognizers: <
                              Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer()),
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
