import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowBookPage extends StatefulWidget {
  const BorrowBookPage({super.key});

  @override
  State<BorrowBookPage> createState() => _BorrowBookPageState();
}

class _BorrowBookPageState extends State<BorrowBookPage> {
  String _searchQuery = '';

  // Show dialog to select a verified member and borrow the book
  void _showMemberSelectionDialog(BuildContext context, String bookId, String bookTitle, String category, int quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This book is out of stock!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Borrow "$bookTitle"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No active members found. Please add members in the Members page first.'),
                );
              }

              final members = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final memberData = members[index].data() as Map<String, dynamic>;
                  final memberName = memberData['name'] ?? 'Member';
                  final memberEmail = memberData['email'] ?? '';

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF003B7A),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(memberEmail),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003B7A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // 1. Save record to 'borrowed_books'
                        await FirebaseFirestore.instance.collection('borrowed_books').add({
                          'bookTitle': bookTitle,
                          'category': category,
                          'memberName': memberName,
                          'borrowedAt': FieldValue.serverTimestamp(),
                        });

                        // 2. Reduce book quantity by 1
                        await FirebaseFirestore.instance.collection('books').doc(bookId).update({
                          'quantity': quantity - 1,
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully checked out to $memberName!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: const Text('Select'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Borrow a Book', style: TextStyle(color: Colors.white)),
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
                hintText: 'Search available books...',
                prefixIcon: const Icon(Icons.search, color: primaryBlue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD6E4F0))),
              ),
            ),
            const SizedBox(height: 16),

            // Book List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No books available in the library.'));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No matching books found.'));
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
                                      Text('Available: $qty', style: TextStyle(fontSize: 12, color: qty > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: qty > 0 ? primaryBlue : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: qty > 0 ? () => _showMemberSelectionDialog(context, doc.id, data['title'] ?? 'Book', data['category'] ?? 'Fiction', qty) : null,
                              child: const Text('Borrow'),
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
    );
  }
}