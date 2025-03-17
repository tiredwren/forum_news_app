import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class ArticleDetailPage extends StatefulWidget {
  final String articleUrl;

  const ArticleDetailPage({super.key, required this.articleUrl});

  @override
  _ArticleDetailPageState createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  String _articleContent = '';
  String _articleTitle = '';
  String _byLine = '';
  String _imageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticleContent();
  }

  Future<void> _fetchArticleContent() async {
    final response = await http.get(Uri.parse(widget.articleUrl));

    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      final title = document.querySelector('.sno-story-headline');
      final byline = document.querySelector('.byline-inner-container');
      final content = document.querySelector('.sno-story-body-content');
      final imageElement = document.querySelector('#sno-main-content > div > div > div.sno-story-photo-area > div.photowrap > img');
      final authorElement = document.querySelector('.byline-inner-container .byline-name');
      final dateElement = document.querySelector('.byline-inner-container .time-wrapper');
      final contentElements = document.querySelectorAll('.sno-story-body-content p');




      String author = authorElement?.text.trim() ?? '';
      String date = dateElement?.text.trim() ?? '';

      setState(() {
        _articleTitle = title?.text.trim() ?? "Unable to load article title.";
        _byLine = (author.isNotEmpty && date.isNotEmpty) ? '$author • $date' : 'Unable to find article byline.';
        _articleContent = contentElements.map((p) => p.text.trim()).join("\n\n");
        _imageUrl = imageElement?.attributes['src'] ?? '';
        _isLoading = false;

        if (_imageUrl == "") {
          print(imageElement);
        }
      });
    } else {
      setState(() {
        _articleContent = 'Failed to load article.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _articleTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_byLine, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            if (_imageUrl.isNotEmpty)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageUrl, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            Text(_articleContent, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
