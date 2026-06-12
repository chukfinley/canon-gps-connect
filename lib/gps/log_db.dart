import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'nmea.dart';

/// Mirrors Canon's `i4.l` SQLite store (CCGpsLogDatabase.db).
/// Schema is byte-identical to the decompiled `onCreate`.
class GpsLogDb {
  GpsLogDb._(this._db);
  final Database _db;

  static GpsLogDb? _instance;

  static Future<GpsLogDb> open() async {
    if (_instance != null) return _instance!;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'CCGpsLogDatabase.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'create table CCGpsLogData ('
          'time integer primary key,'
          'latitude real not null,'
          'longitude real not null,'
          'altitude real not null,'
          'accuracy real not null,'
          'speed real not null,'
          'bearing real not null,'
          'nmea text not null)',
        );
        await db.execute(
          'create table CCGpsLogTerm ('
          'start integer primary key,'
          'end integer)',
        );
      },
    );
    return _instance = GpsLogDb._(db);
  }

  /// `i4.l.f` — insert/replace. Replace only if the new fix is more accurate
  /// for the same timestamp (Canon's dedup rule).
  Future<void> saveFix(NmeaFix fix) async {
    final existing = await _db.query('CCGpsLogData',
        where: 'time = ?', whereArgs: [fix.timeMillis], limit: 1);
    if (existing.isEmpty) {
      await _db.insert('CCGpsLogData', fix.toRow());
    } else {
      final oldAcc = (existing.first['accuracy'] as num).toDouble();
      if (fix.accuracy < oldAcc) {
        await _db.insert('CCGpsLogData', fix.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  /// `i4.n.i(time)` — nearest logged NMEA fix to a photo's UTC capture time.
  Future<NmeaFix?> nearestFix(int utcMillis) async {
    final rows = await _db.rawQuery(
      'select *, abs(time - ?) as d from CCGpsLogData order by d asc limit 1',
      [utcMillis],
    );
    if (rows.isEmpty) return null;
    return NmeaFix.fromRow(rows.first);
  }

  Future<List<NmeaFix>> fixesInRange(int startMs, int endMs) async {
    final rows = await _db.query('CCGpsLogData',
        where: 'time between ? and ?',
        whereArgs: [startMs, endMs],
        orderBy: 'time asc');
    return rows.map(NmeaFix.fromRow).toList();
  }

  Future<int> count() async {
    final r =
        await _db.rawQuery('select count(*) c from CCGpsLogData');
    return (r.first['c'] as num).toInt();
  }

  Future<void> beginTerm(int startMs) async {
    await _db.insert('CCGpsLogTerm', {'start': startMs, 'end': null},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> endTerm(int startMs, int endMs) async {
    await _db.update('CCGpsLogTerm', {'end': endMs},
        where: 'start = ?', whereArgs: [startMs]);
  }
}
