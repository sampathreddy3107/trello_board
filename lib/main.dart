import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(FlutterListsApp());
}

class FlutterListsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Lists',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ListsPage(),
    );
  }
}

class ListsPage extends StatefulWidget {
  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  List<ListModel> lists = [];

  @override
  void initState() {
    super.initState();
    lists = [
      ListModel(title: 'List 1', items: []),
      ListModel(title: 'List 2', items: []),
    ];
  }

  void addNewItem(int listIndex, String newItem) {
    setState(() {
      lists[listIndex].items.add(newItem);
    });
  }

  void removeItem(int listIndex, int itemIndex) {
    setState(() {
      lists[listIndex].items.removeAt(itemIndex);
    });
  }

  void removeList(int listIndex) {
    setState(() {
      lists.removeAt(listIndex);
    });
  }

  void reorderLists(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final ListModel list = lists.removeAt(oldIndex);
      lists.insert(newIndex, list);
    });
  }

  void reorderItems(int listIndex, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = lists[listIndex].items.removeAt(oldIndex);
      lists[listIndex].items.insert(newIndex, item);
    });
  }

  void resetList(int listIndex) {
    setState(() {
      lists[listIndex].items.clear();
    });
  }

  void filterList(int listIndex, String searchTerm) {
    setState(() {
      lists[listIndex].filteredItems = lists[listIndex].items
          .where((item) => item.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  void resetFilter(int listIndex) {
    setState(() {
      lists[listIndex].filteredItems = lists[listIndex].items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Lists'),
      ),
      body: ListView.builder(
        itemCount: lists.length,
        itemBuilder: (context, index) {
          return ListWidget(
            list: lists[index],
            onAddItem: (newItem) => addNewItem(index, newItem),
            onRemoveItem: (itemIndex) => removeItem(index, itemIndex),
            onRemoveList: () => removeList(index),
            onReorderLists: (oldIndex, newIndex) =>
                reorderLists(oldIndex, newIndex),
            onReorderItems: (oldIndex, newIndex) =>
                reorderItems(index, oldIndex, newIndex),
            onResetList: () => resetList(index),
            onFilterList: (searchTerm) => filterList(index, searchTerm),
            onResetFilter: () => resetFilter(index), key: Key("item"),
          );
        },
      ),
    );
  }
}

class ListWidget extends StatefulWidget {
  final ListModel list;
  final Function(String) onAddItem;
  final Function(int) onRemoveItem;
  final VoidCallback onRemoveList;
  final Function(int, int) onReorderLists;
  final Function(int, int) onReorderItems;
  final VoidCallback onResetList;
  final Function(String) onFilterList;
  final VoidCallback onResetFilter;

  const ListWidget({
    required Key key,
    required this.list,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onRemoveList,
    required this.onReorderLists,
    required this.onReorderItems,
    required this.onResetList,
    required this.onFilterList,
    required this.onResetFilter,
  }) : super(key: key);

  @override
  _ListWidgetState createState() => _ListWidgetState();
}


class _ListWidgetState extends State<ListWidget> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onAddItem(_textEditingController.text);
        _textEditingController.clear();
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleRemoveItem(int itemIndex) {
    widget.onRemoveItem(itemIndex);
    _listKey.currentState?.removeItem(
      itemIndex,
          (BuildContext context, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: Container(),
        );
      },
      duration: const Duration(milliseconds: 300),
    );
  }

  void _handleReorderItems(int oldIndex, int newIndex) {
    widget.onReorderItems(oldIndex, newIndex);
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    final item = widget.list.filteredItems[index];
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        key: ValueKey(item ?? ''),
        title: Text(item),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _handleRemoveItem(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.list.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: widget.onRemoveList,
              ),
            ],
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _textEditingController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Enter a new item',
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _focusNode.unfocus(),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchTerm = '';
                          widget.onResetFilter();
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                      widget.onFilterList(value);
                    });
                  },
                ),
              ),
              SizedBox(width: 8.0),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchTerm = '';
                    widget.onResetFilter();
                  });
                },
                child: Text('Reset'),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemBuilder: _buildItem,
            initialItemCount: widget.list.filteredItems.length,
          ),
        ],
      ),
    );
  }
}

class ListModel {
  final String title;
  final List<String> items;
  List<String> filteredItems;

  ListModel({required this.title, required this.items}) : filteredItems = List.from(items);
}
