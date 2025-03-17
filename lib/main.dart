import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:carousel_slider/carousel_slider.dart';
import 'article_details.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Forum',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ArticlesScreen(),
    );
  }
}

class ArticlesScreen extends StatefulWidget {
  ArticlesScreen({super.key});

  @override
  _ArticlesScreenState createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _articles = [];
  bool _isLoading = true;

  late TabController _tabController; // Declare TabController
  final List<String> _tabs = ['Featured', 'Technology', 'Science']; // Define your sections

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this); // Initialize TabController
    _tabController.addListener(_onTabChanged); // Listen for tab changes
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    final response = await http.get(Uri.parse('https://thespartanforum.com/'));

    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      final articlesElements = document.querySelectorAll('.sno-story-card');

      if (articlesElements.isEmpty) {
        print("Something went wrong... please try again soon!");
      }

      List<Map<String, String>> articles = articlesElements.map((element) {
        final titleElement = element.querySelector('.sno-story-card-link a');
        final authorElement = element.querySelector('.creditline a');
        final imageElement = element.querySelector('img');

        final title = titleElement?.text ?? 'No Title';
        final url = titleElement?.attributes['href'] ?? '';
        final author = authorElement?.text ?? 'Unknown Author';
        final imageUrl = imageElement?.attributes['src'] ?? '';

        // Assign section based on the title or other criteria (for demo purposes)
        String section = 'Technology'; // You can customize this logic based on your needs
        if (title.toLowerCase().contains('science')) {
          section = 'Science';
        } else if (title.toLowerCase().contains('featured')) {
          section = 'Featured';
        }

        return {
          'title': title,
          'url': url,
          'author': author,
          'image': imageUrl,
          'section': section,
        };
      }).toList();

      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load articles');
    }
  }

  void _onTabChanged() {
    setState(() {}); // Trigger a rebuild when the tab changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Forum')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for an article...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          _buildArticleCarousel(),
          TabBar(
            controller: _tabController,
            tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
            indicatorColor: Colors.blue,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildArticleListView(), // Show articles based on selected tab
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCarousel() {
    final featuredArticles = _articles.take(5).toList();

    if (featuredArticles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 250,
          autoPlay: true,
          enlargeCenterPage: true,
        ),
        items: featuredArticles.map((article) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(articleUrl: article['url']!),
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article['image']!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      width: double.infinity,
                      height: 250,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArticleListView() {
    final filteredArticles = _articles.where((article) {
      return article['title']?.toLowerCase().contains(_searchQuery) ?? false;
    }).toList();

    // Filter articles based on the selected tab
    final selectedTabIndex = _tabController.index;
    String selectedSection = _tabs[selectedTabIndex];
    final sectionedArticles = filteredArticles.where((article) {
      return article['section'] == selectedSection; // filter articles based on the selected section
    }).toList();

    if (sectionedArticles.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: sectionedArticles.length,
      itemBuilder: (context, index) {
        final article = sectionedArticles[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: ListTile(
            leading: article['image']!.isNotEmpty
                ? Image.network(article['image']!, width: 80, height: 80, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(article['title'] ?? 'Untitled',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text(article['author'] ?? 'Unknown Author',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(articleUrl: article['url']!),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController
    super.dispose();
  }
}
