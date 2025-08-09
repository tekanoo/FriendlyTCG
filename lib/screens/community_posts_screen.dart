import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Écran Communauté : publication de posts, likes, commentaires.
/// Structure Firestore proposée:
///  collection `posts` documents:
///    - text: String
///    - authorUid: String
///    - authorName: String?
///    - authorPhoto: String?
///    - createdAt: Timestamp
///    - likeCount: int (miroir, maintenu via transaction)
///
///  sous-collection `posts/{postId}/likes` : documents { uid: true }
///  sous-collection `posts/{postId}/comments` : documents {
///     text, authorUid, authorName, authorPhoto, createdAt
///  }
class CommunityPostsScreen extends StatefulWidget {
  const CommunityPostsScreen({super.key});
  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _postController = TextEditingController();
  bool _publishing = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final user = _auth.currentUser;
    final text = _postController.text.trim();
    if (user == null || text.isEmpty) return;
    setState(()=> _publishing = true);
    try {
      await _firestore.collection('posts').add({
        'text': text,
        'authorUid': user.uid,
        'authorName': user.displayName,
        'authorPhoto': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      });
      _postController.clear();
  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post publié')));
    } finally {
      if (mounted) setState(()=> _publishing = false);
    }
  }

  Future<void> _toggleLike(DocumentSnapshot postDoc) async {
    final user = _auth.currentUser; if (user == null) return;
    final likeRef = postDoc.reference.collection('likes').doc(user.uid);
    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postDoc.reference);
      int likeCount = (postSnap.data() as Map<String,dynamic>)['likeCount'] ?? 0;
      if (likeSnap.exists) {
        tx.delete(likeRef);
        likeCount = likeCount > 0 ? likeCount - 1 : 0;
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        likeCount += 1;
      }
      tx.update(postDoc.reference, {'likeCount': likeCount});
    });
  }

  void _openPost(DocumentSnapshot postDoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PostDetailSheet(postDoc: postDoc, onToggleLike: ()=> _toggleLike(postDoc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Communauté')),
      body: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16,16,16,8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundImage: user.photoURL!=null? NetworkImage(user.photoURL!):null, child: user.photoURL==null? const Icon(Icons.person):null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _postController,
                          maxLines: null,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Exprimez-vous...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _publishing ? null : _publish,
                            icon: _publishing ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send),
                            label: Text(_publishing ? 'Publication...' : 'Publier'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('posts').orderBy('createdAt', descending: true).limit(200).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Aucun post pour le moment.'));
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx,i){
                    final d = docs[i];
                    final data = d.data() as Map<String,dynamic>;
                    final authorName = data['authorName'] ?? 'Utilisateur';
                    final authorPhoto = data['authorPhoto'] as String?;
                    final likeCount = data['likeCount'] ?? 0;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    return InkWell(
                      onTap: () => _openPost(d),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(radius: 18, backgroundImage: authorPhoto!=null? NetworkImage(authorPhoto):null, child: authorPhoto==null? const Icon(Icons.person):null),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  if (createdAt != null)
                                    Text(_formatDate(createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(data['text'] ?? '', maxLines: 5, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              _InlinePostActions(
                                postDoc: d,
                                likeCount: likeCount,
                                onLike: () => _toggleLike(d),
                                onOpen: () => _openPost(d),
                              ),
                            ],
                          ),
                        ),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
  }
}

class _InlinePostActions extends StatelessWidget {
  final DocumentSnapshot postDoc;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onOpen;
  const _InlinePostActions({required this.postDoc, required this.likeCount, required this.onLike, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        // Like status
        if (user != null)
          StreamBuilder<DocumentSnapshot>(
            stream: postDoc.reference.collection('likes').doc(user.uid).snapshots(),
            builder: (context, snap) {
              final liked = snap.data?.exists == true;
              return IconButton(
                onPressed: onLike,
                icon: Icon(liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, color: liked ? Colors.blue : null),
              );
            },
          ),
        Text('$likeCount'),
        const SizedBox(width: 16),
        TextButton.icon(onPressed: onOpen, icon: const Icon(Icons.comment, size: 18), label: const Text('Ouvrir')),
      ],
    );
  }
}

class PostDetailSheet extends StatelessWidget {
  final DocumentSnapshot postDoc;
  final VoidCallback onToggleLike;
  const PostDetailSheet({super.key, required this.postDoc, required this.onToggleLike});

  @override
  Widget build(BuildContext context) {
    final data = postDoc.data() as Map<String,dynamic>;
    final user = FirebaseAuth.instance.currentUser;
    final authorPhoto = data['authorPhoto'] as String?;
    final authorName = data['authorName'] ?? 'Utilisateur';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final likeCount = data['likeCount'] ?? 0;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            children: [
              Container(width: 48,height:4,margin: const EdgeInsets.symmetric(vertical:12),decoration: BoxDecoration(color: Colors.grey[400],borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: CircleAvatar(radius: 22, backgroundImage: authorPhoto!=null? NetworkImage(authorPhoto):null, child: authorPhoto==null? const Icon(Icons.person):null),
                title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: createdAt!=null? Text(_formatDetailDate(createdAt), style: TextStyle(color: Colors.grey[600])): null,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal:16, vertical: 8),
                  children: [
                    Text(data['text'] ?? '', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (user!=null)
                          StreamBuilder<DocumentSnapshot>(
                            stream: postDoc.reference.collection('likes').doc(user.uid).snapshots(),
                            builder: (context, snap) {
                              final liked = snap.data?.exists == true;
                              return IconButton(
                                onPressed: onToggleLike,
                                icon: Icon(liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, color: liked ? Colors.blue : null),
                              );
                            },
                          ),
                        StreamBuilder<QuerySnapshot>(
                          stream: postDoc.reference.collection('likes').snapshots(),
                          builder: (context, snap){
                            final count = snap.data?.docs.length ?? likeCount;
                            return Text('$count likes');
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _CommentsList(postDoc: postDoc),
                  ],
                ),
              ),
              if (user!=null) _CommentComposer(postDoc: postDoc),
            ],
          ),
        );
      },
    );
  }

  String _formatDetailDate(DateTime dt) => '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
}

