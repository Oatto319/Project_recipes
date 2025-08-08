import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RecipeListScreen(),
    );
  }
}

class Recipe {
  final String name;
  final String imageUrl;
  final double price;
  final double rating;

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // ไม่สุ่มราคาและ rating ให้ใช้จาก API ถ้ามี ถ้าไม่มีให้เป็น 0
    return Recipe(
      name: json['name']?.toString() ?? 'No Name',
      imageUrl: json['image']?.toString() ?? '',
      price: (json['price'] != null)
          ? (json['price'] as num).toDouble()
          : 0,
      rating: (json['rating'] != null)
          ? (json['rating'] as num).toDouble()
          : 0,
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<Recipe>> _recipes;

  Future<List<Recipe>> fetchRecipes() async {
    const apiUrl = 'https://dummyjson.com/recipes';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List recipes = data['recipes'];
      // เรียงลำดับตาม rating มากไปน้อย
      List<Recipe> recipeList = recipes.map<Recipe>((r) => Recipe.fromJson(r)).toList();
      recipeList.sort((a, b) => b.rating.compareTo(a.rating));
      return recipeList;
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  @override
  void initState() {
    super.initState();
    _recipes = fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: Colors.deepOrange,
        elevation: 8,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Recipe>>(
          future: _recipes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No recipes found.'));
            }
            final recipes = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: recipes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  elevation: 8,
                  shadowColor: Colors.deepOrange.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {},
                    child: Row(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepOrange.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: recipe.imageUrl.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        recipe.imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: Colors.orange[100],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.3),
                                                Colors.transparent
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.orange[100],
                                    child: const Icon(Icons.restaurant_menu, size: 48, color: Colors.deepOrange),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.deepOrange,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ...List.generate(
                                      recipe.rating.floor(),
                                      (i) => const Icon(Icons.star, color: Colors.amber, size: 18),
                                    ),
                                    if (recipe.rating - recipe.rating.floor() >= 0.5)
                                      const Icon(Icons.star_half, color: Colors.amber, size: 18),
                                    ...List.generate(
                                      5 - recipe.rating.ceil(),
                                      (i) => const Icon(Icons.star_border, color: Colors.amber, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      recipe.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ราคา ${recipe.price.toStringAsFixed(0)} บาท',
                                  style: const TextStyle(
                                    color: Colors.brown,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap for details',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

