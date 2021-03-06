import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Format Dates
import 'package:journal_app/classes/database.dart';
import 'package:journal_app/pages/edit_entry.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Database _database;

  Future<List<Journal>> _loadJournals() async {
    await DatabaseFileRoutines().readJournals().then((journalsJason) {
      _database = databaseFromJson(journalsJason);
      _database.journal
          .sort((comp1, comp2) => comp2.date.compareTo(comp1.date));
    });

    return _database.journal;
  }

  void _addOrEditJournal({bool add, int index, Journal journal}) async {
    JournalEdit _journalEdit = JournalEdit(action: '', journal: journal);
    _journalEdit = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditEntry(
                add: add,
                index: index,
                journalEdit: _journalEdit,
              ),
          fullscreenDialog: true),
    );

    switch (_journalEdit.action) {
      case 'Save':
        if (add) {
          setState(() {
            _database.journal.add(_journalEdit.journal);
          });
        } else {
          setState(() {
            _database.journal[index] = _journalEdit.journal;
          });
        }
        DatabaseFileRoutines().writeJournals(databaseToJson(_database));
        break;
      case 'Cancel':
        break;
      default:
        break;
    }
  }

  _buildListViewSeparated(AsyncSnapshot snapshot) {
    return ListView.separated(
      padding: EdgeInsets.all(16.0),
      // itemBuilder: itemBuilder, separatorBuilder: separatorBuilder, itemCount: itemCount
      itemCount: snapshot.data.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        String _titleDate = DateFormat.yMMMd()
            .format(DateTime.parse(snapshot.data[index].date));
        String _subtitle =
            snapshot.data[index].mood + "\n" + snapshot.data[index].note;

        return Dismissible(
          key: Key(snapshot.data[index].id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: ListTile(
            leading: Column(
              children: [
                Text(
                  DateFormat.d()
                      .format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32.0,
                      color: Colors.blue),
                ),
                Text(
                  DateFormat.E()
                      .format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: Text(_subtitle),
            onTap: () async {
              _addOrEditJournal(
                  add: false, index: index, journal: snapshot.data[index]);
            },
          ),
          onDismissed: (direction) {
            setState(() {
              _database.journal.removeAt(index);
            });
            DatabaseFileRoutines().writeJournals(databaseToJson(_database));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Journal App"),
      ),
      body: FutureBuilder(
        initialData: [],
        future: _loadJournals(),
        builder: (context, snapshot) {
          return !snapshot.hasData
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _buildListViewSeparated(snapshot);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addOrEditJournal(add: true, index: -1, journal: Journal());
        },
      ),
    );
  }
}
