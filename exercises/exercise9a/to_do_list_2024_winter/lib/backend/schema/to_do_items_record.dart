// lib/backend/schema/to_do_items_record.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

class ToDoItemsRecord extends FirestoreRecord {
  ToDoItemsRecord._(DocumentReference reference, Map<String, dynamic> data)
      : super(reference, data) {
    _initializeFields();
  }

  String? _title;               // title / Title
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  String? _description;         // description / Description
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  DateTime? _dueDate;           // dueDate (Timestamp) / DueDate
  DateTime? get dueDate => _dueDate;
  bool hasDueDate() => _dueDate != null;

  String? _imageURL;            // imageURL / ImageURL
  String get imageURL => _imageURL ?? '';
  bool hasImageURL() => _imageURL != null;

  String? _address;             // address / Address
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  double? _lat;                 // lat / Lat
  double? get lat => _lat;
  bool hasLat() => _lat != null;

  double? _lng;                 // lng / Lng
  double? get lng => _lng;
  bool hasLng() => _lng != null;

  String? _createdBy;           // createdBy / CreatedBy
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _title       = (snapshotData['title'] ?? snapshotData['Title']) as String?;
    _description = (snapshotData['description'] ?? snapshotData['Description']) as String?;
    _imageURL    = (snapshotData['imageURL'] ?? snapshotData['ImageURL']) as String?;
    _address     = (snapshotData['address'] ?? snapshotData['Address']) as String?;
    _createdBy   = (snapshotData['createdBy'] ?? snapshotData['CreatedBy']) as String?;

    final vDue = (snapshotData['dueDate'] ?? snapshotData['DueDate']);
    if (vDue is Timestamp) {
      _dueDate = vDue.toDate();
    } else if (vDue is DateTime) {
      _dueDate = vDue;
    } else {
      _dueDate = null;
    }

    final vCreated = (snapshotData['createdAt'] ?? snapshotData['CreatedAt']);
    if (vCreated is Timestamp) {
      _createdAt = vCreated.toDate();
    } else if (vCreated is DateTime) {
      _createdAt = vCreated;
    } else {
      final createdAtMs = (snapshotData['CreatedAtMs'] as num?)?.toInt();
      _createdAt = createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : null;
    }

    _lat = ((snapshotData['lat'] ?? snapshotData['Lat']) as num?)?.toDouble();
    _lng = ((snapshotData['lng'] ?? snapshotData['Lng']) as num?)?.toDouble();
  }


  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ToDoItems');

  static Stream<ToDoItemsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ToDoItemsRecord.fromSnapshot(s));
  static Future<ToDoItemsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ToDoItemsRecord.fromSnapshot(s));
  static ToDoItemsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ToDoItemsRecord._(snapshot.reference, mapFromFirestore(snapshot.data() as Map<String, dynamic>));
  static ToDoItemsRecord getDocumentFromData(Map<String, dynamic> data, DocumentReference reference) =>
      ToDoItemsRecord._(reference, mapFromFirestore(data));
}

Map<String, dynamic> createToDoItemsRecordData({
  String? title,
  String? description,
  DateTime? dueDate,
  String? imageURL,
  String? address,
  double? lat,
  double? lng,
  String? createdBy,
  DateTime? createdAt,
}) {
  final map = <String, dynamic>{
    'title': title,
    'description': description,
    'dueDate': dueDate,
    'imageURL': imageURL,
    'address': address,
    'lat': lat,
    'lng': lng,
    'createdBy': createdBy,
    'createdAt': createdAt ?? DateTime.now(),
  }..removeWhere((k, v) => v == null);

  return mapToFirestore(map);
}
