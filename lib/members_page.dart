import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  // Show dialog to add a new member
  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Member', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Status'),
                  value: isActive,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setDialogState(() => isActive = val);
                  },
                ),
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
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance.collection('users').add({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'isActive': isActive,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog to edit existing member credentials
  void _showEditMemberDialog(BuildContext context, String docId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final emailController = TextEditingController(text: currentData['email'] ?? '');
    bool isActive = currentData['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Member Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Status'),
                  value: isActive,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setDialogState(() => isActive = val);
                  },
                ),
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
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance.collection('users').doc(docId).update({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // Show Member Details Modal with Local Sorted Transaction Log History
  void _showMemberDetailsModal(BuildContext context, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'Member';
    final String email = data['email'] ?? 'No Email';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final String createdDateStr = createdAt != null
        ? "${createdAt.toDate().month}/${createdAt.toDate().day}/${createdAt.toDate().year}"
        : 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF003B7A),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
                        Text(email, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Member since: $createdDateStr', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Transaction Log History (Borrow & Return)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003B7A))),
              const SizedBox(height: 12),

              // Stream transaction logs for this member without requiring composite indexes
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transaction_logs')
                    .where('memberName', isEqualTo: name)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('No past transaction history found for this member.')),
                    );
                  }

                  // Sort documents locally by timestamp descending
                  final docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    Timestamp? tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    Timestamp? tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    if (tA == null || tB == null) return 0;
                    return tB.compareTo(tA);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = docs[index].data() as Map<String, dynamic>;
                      final bookTitle = item['bookTitle'] ?? 'Book';
                      final type = item['type'] ?? 'Borrowed';
                      final Timestamp? timestamp = item['timestamp'] as Timestamp?;
                      final String dateStr = timestamp != null
                          ? "${timestamp.toDate().month}/${timestamp.toDate().day}/${timestamp.toDate().year} - ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                          : 'Recent';

                      bool isBorrow = type == 'Borrowed';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EEF5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBorrow ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isBorrow ? Icons.bookmark_add : Icons.keyboard_return,
                                color: isBorrow ? Colors.orange : Colors.green,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        isBorrow ? 'Borrowed' : 'Returned',
                                        style: TextStyle(
                                          color: isBorrow ? Colors.orange : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                                      Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> _deleteMember(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF003B7A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Library Members', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No members found. Tap "+" to add one!', style: TextStyle(color: Colors.black54)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'No Name';
              final String email = data['email'] ?? 'No Email';
              final bool isActive = data['isActive'] ?? true;
              final Timestamp? createdAt = data['createdAt'] as Timestamp?;
              final String createdDateStr = createdAt != null
                  ? "${createdAt.toDate().month}/${createdAt.toDate().day}/${createdAt.toDate().year}"
                  : 'N/A';

              return GestureDetector(
                onTap: () => _showMemberDetailsModal(context, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, color: primaryBlue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue)),
                            const SizedBox(height: 2),
                            Text(email, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Joined: $createdDateStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleStatus(doc.id, isActive),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _showEditMemberDialog(context, doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteMember(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddMemberDialog(context),
      ),
    );
  }
}