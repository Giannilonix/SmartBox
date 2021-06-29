import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {

  static final _databaseName = 'my_database.db';
  static final _databaseVersion = 1;

  static final table = 'Messages';

  static final columnId = '_id';
  static final columnName = 'name';
  static final columnAge = 'age';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE Messages ("
          "time TEXT PRIMARY KEY,"
          "latitude TEXT,"
          "longitude TEXT,"
          "s_temp REAL,"
          "b_temp REAL,"
          "b_pressure REAL,"
          "b_altitude REAL,"
          "b_humidity REAL,"
          "accx REAL,"
          "accy REAL,"
          "accz REAL,"
          "gyrox REAL,"
          "gyroy REAL,"
          "gyroz REAL,"
          "angley INTEGER,"
          "anglex INTEGER,"
          "anglez INTEGER"
          ")",
    );
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> querylog(String _date) async {
    Database db = await instance.database;
    _date=_date+"%";
    var _result = await db.rawQuery('SELECT * FROM $table WHERE time LIKE "$_date" ORDER BY time');
    return _result.toList();
  }
  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> deleteDailyLog(String _date) async {
    Database db = await instance.database;
    _date=_date+"%";
    return await db.delete(table, where: 'time LIKE "$_date"');
  }
  Future<int> clear() async {
    Database db = await instance.database;
    await db.execute("DROP TABLE IF EXISTS $table");
  }
}



/*CREATE TABLE Messages (time TEXT PRIMARY KEY, latitude TEXT,longitude TEXT, s_temp REAL,b_temp REAL, b_pressure REAL,b_altitude REAL, b_humidity REAL,accx REAL, accy REAL,
accz REAL,gyrox REAL,gyroy REAL, gyroz REAL,angley INTEGER, anglex INTEGER,anglez INTEGER)

 */