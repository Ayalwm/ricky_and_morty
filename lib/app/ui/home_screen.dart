import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rick_and_morty/app/model/character.dart';
import 'package:rick_and_morty/app/utils/query.dart';
import 'package:rick_and_morty/app/widgets/character_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/logo.png",
          height: 62,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 150,
              height: 36,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 140,
              height: 36,
              child: DropdownButton<String>(
                hint:
                    const Text("Gender", style: TextStyle(color: Colors.grey)),
                value: _selectedGender,
                isDense: true,
                items: <String>['All', 'Male', 'Female', 'unknown']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value == 'All' ? null : value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                underline: Container(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: TextStyle(color: Colors.black87, fontSize: 16),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Query(
                  options: QueryOptions(
                    fetchPolicy: FetchPolicy.cacheAndNetwork,
                    document: getAllCharachters(),
                    variables: const {"page": 1},
                  ),
                  builder: (result, {fetchMore, refetch}) {
                    if (result.data != null) {
                      int? nextPage = 1;
                      List<Character> characters =
                          (result.data!["characters"]["results"] as List)
                              .map((e) => Character.fromMap(e))
                              .toList();

                      nextPage = result.data!["characters"]["info"]["next"];

                      List<Character> filteredCharacters = characters
                          .where((character) =>
                              character.name
                                  .toLowerCase()
                                  .contains(_searchText.toLowerCase()) &&
                              (_selectedGender == null ||
                                  character.gender.toLowerCase() ==
                                      _selectedGender!.toLowerCase()))
                          .toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          await refetch!();
                          nextPage = 1;
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Center(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: filteredCharacters
                                      .map((e) => CharacterWidget(character: e))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (nextPage != null)
                                ElevatedButton(
                                    onPressed: () async {
                                      FetchMoreOptions opts = FetchMoreOptions(
                                        variables: {'page': nextPage},
                                        updateQuery: (previousResultData,
                                            fetchMoreResultData) {
                                          final List<dynamic> repos = [
                                            ...previousResultData!["characters"]
                                                ["results"] as List<dynamic>,
                                            ...fetchMoreResultData![
                                                    "characters"]["results"]
                                                as List<dynamic>
                                          ];
                                          fetchMoreResultData["characters"]
                                              ["results"] = repos;
                                          return fetchMoreResultData;
                                        },
                                      );
                                      await fetchMore!(opts);
                                    },
                                    child: result.isLoading
                                        ? const CircularProgressIndicator
                                            .adaptive()
                                        : const Text("Load More"))
                            ],
                          ),
                        ),
                      );
                    } else if (result.data == null) {
                      return const Text("Data Not Found!");
                    } else if (result.isLoading) {
                      return const Center(child: Text("Loading..."));
                    } else {
                      return const Center(
                          child: Center(child: Text("Something went wrong")));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
