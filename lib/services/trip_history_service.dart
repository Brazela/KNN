import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class TripHistoryService {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'trips.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id TEXT PRIMARY KEY,
            origin_lat REAL NOT NULL,
            origin_lng REAL NOT NULL,
            origin_address TEXT,
            origin_place_id TEXT,
            dest_lat REAL NOT NULL,
            dest_lng REAL NOT NULL,
            dest_address TEXT,
            dest_place_id TEXT,
            mode INTEGER NOT NULL,
            cost REAL NOT NULL,
            time_minutes INTEGER NOT NULL,
            date TEXT NOT NULL,
            weather_json TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert(
      'trips',
      {
        'id': trip.id,
        'origin_lat': trip.origin.latitude,
        'origin_lng': trip.origin.longitude,
        'origin_address': trip.origin.address,
        'origin_place_id': trip.origin.placeId,
        'dest_lat': trip.destination.latitude,
        'dest_lng': trip.destination.longitude,
        'dest_address': trip.destination.address,
        'dest_place_id': trip.destination.placeId,
        'mode': trip.mode == TravelMode.transit ? 0 : 1,
        'cost': trip.cost,
        'time_minutes': trip.timeMinutes,
        'date': trip.date.toIso8601String(),
        'weather_json': trip.weather != null ? jsonEncode(trip.weather!.toJson()) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Trip>> getTrips({
    TravelMode? mode,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final params = <dynamic>[];

    if (mode != null) {
      conditions.add('mode = ?');
      params.add(mode == TravelMode.transit ? 0 : 1);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(origin_address LIKE ? OR dest_address LIKE ?)');
      final q = '%$searchQuery%';
      params.addAll([q, q]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final rows = await db.rawQuery(
      'SELECT * FROM trips $where ORDER BY date DESC LIMIT ? OFFSET ?',
      [...params, limit, offset],
    );

    return rows.map(_rowToTrip).toList();
  }

  Future<int> countTrips({
    TravelMode? mode,
    String? searchQuery,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final params = <dynamic>[];

    if (mode != null) {
      conditions.add('mode = ?');
      params.add(mode == TravelMode.transit ? 0 : 1);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(origin_address LIKE ? OR dest_address LIKE ?)');
      final q = '%$searchQuery%';
      params.addAll([q, q]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM trips $where',
      params,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT * FROM trips ORDER BY date DESC');
    return rows.map(_rowToTrip).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('trips');
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Trip _rowToTrip(Map<String, dynamic> row) {
    return Trip(
      id: row['id'] as String,
      origin: Location(
        latitude: (row['origin_lat'] as num).toDouble(),
        longitude: (row['origin_lng'] as num).toDouble(),
        address: row['origin_address'] as String?,
        placeId: row['origin_place_id'] as String?,
      ),
      destination: Location(
        latitude: (row['dest_lat'] as num).toDouble(),
        longitude: (row['dest_lng'] as num).toDouble(),
        address: row['dest_address'] as String?,
        placeId: row['dest_place_id'] as String?,
      ),
      mode: row['mode'] == 0 ? TravelMode.transit : TravelMode.driving,
      cost: (row['cost'] as num).toDouble(),
      timeMinutes: row['time_minutes'] as int,
      date: DateTime.parse(row['date'] as String),
      weather: row['weather_json'] != null
          ? Weather.fromJson(jsonDecode(row['weather_json'] as String) as Map<String, dynamic>)
          : null,
    );
  }
}
