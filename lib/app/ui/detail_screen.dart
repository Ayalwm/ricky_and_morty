import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty Character Details',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty Characters'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DetailScreen(id: '1'),
              ),
            );
          },
          child: const Text('Show Character Details'),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key, required this.id}) : super(key: key);

  final String id;

  Future<Map<String, dynamic>?> fetchCharacterDetails() async {
    try {
      final response = await http
          .get(Uri.parse('https://rickandmortyapi.com/api/character/$id'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load character details');
      }
    } catch (e) {
      print('Error fetching character details: $e');
      return null;
    }
  }

  Future<List<dynamic>?> fetchEpisodeDetails(List<String> episodeUrls) async {
    try {
      final episodesData = await Future.wait(
        episodeUrls.map((url) async {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final episodeData = json.decode(response.body);
            final charactersUrls = List<String>.from(episodeData['characters']);
            final random = Random();
            final randomCharacterUrl =
                charactersUrls[random.nextInt(charactersUrls.length)];
            final characterResponse =
                await http.get(Uri.parse(randomCharacterUrl));
            if (characterResponse.statusCode == 200) {
              final characterData = json.decode(characterResponse.body);
              return {
                'episode': episodeData['episode'],
                'name': episodeData['name'],
                'air_date': episodeData['air_date'],
                'image': characterData['image'],
              };
            } else {
              throw Exception('Failed to load character details for episode');
            }
          } else {
            throw Exception('Failed to load episode details');
          }
        }),
      );

      return episodesData;
    } catch (e) {
      print('Error fetching episode details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Character Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchCharacterDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No character details found.'));
          } else {
            final character = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: character['image'] != null
                        ? Image.network(character['image'])
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    character['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 4),
                      Text(character['species'] ?? 'Unknown'),
                      const SizedBox(width: 16),
                      const Icon(Icons.male),
                      const SizedBox(width: 4),
                      Text(character['gender'] ?? 'Unknown'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 4),
                      Text(character['location']['name'] ?? 'Unknown'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Episodes:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<dynamic>?>(
                    future: fetchEpisodeDetails(
                        List<String>.from(character['episode'] ?? [])),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(child: Text('No episodes found.'));
                      } else {
                        final episodes = snapshot.data!;
                        return Column(
                          children: episodes.map((episode) {
                            return Card(
                              child: ListTile(
                                leading: episode['image'] != null
                                    ? Image.network(
                                        episode['image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox.shrink(),
                                title: Text(
                                  episode['episode'] != null
                                      ? 'S${episode['episode'].toString().padLeft(2, '0')}'
                                      : 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  episode['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: Text(
                                  ' ${episode['air_date'] ?? 'Unknown'}',
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
