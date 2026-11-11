import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_book_page.dart';

class ManageBooksPage extends StatefulWidget {
  const ManageBooksPage({super.key});

  @override
  State<ManageBooksPage> createState() => _ManageBooksPageState();
}

class _ManageBooksPageState extends State<ManageBooksPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _categories = [
    'Fantasy',
    'Science Fiction',
    'Mystery & Crime',
    'Thriller & Suspense',
    'Romance',
    'Historical Fiction',
    'Horror',
    'Literary Fiction',
    'Young Adult & New Adult',
    'Biography & Memoir',
    'Self-Help & Personal Development',
    'History & Politics',
    'True Crime',
    'Science & Technology',
    'Business, Finance & Economics',
  ];

  void _showEditBookDialog(BuildContext context, String docId, Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title'] ?? '');
    final authorController = TextEditingController(text: currentData['author'] ?? '');
    final descriptionController = TextEditingController(text: currentData['description'] ?? '');
    final quantityController = TextEditingController(text: (currentData['quantity'] ?? 1).toString());
    String selectedCategory = currentData['category'] ?? 'Fantasy';
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Book', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003B7A))),
                const SizedBox(height: 4),
                TextField(controller: titleController, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text('Author *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003B7A))),
                const SizedBox(height: 4),
                TextField(controller: authorController, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003B7A))),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003B7A))),
                const SizedBox(height: 4),
                TextField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text('Quantity *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003B7A))),
                const SizedBox(height: 4),
                TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B7A), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || authorController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance.collection('books').doc(docId).update({
                  'title': titleController.text.trim(),
                  'author': authorController.text.trim(),
                  'category': selectedCategory,
                  'description': descriptionController.text.trim(),
                  'quantity': int.tryParse(quantityController.text.trim()) ?? 1,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId, String bookTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Book?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to delete "$bookTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('books').doc(docId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);
    final filterOptions = ['All', 'Available', ..._categories];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Manage Books', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search, color: primaryBlue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD6E4F0))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                itemBuilder: (context, index) {
                  final option = filterOptions[index];
                  final isSelected = _selectedFilter == option;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : primaryBlue, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = option);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, bookSnapshot) {
                  if (bookSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!bookSnapshot.hasData || bookSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No books found. Add one!'));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('borrowed_books').snapshots(),
                    builder: (context, borrowSnapshot) {
                      final borrowedDocs = borrowSnapshot.hasData ? borrowSnapshot.data!.docs : [];
                      Map<String, int> borrowedCounts = {};
                      for (var doc in borrowedDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['bookTitle'] ?? '').toString();
                        borrowedCounts[title] = (borrowedCounts[title] ?? 0) + 1;
                      }

                      final docs = bookSnapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        final category = data['category'] ?? '';
                        final quantity = data['quantity'] ?? 0;

                        bool matchesSearch = title.contains(_searchQuery);
                        bool matchesFilter = true;

                        if (_selectedFilter == 'Available') {
                          matchesFilter = quantity > 0;
                        } else if (_selectedFilter != 'All') {
                          matchesFilter = category == _selectedFilter;
                        }

                        return matchesSearch && matchesFilter;
                      }).toList();

                      if (docs.isEmpty) {
                        return const Center(child: Text('No books match this filter.'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'No Title';
                          int qty = data['quantity'] ?? 0;
                          int borrowedCount = borrowedCounts[title] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 45,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.menu_book, color: primaryBlue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data['author'] ?? 'Unknown Author',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFE6F0FA), borderRadius: BorderRadius.circular(4)),
                                            child: Text(data['category'] ?? 'General', style: const TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          Text('Available: $qty', style: TextStyle(fontSize: 11, color: qty > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                          Text('Borrowed: $borrowedCount', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditBookDialog(context, doc.id, data),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteDialog(context, doc.id, title),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookPage())),
      ),
    );
  }
}