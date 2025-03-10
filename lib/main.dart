import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
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

class _ArticlesScreenState extends State<ArticlesScreen> {
  final CollectionReference articles = FirebaseFirestore.instance.collection('articles');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text('The Forum')),
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
                    prefixIcon: Icon(Icons.search),
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
            if (_searchQuery.isEmpty) _buildFeaturedArticles(),
            Expanded(
              child: _searchQuery.isEmpty
                  ? TabBarView(
                children: [
                  _buildArticleList(articles.where('category', isEqualTo: 'news')),
                  _buildArticleList(articles.where('category', isEqualTo: 'public_health')),
                  _buildArticleList(articles.where('category', isEqualTo: 'sports')),
                ],
              )
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedArticles() {
    return StreamBuilder<QuerySnapshot>(
      stream: articles.where('isFeatured', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(doc['imageUrl'] ?? '', fit: BoxFit.cover),
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(8),
                          child: Text(
                            doc['title'] ?? 'Untitled',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticleList(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No articles found.'));
        }
        return _buildArticleListView(snapshot.data!.docs);
      },
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: articles.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No articles found.'));
        }
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final titleMatches = doc['title']?.toLowerCase().contains(_searchQuery) ?? false;
          final authorMatches = doc['author']?.toLowerCase().contains(_searchQuery) ?? false;
          return titleMatches || authorMatches;
        }).toList();

        return _buildArticleListView(filteredDocs);
      },
    );
  }

  Widget _buildArticleListView(List<QueryDocumentSnapshot> docs) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: docs.map((doc) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: doc['imageUrl'] != null
                ? Image.network(doc['imageUrl'], width: 80, height: 80, fit: BoxFit.cover)
                : Icon(Icons.image, size: 80, color: Colors.grey),
            title: Text(doc['title'] ?? 'Untitled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Navigator.pop(context);
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
            Text(article['content'] ?? '', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
