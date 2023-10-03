import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class MessageDatabase {
  static const String tableName = 'messages';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertMessage(String text, String timestamp) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        'text': text,
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    return await db.query(tableName);
  }
}
