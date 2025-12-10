import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../services/firebase_service.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<XFile?> _images = [];
  bool _isSubmitting = false;

  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(42.3398, -71.0892);
  LatLng? _selectedLatLng;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _descController.clear();
    _addressController.clear();
    setState(() {
      _images = [];
      _selectedLatLng = null;
    });
  }

  void _ensureImageSlots(int index) {
    if (_images.length <= index) {
      _images = [
        ..._images,
        ...List<XFile?>.filled(index + 1 - _images.length, null),
      ];
    }
  }

  int _getNextImageIndex() {
    const maxImages = 4;
    for (int i = 0; i < maxImages; i++) {
      if (i >= _images.length || _images[i] == null) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _pickImageForSlot(int index, ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);
    if (img != null) {
      setState(() {
        _ensureImageSlots(index);
        _images[index] = img;
      });
    }
  }

  Future<void> _showImageSourcePicker(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageForSlot(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageForSlot(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerArea() {
    XFile? mainImg = _images.isNotEmpty ? _images[0] : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showImageSourcePicker(0),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.shade100,
                  ),
                  child: mainImg == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap to add cover photo',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(mainImg.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                final idx = _getNextImageIndex();
                if (idx == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You can attach up to 4 photos'),
                    ),
                  );
                  return;
                }
                _showImageSourcePicker(idx);
              },
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF3E5F5),
                  border: Border.all(
                    color: const Color(0xFFCE93D8),
                    width: 1.8,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 34,
                    color: Color(0xFF8E24AA),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubImagesRow() {
    List<Widget> slots = [];
    for (int i = 1; i <= 3; i++) {
      XFile? img = i < _images.length ? _images[i] : null;
      slots.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _showImageSourcePicker(i),
            child: Container(
              height: 70,
              margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: img == null
                  ? Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(img.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(children: slots);
  }

  Future<void> _locateAddressOnMap() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address first')),
      );
      return;
    }

    try {
      final List<geo.Location> locations =
      await geo.locationFromAddress(address);

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find this address')),
        );
        return;
      }

      final loc = locations.first;
      final LatLng pos = LatLng(loc.latitude, loc.longitude);

      setState(() {
        _selectedLatLng = pos;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(pos, 14),
        );
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to locate this address')),
      );
    }
  }

  Widget _buildLocationPickerCard() {
    final LatLng center = _selectedLatLng ?? _defaultCenter;

    final markers = <Marker>{};
    if (_selectedLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('post_location'),
          position: _selectedLatLng!,
          infoWindow: const InfoWindow(title: 'Meet-up location'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet-up location',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              onTap: (LatLng pos) {
                setState(() {
                  _selectedLatLng = pos;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedLatLng == null
              ? 'Type an address and tap the pin icon, or tap on the map to set meet-up location.'
              : 'Selected: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, '
              '${_selectedLatLng!.longitude.toStringAsFixed(4)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(
      String label, {
        String? hint,
        String? helper,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      labelStyle: const TextStyle(
        color: Color(0xFF8E24AA),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF8E24AA),
          width: 2,
        ),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _onPostPressed() async {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();
    final desc = _descController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and price are required')),
      );
      return;
    }

    if (double.tryParse(price) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be numeric digits only')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Creating post, please wait...',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        );
      },
    );

    try {
      LatLng? finalLatLng = _selectedLatLng;

      if (finalLatLng == null && address.isNotEmpty) {
        try {
          final locations = await geo.locationFromAddress(address);
          if (locations.isNotEmpty) {
            final loc = locations.first;
            finalLatLng = LatLng(loc.latitude, loc.longitude);
          }
        } catch (e) {
          debugPrint('Geocoding on submit failed: $e');
        }
      }

      final imagesToUpload =
      _images.whereType<XFile>().toList(growable: false);

      await FirebaseService.createPost(
        title: title,
        price: price,
        description: desc,
        images: imagesToUpload,
        latitude: finalLatLng?.latitude,
        longitude: finalLatLng?.longitude,
        meetupAddress: address.isEmpty ? null : address,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add post: $e')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        elevation: 0,
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (value) {
              if (value == 'new') {
                _clearForm();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'new',
                child: Text('Clear form'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE1D9FF),
              Color(0xFFF7ECFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Create a post',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share second-hand items and find the right buyer.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildImagePickerArea(),
                            const SizedBox(height: 12),
                            _buildSubImagesRow(),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              decoration: _fieldDecoration(
                                'Item title',
                                hint: 'Example: “Brand new bag”',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _fieldDecoration(
                                'Price',
                                hint: 'Digits only, e.g. 100',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: _fieldDecoration(
                                'Description',
                                hint: 'Condition, etc.',
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _addressController,
                              maxLines: 1,
                              decoration: _fieldDecoration(
                                'Meet-up address (optional)',
                                hint:
                                'e.g. Northeastern University library',
                                helper:
                                'Type an address and tap the pin to locate it on the map.',
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.location_searching,
                                    color: Color(0xFF8E24AA),
                                  ),
                                  onPressed: _locateAddressOnMap,
                                  tooltip: 'Locate on map',
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            _buildLocationPickerCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.25),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _onPostPressed,
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text('Post now'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
