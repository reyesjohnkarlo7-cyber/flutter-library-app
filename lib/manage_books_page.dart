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
  String _selectedFilter = 'All'; // Filter state
  final List<String> _categories = ['Fiction', 'Non-Fiction', 'Programming', 'Science', 'Self-Help'];

  // Show dialog to borrow a book
  void _showBorrowDialog(BuildContext context, String bookId, String bookTitle, String category, int quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This book is out of stock!'), backgroundColor: Colors.red));
      return;
    }

    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Borrow "$bookTitle"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter borrower student name:'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B7A), foregroundColor: Colors.white),
            onPressed: () async {
              String borrower = nameController.text.trim();
              if (borrower.isEmpty) return;

              // 1. Add record to 'borrowed_books' collection
              await FirebaseFirestore.instance.collection('borrowed_books').add({
                'bookTitle': bookTitle,
                'category': category,
                'memberName': borrower,
                'borrowedAt': FieldValue.serverTimestamp(),
              });

              // 2. Decrease book quantity by 1
              await FirebaseFirestore.instance.collection('books').doc(bookId).update({
                'quantity': quantity - 1,
              });

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book borrowed successfully!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Confirm Borrow'),
          ),
        ],
      ),
    );
  }

  void _showEditBookDialog(BuildContext context, String docId, Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title'] ?? '');
    final authorController = TextEditingController(text: currentData['author'] ?? '');
    final descriptionController = TextEditingController(text: currentData['description'] ?? '');
    final quantityController = TextEditingController(text: (currentData['quantity'] ?? 1).toString());
    String selectedCategory = currentData['category'] ?? 'Fiction';
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
            // Search Bar
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

            // Filter Chips Horizontal Scroll
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

            // Firestore Stream Builder List with Filtering Logic
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No books found. Add one!'));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final category = data['category'] ?? '';
                    final quantity = data['quantity'] ?? 0;

                    // Match search query
                    bool matchesSearch = title.contains(_searchQuery);

                    // Match filter category or availability
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
                      int qty = data['quantity'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 65,
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.menu_book, color: primaryBlue),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
                                  const SizedBox(height: 2),
                                  Text(data['author'] ?? 'Unknown Author', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFE6F0FA), borderRadius: BorderRadius.circular(6)),
                                        child: Text(data['category'] ?? 'General', style: const TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Qty: $qty', style: TextStyle(fontSize: 12, color: qty > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Borrow Button
                            IconButton(
                              icon: const Icon(Icons.bookmark_add, color: primaryBlue),
                              tooltip: 'Borrow Book',
                              onPressed: () => _showBorrowDialog(context, doc.id, data['title'] ?? 'Book', data['category'] ?? 'Fiction', qty),
                            ),
                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditBookDialog(context, doc.id, data),
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(context, doc.id, data['title'] ?? 'Book'),
                            ),
                          ],
                        ),
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