class _CommentsList extends StatelessWidget {
  final DocumentSnapshot postDoc;
  const _CommentsList({required this.postDoc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: postDoc.reference.collection('comments').orderBy('createdAt', descending: true).limit(200).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text('Aucun commentaire.');
        return Column(
          children: [
            for (final d in docs)
              _SingleCommentTile(data: d.data() as Map<String,dynamic>),
          ],
        );
      },
    );
  }
}

class _SingleCommentTile extends StatelessWidget {
  final Map<String,dynamic> data;
  const _SingleCommentTile({required this.data});
  @override
  Widget build(BuildContext context) {
    final photo = data['authorPhoto'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundImage: photo!=null? NetworkImage(photo):null, child: photo==null? const Icon(Icons.person,size:16):null),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['authorName'] ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data['text'] ?? ''),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  final DocumentSnapshot postDoc;
  const _CommentComposer({required this.postDoc});
  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _auth = FirebaseAuth.instance;
  final _controller = TextEditingController();
  bool _sending = false;
  @override
  void dispose(){ _controller.dispose(); super.dispose(); }
  Future<void> _send() async {
    final user = _auth.currentUser; if (user == null) return; final text = _controller.text.trim(); if (text.isEmpty) return;
    setState(()=> _sending = true);
    try {
      await widget.postDoc.reference.collection('comments').add({
        'text': text,
        'authorUid': user.uid,
        'authorName': user.displayName,
        'authorPhoto': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } finally { if (mounted) setState(()=> _sending = false); }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12,4,12,8),
        child: Row(
          children: [
            Expanded(child: TextField(controller: _controller, minLines:1, maxLines:4, decoration: const InputDecoration(hintText: 'Commenter...'))),
            const SizedBox(width: 8),
            IconButton(onPressed: _sending? null : _send, icon: _sending? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send))
          ],
        ),
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final DocumentSnapshot postDoc;
  const CommentsSheet({super.key, required this.postDoc});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = _auth.currentUser; if (user == null) return;
    final text = _commentController.text.trim(); if (text.isEmpty) return;
    setState(()=> _sending = true);
    try {
      await widget.postDoc.reference.collection('comments').add({
        'text': text,
        'authorUid': user.uid,
        'authorName': user.displayName,
        'authorPhoto': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } finally {
      if (mounted) setState(()=> _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: widget.postDoc.reference.collection('comments').orderBy('createdAt', descending: true).limit(200).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return const Center(child: Text('Aucun commentaire.'));
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx,i){
                          final d = docs[i];
                          final data = d.data() as Map<String,dynamic>;
                          final photo = data['authorPhoto'] as String?;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 16, backgroundImage: photo!=null? NetworkImage(photo):null, child: photo==null? const Icon(Icons.person,size:16):null),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['authorName'] ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(data['text'] ?? ''),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...'
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sending? null : _send,
                        icon: _sending ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
