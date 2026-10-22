import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_4/DataBase/Model/contact_model.dart';

class ContactHelper {
  ContactHelper._internal();
  static final ContactHelper _instance = ContactHelper._internal();
  factory ContactHelper() => _instance;

  Database? _db;
  Future<Database> get db async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'contacts.db');
    return openDatabase(path, version: 2,
      onCreate: (database, version) async {
        await database.execute(
          '''CREATE TABLE $contactTable (
            $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $nameColumn TEXT NOT NULL,
            $emailColumn TEXT NOT NULL,
            $phoneColumn TEXT NOT NULL,
            $imgColumn TEXT,
            $cepColumn TEXT NOT NULL DEFAULT '',
            $streetColumn TEXT NOT NULL DEFAULT '',
            $neighborhoodColumn TEXT NOT NULL DEFAULT '',
            $cityColumn TEXT NOT NULL DEFAULT '',
            $stateColumn TEXT NOT NULL DEFAULT '',
            $numberColumn TEXT NOT NULL DEFAULT '',
            $complementColumn TEXT NOT NULL DEFAULT ''
          )'''
        );
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final column in [
            "$cepColumn TEXT NOT NULL DEFAULT ''",
            "$streetColumn TEXT NOT NULL DEFAULT ''",
            "$neighborhoodColumn TEXT NOT NULL DEFAULT ''",
            "$cityColumn TEXT NOT NULL DEFAULT ''",
            "$stateColumn TEXT NOT NULL DEFAULT ''",
            "$numberColumn TEXT NOT NULL DEFAULT ''",
            "$complementColumn TEXT NOT NULL DEFAULT ''",
          ]) {
            await database.execute('ALTER TABLE $contactTable ADD COLUMN $column');
          }
        }
      },
    );
  }

  Future<Contact> saveContact(Contact contact) async {
    final database = await db;
    contact.id = await database.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact?> getContact(int id) async {
    final rows = await (await db).query(contactTable,
        where: '$idColumn = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Contact.fromMap(rows.first);
  }

  Future<List<Contact>> getAllContacts() async {
    final rows = await (await db).query(contactTable, orderBy: '$nameColumn COLLATE NOCASE');
    return rows.map(Contact.fromMap).toList();
  }

  Future<int> updateContact(Contact contact) async => (await db).update(
        contactTable, contact.toMap(), where: '$idColumn = ?', whereArgs: [contact.id]);

  Future<int> deleteContact(int id) async => (await db).delete(
        contactTable, where: '$idColumn = ?', whereArgs: [id]);
}
