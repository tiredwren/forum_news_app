import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

class _ArticlesScreenState extends State<ArticlesScreen> {
  final CollectionReference articles = FirebaseFirestore.instance.collection('articles');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('The Forum'),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(width: 1),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            // Carousel for featured articles
            StreamBuilder<QuerySnapshot>(
              stream: articles.where('isFeatured', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(); // No featured articles
                }

                return CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                    enlargeCenterPage: true,
                  ),
                  items: snapshot.data!.docs.map((doc) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: doc),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(doc['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            doc['title'] ?? 'Untitled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            // TabBar for article types
            TabBar(
              tabs: [
                Tab(text: 'news'),
                Tab(text: 'public health'),
                Tab(text: 'sports'), // Add more tabs as needed
              ],
            ),
            // TabBarView for different types of articles
            Expanded(
              child: TabBarView(
                children: [
                  // News Articles Tab
                  _buildArticleList(articles.where('category', isEqualTo: 'news')),
                  // Public Health Articles Tab
                  _buildArticleList(articles.where('category', isEqualTo: 'public_health')),
                  // Sports Articles Tab
                  _buildArticleList(articles.where('category', isEqualTo: 'sports')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build the list of articles for a given category
  Widget _buildArticleList(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No articles found.'));
        }

        // Filter articles based on the search query
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final title = doc['title']?.toLowerCase() ?? '';
          return title.contains(_searchQuery);
        }).toList();

        return ListView(
          padding: EdgeInsets.all(10),
          children: filteredDocs.map((doc) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
              child: ListTile(
                contentPadding: EdgeInsets.all(10),
                leading: doc['imageUrl'] != null
                    ? Image.network(doc['imageUrl'], width: 80, height: 80, fit: BoxFit.cover)
                    : Icon(Icons.image, size: 80, color: Colors.grey),
                title: Text(
                  doc['title'] ?? 'Untitled',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(doc['author'] ?? 'Unknown Author', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(article: doc),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article['title']),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/banner.png', width: double.infinity, fit: BoxFit.cover),
            SizedBox(height: 10),
            if (article['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 9 / 4,
                  child: Image.network(article['imageUrl'], width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            SizedBox(height: 10),
            Text(
              article['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'By ${article['author']}',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            _buildFormattedText(article['content']),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String content) {
    List<TextSpan> spans = [];
    List<String> paragraphs = content.split('\n\n');

    for (String paragraph in paragraphs) {
      if (paragraph.startsWith('# ')) {
        spans.add(
          TextSpan(
            text: '${paragraph.substring(2)}\n\n',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        );
      } else if (paragraph.startsWith('## ')) {
        spans.add(
          TextSpan(
            text: '${paragraph.substring(3)}\n\n',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$paragraph\n\n',
            style: TextStyle(fontSize: 16),
          ),
        );
      }
    }

    return RichText(text: TextSpan(style: TextStyle(color: Colors.black), children: spans));
  }
}
