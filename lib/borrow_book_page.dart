import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowBookPage extends StatefulWidget {
  const BorrowBookPage({super.key});

  @override
  State<BorrowBookPage> createState() => _BorrowBookPageState();
}

class _BorrowBookPageState extends State<BorrowBookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMemberSelectionDialog(BuildContext context, String bookId, String bookTitle, String category, int quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This book is out of stock!'), backgroundColor: Colors.red),
      );
      return;
    }

    String memberSearchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Borrow "$bookTitle"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setDialogState(() {
                      memberSearchQuery = val.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search active member...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF003B7A)),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD6E4F0))),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('isActive', isEqualTo: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No active members found. Please activate members first.'),
                        );
                      }

                      final members = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(memberSearchQuery) || email.contains(memberSearchQuery);
                      }).toList();

                      if (members.isEmpty) {
                        return const Center(child: Text('No matching active members found.'));
                      }

                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final memberData = members[index].data() as Map<String, dynamic>;
                          final memberName = memberData['name'] ?? 'Member';
                          final memberEmail = memberData['email'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF003B7A),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memberName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF003B7A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        memberEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003B7A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    // 1. Add active borrow record
                                    await FirebaseFirestore.instance.collection('borrowed_books').add({
                                      'bookTitle': bookTitle,
                                      'category': category,
                                      'memberName': memberName,
                                      'borrowedAt': FieldValue.serverTimestamp(),
                                    });

                                    // 2. Add permanent log entry for history
                                    await FirebaseFirestore.instance.collection('transaction_logs').add({
                                      'bookTitle': bookTitle,
                                      'category': category,
                                      'memberName': memberName,
                                      'type': 'Borrowed',
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    // 3. Reduce book stock
                                    await FirebaseFirestore.instance.collection('books').doc(bookId).update({
                                      'quantity': quantity - 1,
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Successfully checked out to $memberName!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  },
                                  child: const Text('Select', style: TextStyle(fontSize: 12)),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
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
        title: const Text('Book Transactions', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Borrow Books', icon: Icon(Icons.bookmark_add, size: 20)),
            Tab(text: 'Borrowed Log & Return', icon: Icon(Icons.assignment_returned, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: BORROW BOOKS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                                        data['title'] ?? 'No Title',
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
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: qty > 0 ? primaryBlue : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          // TAB 2: BORROWED LOG & RETURN
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('borrowed_books').orderBy('borrowedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No active borrowed books right now.', style: TextStyle(color: Colors.black54)));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final borrowDoc = docs[index];
                    final data = borrowDoc.data() as Map<String, dynamic>;
                    final String bookTitle = data['bookTitle'] ?? 'Book';
                    final String memberName = data['memberName'] ?? 'Member';
                    final String category = data['category'] ?? 'General';
                    final Timestamp? borrowedAt = data['borrowedAt'] as Timestamp?;
                    
                    final String dateStr = borrowedAt != null
                        ? "${borrowedAt.toDate().month}/${borrowedAt.toDate().day}/${borrowedAt.toDate().year}"
                        : 'Just now';

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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bookmark_added, color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Borrower: $memberName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: $dateStr',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE6F0FA), borderRadius: BorderRadius.circular(4)),
                                  child: Text('Genre: $category', style: const TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.keyboard_return, size: 16),
                            label: const Text('Return', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              // 1. Remove from active borrowed_books collection
                              await FirebaseFirestore.instance.collection('borrowed_books').doc(borrowDoc.id).delete();

                              // 2. Add permanent return transaction log entry
                              await FirebaseFirestore.instance.collection('transaction_logs').add({
                                'bookTitle': bookTitle,
                                'category': category,
                                'memberName': memberName,
                                'type': 'Returned',
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              // 3. Restore book quantity
                              final bookQuery = await FirebaseFirestore.instance.collection('books').where('title', isEqualTo: bookTitle).get();
                              if (bookQuery.docs.isNotEmpty) {
                                final bookDoc = bookQuery.docs.first;
                                int currentQty = bookDoc['quantity'] ?? 0;
                                await bookDoc.reference.update({'quantity': currentQty + 1});
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('"$bookTitle" returned successfully!'), backgroundColor: Colors.green),
                                );
                              }
                            },
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
    );
  }
}