import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:newspaper_app_the_forum/firebase_options.dart';
import 'article_details.dart';
import 'firebase_api.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firebaseApi = FirebaseApi();
  firebaseApi.initNotifications();

  runApp(MyApp(firebaseApi: firebaseApi));
}

class MyApp extends StatelessWidget {
  final FirebaseApi firebaseApi;

  const MyApp({Key? key, required this.firebaseApi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Spartan News',
    navigatorKey: GlobalKey<NavigatorState>(), // Avoid multiple instances
    home: ArticlesScreen(), // Ensure this is a single entry point
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
  final List<String> _tabs = ['S & T', 'Advice', 'Sports', 'A & E']; // Define your sections

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
      final articlesElementsMain = document.querySelectorAll('.sno-story-card');
      final articlesElementsDual = document.querySelectorAll('.dual-format-card');
      final articleElementsSports = document.querySelectorAll('.carousel-widget-slide');
      // <li class="carousel-widget-slide visible-slide" style="width: 248.667px; margin-right: 10px; float: left; display: block;"><div style="height:150px;width:100%;overflow:hidden;position:relative;"><img src="https://thespartanforum.com/wp-content/uploads/2025/03/Basketball-Seniors-1200x800.jpg" id="imgcarousel-273406" style="height:100%;width:101%; object-fit:cover;" alt="A New Tradition in the Making" draggable="false"></div><div class="carouseltext carouseltextcarousel-27 " style="max-height:80px;min-height:80px; padding:10px; background: #eeeeee; "><div class="widgetheadline"><a style="font-size:18px; line-height:22px; " class="homeheadline" href="https://thespartanforum.com/3406/sports/a-new-tradition-in-the-making/">A New Tradition in the Making</a></div><p class="carouselbyline"><span class="sno_writer_carousel"> <a href="https://thespartanforum.com/staff_name/aleise-robertson/" class="creditline">Aleise Robertson</a></span></p></div></li>

      if (articlesElementsMain.isEmpty) {
        print("Something went wrong... please try again soon!");
      }

      List<Map<String, String>> articlesMain = articlesElementsMain.map((element) {
        final titleMain = element.querySelector('.sno-story-card-link a');
        final authorElement = element.querySelector('.creditline');
        final imageElement = element.querySelector('img');

        final title = titleMain?.text ?? 'No Title';
        final url = titleMain?.attributes['href'] ?? '';
        final author = authorElement?.text ?? 'Unknown Author';
        final imageUrl = imageElement?.attributes['src'] ?? '';

        // assign section based on the article URL
        String section = 'Features'; // default section
        if (url.contains('science-technology')) {
          section = 'S & T';
        } else if (url.contains('advice')) {
          section = 'Advice';
        } else if (url.contains('arts')) {
          section = 'A & E';
        }

        return {
          'title': title,
          'url': url,
          'author': author,
          'image': imageUrl,
          'section': section,
        };
      }).toList();

      List<Map<String, String>> articlesDual = articlesElementsDual.map((element) {
        final titleMain = element.querySelector('.sno-story-card-link a');
        final authorElement = element.querySelector('.creditline');
        final imageElement = element.querySelector('img');

        final title = titleMain?.text ?? 'No Title';
        final url = titleMain?.attributes['href'] ?? '';
        final author = authorElement?.text ?? 'Unknown Author';
        final imageUrl = imageElement?.attributes['src'] ?? '';

        // assign section based on the article URL
        String section = 'Features'; // default section
        if (url.contains('science-technology')) {
          section = 'S & T';
        } else if (url.contains('advice')) {
          section = 'Advice';
        } else if (url.contains('arts')) {
          section = 'A & E';
        }

        return {
          'title': title,
          'url': url,
          'author': author,
          'image': imageUrl,
          'section': section,
        };
      }).toList();

      List<Map<String, String>> sportsArticles = articleElementsSports.map((element) {
        final titleMain = element.querySelector('.homeheadline a');
        final authorElement = element.querySelector('.creditline');
        final imageElement = element.querySelector('img');

        final title = titleMain?.text ?? 'No Title';
        final url = titleMain?.attributes['href'] ?? '';
        final author = authorElement?.text ?? 'Unknown Author';
        final imageUrl = imageElement?.attributes['src'] ?? '';

        return {
          'title': title,
          'url': url,
          'author': author,
          'image': imageUrl,
          'section': "sports",
        };
      }).toList();

      setState(() {
        _articles = articlesMain + articlesDual + sportsArticles;
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
      appBar: AppBar(title: const Text('')),
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
            if (_searchQuery.isEmpty) _buildArticleCarousel(), // Hide carousel when searching
            TabBar(
              controller: _tabController,
              tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
              indicatorColor: Colors.blue,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildArticleListView(),
            ),
          ],
        ),
    );
  }

  Widget _buildArticleCarousel() {
    final featuredArticles = _articles.where((article) {
      return article['section']?.toLowerCase() == "features" ;
    }).toList();

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
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        article['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

    // Show all articles when searching, otherwise filter by section
    final selectedTabIndex = _tabController.index;
    String selectedSection = _tabs[selectedTabIndex];
    final sectionedArticles = _searchQuery.isEmpty
        ? filteredArticles.where((article) => article['section'] == selectedSection).toList()
        : filteredArticles; // Show all matching articles when searching

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
