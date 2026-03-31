// ========================================
// IMPORTS - mga kailangang packages
// ========================================
import 'package:flutter/material.dart';                    // Flutter UI framework
import 'package:social_media/models/user_model.dart';      // User data model
import 'package:social_media/services/auth_service.dart';   // Authentication service
import 'package:cloud_firestore/cloud_firestore.dart';      // Firebase database
import 'package:url_launcher/url_launcher.dart';           // Para magbukas ng links sa browser

// ========================================
// HOME SCREEN WIDGET - main screen ng app
// ========================================
class HomeScreen extends StatefulWidget {
  final UserModel user;               // User object (uid, email, username)
  final void Function(bool) onThemeChanged;  // Function para magpalit ng theme (dark/light)
  final bool isDarkMode;              // Current theme state

  const HomeScreen({
    super.key,
    required this.user,               // Required user data
    required this.onThemeChanged,      // Required theme change function
    required this.isDarkMode          // Required theme state
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // Create state object
}

// ========================================
// HOME SCREEN STATE - nandito yung lahat ng logic
// ========================================
class _HomeScreenState extends State<HomeScreen> {
  // STATE VARIABLES - mga values na nagbabago habang nagrurun ang app
  
  int _selectedIndex = 0;           // Current selected tab (0=Home, 1=Groups, 2=Profile, 3=Notifications)
  bool _notificationsEnabled = true;    // Kung naka-on ba ang notifications
  
  // List ng notification messages (pwede palitan)
  List<String> _notifications = [
    'Welcome to MangaVerse!',
    'New group available: "Berserk Fans"',
    'System update completed',
  ];

  // ========================================
  // COLOR CONSTANTS - mga kulay na ginagamit sa app
  // ========================================
  
  // Traditional manga theme colors
  final Color primaryColor = const Color(0xFF8B4513);      // Brown/orange na primary color
  final Color accentColor = const Color(0xFFD4A574);        // Light brown accent
  final Color goldAccent = const Color(0xFFFFD700);         // Gold highlight color

  // Modern alternative colors (hindi pa ginagamit)
  final Color modernPrimaryColor = const Color(0xFF6366F1); // Indigo
  final Color modernAccentColor = const Color(0xFF818CF8);  // Light Indigo

  Future<int> _getGroupMemberCount(String groupName) async {
    try {
      // Naghahanap tayo sa lahat ng users_stats kung sino ang may following [groupName]
      QuerySnapshot query = await FirebaseFirestore.instance
          .collectionGroup('following') // collectionGroup para ma-search lahat ng subcollections
          .where('groupName', isEqualTo: groupName)
          .get();
          
      return query.docs.length;
    } catch (e) {
      print("Error counting members: $e");
      return 0;
    }
  }

  void _toggleJoinGroup(String groupName, bool isJoined) async {
    try {
      DocumentReference ref = FirebaseFirestore.instance
          .collection('users_stats')
          .doc(widget.user.username)
          .collection('following')
          .doc(groupName);

      if (isJoined) {
        // Leave group
        await ref.delete();
        _addNotification('${widget.user.username} left "$groupName" group!');
      } else {
        // Join group
        await ref.set({
          'type': 'group', 
          'groupName': groupName, // ✅ ADD THIS
          'joinedAt': FieldValue.serverTimestamp()
        });
        _addNotification('${widget.user.username} joined "$groupName" group!');
      }
    } catch (e) {
      print("Error toggling group membership: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kunin ang current theme (dark/light)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Kunin ang screen size para sa responsive design
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;           // Mobile: < 600px
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200; // Tablet: 600-1199px
    final isDesktop = screenSize.width >= 1200;       // Desktop: >= 1200px

    return Scaffold(
      // Body: mobile layout kung mobile, desktop layout kung desktop/tablet
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      
      // Bottom navigation bar lang para sa mobile devices
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar(isDark) : null,
    );
  }

  // ========================================
// MOBILE LAYOUT - layout para sa mobile devices
// ========================================
Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // ========================================
        // TOP BAR - header ng mobile app
        // ========================================
        Container(
          height: 70, // Fixed height para sa top bar
          color: isDark ? const Color(0xFF121212) : primaryColor, // Dark gray sa dark mode, brown sa light
          padding: const EdgeInsets.symmetric(horizontal: 20), // 20px left/right padding
          child: Row(
            children: [
              // APP TITLE
              const Text(
                'MangaVerse',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const Spacer(), // Itulak yung button sa right side
              
              // CREATE POST BUTTON - lumalabas lang sa Home page
              if (_selectedIndex == 0) // Kung 0 ang index (Home page)
                ElevatedButton.icon(
                  onPressed: _showCreatePostDialog, // Magbubukas ng post creation dialog
                  icon: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
                  label: Text(
                    'Post',
                    style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? goldAccent : const Color(0xFF4F46E5), // Gold sa dark, indigo sa light
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
        ),
        
        // ========================================
        // PAGE CONTENT AREA - nandito yung content ng selected page
        // ========================================
        Expanded(
          child: _buildPageContent(), // Tawag sa function na bubuild ng content
        ),
      ],
    );
  }

  // ========================================
// DESKTOP LAYOUT - layout para sa desktop/tablet
// ========================================
Widget _buildDesktopLayout(bool isDark) {
    return Stack(
      children: [
        Row(
          children: [
            // ========================================
            // SIDEBAR NAVIGATION - left side navigation bar
            // ========================================
            Container(
              width: 80, // Fixed width ng sidebar
              color: isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF1F5F9), // Dark gray sa dark, light gray sa light
              child: Column(
                children: [
                  const SizedBox(height: 20), // Top spacing
                  
                  // HOME NAVIGATION ITEM
                  _buildNavItem(
                    icon: Icons.home,                    // Home icon
                    isSelected: _selectedIndex == 0,       // Selected kung index 0
                    onTap: () => setState(() => _selectedIndex = 0), // Set to 0 para pumunta sa Home
                  ),
                  // GROUPS NAVIGATION ITEM
                  // Ito yung pangalawang navigation item (index 1)
                  // Icons.group = icon ng mga tao (para sa Groups page)
                  _buildNavItem(
                    icon: Icons.group,                    // Group icon
                    isSelected: _selectedIndex == 1,       // Selected kung index 1 ang current
                    onTap: () => setState(() => _selectedIndex = 1), // Set to 1 para pumunta sa Groups
                  ),
                  
                  // PROFILE NAVIGATION ITEM  
                  // Ito yung pangatlong navigation item (index 2)
                  // Icons.person = icon ng tao (para sa Profile page)
                  _buildNavItem(
                    icon: Icons.person,                   // Profile icon
                    isSelected: _selectedIndex == 2,       // Selected kung index 2 ang current
                    onTap: () => setState(() => _selectedIndex = 2), // Set to 2 para pumunta sa Profile
                  ),
                  
                  // NOTIFICATIONS NAVIGATION ITEM
                  // Ito yung pang-apat na navigation item (index 3)
                  // Icons.notifications = icon ng bell (para sa Notifications page)
                  _buildNavItem(
                    icon: Icons.notifications,              // Notifications icon
                    isSelected: _selectedIndex == 3,       // Selected kung index 3 ang current
                    onTap: () => setState(() => _selectedIndex = 3), // Set to 3 para pumunta sa Notifications
                  ),
                ],
              ),
            ),
            
            // ========================================
            // MAIN CONTENT AREA - right side content
            // ========================================
            Expanded(
              child: Column(
                children: [
                  // TOP BAR (same as mobile but without post button)
                  Container(
                    height: 70,
                    color: isDark ? const Color(0xFF121212) : primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        const Text(
                          'MangaVerse',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // PAGE CONTENT
                  Expanded(
                    child: _buildPageContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // ========================================
        // FLOATING CREATE POST BUTTON - lumalabas lang sa Home page
        // ========================================
        if (_selectedIndex == 0) // Kung nasa Home page
          Positioned(
            right: 30, // 30px from right
            bottom: 30, // 30px from bottom
            child: ElevatedButton.icon(
              onPressed: _showCreatePostDialog, // Magbubukas ng post creation dialog
              icon: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
              label: Text(
                'Create Post',
                style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? goldAccent : const Color(0xFF4F46E5), // Gold sa dark, indigo sa light
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 5, // Shadow effect
              ),
            ),
          ),
      ],
    );
  }

  // ========================================
// BOTTOM NAVIGATION BAR - navigation bar para sa mobile (sa baba)
// ========================================
Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF1F5F9), // Background color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Semi-transparent shadow
            blurRadius: 10, // Blur effect
            offset: const Offset(0, -2), // Shadow pointing upward
          ),
        ],
      ),
      child: SafeArea( // Ensure hindi ma-overlap sa system UI (notch, etc.)
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // 20px left/right, 8px top/bottom
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Evenly spaced items
            children: [
              // HOME NAVIGATION ITEM
              _buildBottomNavItem(
                icon: Icons.home,                    // Home icon
                isSelected: _selectedIndex == 0,       // Selected kung index 0
                onTap: () => setState(() => _selectedIndex = 0), // Set to 0 para pumunta sa Home
                label: 'Home',                      // Label text
              ),
              
              // GROUPS NAVIGATION ITEM
              _buildBottomNavItem(
                icon: Icons.group,                    // Group icon
                isSelected: _selectedIndex == 1,       // Selected kung index 1
                onTap: () => setState(() => _selectedIndex = 1), // Set to 1 para pumunta sa Groups
                label: 'Groups',                     // Label text
              ),
              
              // PROFILE NAVIGATION ITEM
              _buildBottomNavItem(
                icon: Icons.person,                   // Profile icon
                isSelected: _selectedIndex == 2,       // Selected kung index 2
                onTap: () => setState(() => _selectedIndex = 2), // Set to 2 para pumunta sa Profile
                label: 'Profile',                    // Label text
              ),
              
              // NOTIFICATIONS NAVIGATION ITEM
              _buildBottomNavItem(
                icon: Icons.notifications,              // Notifications icon
                isSelected: _selectedIndex == 3,       // Selected kung index 3
                onTap: () => setState(() => _selectedIndex = 3), // Set to 3 para pumunta sa Notifications
                label: 'Alerts',                     // Label text
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected 
                ? (isSelected ? goldAccent : primaryColor)
                : (isSelected ? Colors.grey[400] : Colors.grey[600]),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? (isSelected ? goldAccent : primaryColor)
                  : (isSelected ? Colors.grey[400] : Colors.grey[600]),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeFeed();
      case 1: return _buildGroupsPage();
      case 2: return _buildProfilePage();
      case 3: return _buildNotificationsPage();
      default: return _buildHomeFeed();
    }
  }

  Widget _buildHomeFeed() {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Get screen size for responsive design
  final screenSize = MediaQuery.of(context).size;
  final isMobile = screenSize.width < 600;
  final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
  final isDesktop = screenSize.width >= 1200;
  
  // Responsive padding
  double horizontalPadding = isMobile ? 10 : isTablet ? 20 : 30;
  double verticalPadding = isMobile ? 10 : isTablet ? 15 : 20;
  
  // Responsive cross axis count for grid layout (desktop/tablet)
  int crossAxisCount = isMobile ? 1 : isTablet ? 2 : 3;
  
  // Child aspect ratio for cards
  double childAspectRatio = isMobile ? 0.8 : isTablet ? 0.75 : 0.7;

  // STEP A: Kunin muna ang listahan ng lahat ng groups na "Joined" ka
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users_stats')
        .doc(widget.user.username)
        .collection('following')
        .snapshots(),
    builder: (context, followingSnapshot) {
      if (!followingSnapshot.hasData) return const Center(child: CircularProgressIndicator());

      // Gagawa tayo ng listahan ng group names (e.g., ['Naruto Fans', 'One Piece Crew'])
      List<String> joinedGroups = followingSnapshot.data!.docs.map((doc) => doc.id).toList();

      // STEP B: Query BOTH regular posts AND group posts
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPosts = snapshot.data!.docs;

          final filteredPosts = allPosts.where((doc) {
  var post = doc.data() as Map<String, dynamic>;
  String? originGroup = post['originGroup'];
  
  // Kung hindi group post, ipakita.
  // Kung group post, ipakita lang kung ang group ay nasa joinedGroups list ng user.
  return originGroup == null || joinedGroups.contains(originGroup);
}).toList();

          if (filteredPosts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.post_add,
                      size: isMobile ? 60 : 80,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    Text(
                      'No posts yet. Be the first to post!',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Use ListView for mobile, GridView for tablet/desktop
          if (isMobile) {
            return ListView.builder(
              padding: EdgeInsets.all(horizontalPadding),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(filteredPosts[index], isDark, isMobile);
              },
            );
          } else {
            return Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isMobile ? 10 : 15,
                  mainAxisSpacing: isMobile ? 10 : 15,
                ),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(filteredPosts[index], isDark, isMobile);
                },
              ),
            );
          }
        },
      );
    },
  );
}

  Widget _buildPostCard(DocumentSnapshot doc, bool isDark, bool isMobile) {
    var post = doc.data() as Map<String, dynamic>;
    String postId = doc.id;

    // --- AUTOMATIC FIX LOGIC ---
    // Kung null ang likes, gagawa tayo ng empty list para hindi mag-error
    final List likes = (post['likes'] != null && post['likes'] is List)
        ? List.from(post['likes'])
        : [];

    // Kung null ang commentCount, matik na 0 ang itatrato natin sa kanya
    final int commentCount = post['commentCount'] ?? 0;

    final bool isLiked = likes.contains(widget.user.username);
    // ----------------------------

    // Responsive sizing
    double avatarRadius = isMobile ? 20 : 25;
    double titleFontSize = isMobile ? 14 : 16;
    double bodyFontSize = isMobile ? 14 : 15;
    double iconSize = isMobile ? 20 : 24;

    return Card(
      margin: EdgeInsets.only(
        bottom: isMobile ? 15 : 20,
        left: isMobile ? 0 : 5,
        right: isMobile ? 0 : 5,
      ),
      color: isDark ? const Color(0xFF242424) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group indicator for posts with originGroup
          if (post['originGroup'] != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16, 
                vertical: isMobile ? 6 : 8
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.group, size: isMobile ? 14 : 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Posted in ${post['originGroup']}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 4 : 8,
            ),
            leading: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: post['username'] ?? 'User')
                  .limit(1)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String? profileImageUrl;
                if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                  final userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>?;
                  profileImageUrl = userData?['profileImage'];
                }

                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: primaryColor,
                  backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? Text(
                          post['username'] != null ? post['username'][0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: isMobile ? 16 : 20),
                        )
                      : null,
                );
              },
            ),
            title: Text(
              post['username'] ?? 'User', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
              )
            ),
            subtitle: Text(
              'Just now',
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
            trailing: post['username'] == widget.user.username
                ? null // Wag ipakita kung sarili mong post
                : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_stats').doc(widget.user.username)
                  .collection('following').doc(post['username']).snapshots(),
              builder: (context, snapshot) {
                bool isFollowing = snapshot.hasData && snapshot.data!.exists;
                return TextButton(
                  onPressed: () => _toggleFollow(post['username']),
                  child: Text(
                    isFollowing ? 'Unfollow' : 'Follow',
                    style: TextStyle(
                        color: isFollowing ? Colors.grey : const Color(0xFFFFD700), // Gold kung Follow
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16, 
              vertical: isMobile ? 6 : 8
            ),
            child: Text(
              post['description'] ?? '',
              style: TextStyle(fontSize: bodyFontSize),
            ),
          ),
          if (post['media'] != null && post['media'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              child: _buildMediaWidget(post['media'], isDark),
            ),

          // --- INTERACTION BAR (Likes & Comments) ---
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8, 
              vertical: isMobile ? 4 : 6
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : (isDark ? Colors.white60 : Colors.black54),
                    size: iconSize,
                  ),
                  onPressed: () => _handleLike(postId, likes, post['username'] ?? 'User'),
                ),
                Text(
                  '${likes.length}', 
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: isMobile ? 14 : 16,
                  )
                ),
                SizedBox(width: isMobile ? 12 : 20),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline, 
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: iconSize,
                  ),
                  onPressed: () => _showCommentSheet(postId, post['username'] ?? 'User'),
                ),
                Text(
                  '$commentCount', 
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: isMobile ? 14 : 16,
                  )
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 3 : 5),
        ],
      ),
    );
  }

  Widget _buildMediaWidget(String mediaUrl, bool isDark) {
  // Mas malawak na check para sa Facebook (Reels, Videos, at Mobile links)
  bool isFacebook = mediaUrl.contains('facebook.com') || mediaUrl.contains('fb.watch');

  if (isFacebook) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse(mediaUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.black87 : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, size: 50, color: primaryColor),
            const SizedBox(height: 10),
            const Text('Facebook Content', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tap to view on Facebook', 
                 style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // Kung hindi FB, itatrato natin bilang regular na Image
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      mediaUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 150,
          color: isDark ? Colors.black45 : Colors.grey[100],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      },
    ),
  );
}

  Widget _buildGroupHeader(String groupName, List<String> joinedGroups) {
  bool isJoined = joinedGroups.contains(groupName);

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            // DITO LALABAS ANG MEMBER COUNT
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('following')
                  .where('groupName', isEqualTo: groupName) // Assuming 'groupName' is a field in document
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error", style: TextStyle(fontSize: 10));
                
                // Bilang ng docs = Bilang ng users na naka-join
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                
                return Text(
                  "$count ${count == 1 ? 'Member' : 'Members'}",
                  style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                );
              },
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () => _toggleJoinGroup(groupName, isJoined),
          style: ElevatedButton.styleFrom(backgroundColor: isJoined ? Colors.grey : primaryColor),
          child: Text(isJoined ? 'Joined' : 'Join', style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  Widget _buildGroupsPage() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;
    
    // Responsive cross axis count for grid layout
    int crossAxisCount = isMobile ? 1 : isTablet ? 2 : 3;
    
    // Responsive padding
    double horizontalPadding = isMobile ? 20 : 30;
    double verticalPadding = isMobile ? 20 : 30;
    
    // Available groups (can be expanded later)
    final List<String> availableGroups = [
      'Naruto Fans',
      'One Piece Crew', 
      'Attack on Titan',
      'Demon Slayer',
      'My Hero Academia',
      'Jujutsu Kaisen',
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Groups',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 15 : 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isMobile ? 1.2 : 1.0,
                crossAxisSpacing: isMobile ? 10 : 15,
                mainAxisSpacing: isMobile ? 10 : 15,
              ),
              itemCount: availableGroups.length,
              itemBuilder: (context, index) {
                return _buildGroupCard(
                  availableGroups[index], 
                  isDark, 
                  isMobile
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupName, bool isDark, bool isMobile) {
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF242424) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 15 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Icon
            Container(
              width: isMobile ? 50 : 60, 
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.group, 
                color: isDark ? accentColor : primaryColor, 
                size: isMobile ? 25 : 30
              ),
            ),
            SizedBox(height: isMobile ? 12 : 15),
            
            // Group Name
            Text(
              groupName,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            
            // Real-time Member Counter using StreamBuilder
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('following') // Hahanapin lahat ng 'following' subcollections
                  .where('groupName', isEqualTo: groupName) // Filter by Group Name
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Text(
                  "0 Members", 
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                  )
                );
                
                int count = snapshot.data!.docs.length;
                return Text(
                  "$count ${count == 1 ? 'Member' : 'Members'}",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                );
              },
            ),
            
            SizedBox(height: isMobile ? 8 : 10),
            
            // Dynamic Description based on actual members
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_stats')
                  .doc(groupName)
                  .collection('followers')
                  .limit(3) // Get first 3 members
                  .snapshots(),
              builder: (context, snapshot) {
                List<String> memberNames = [];
                
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    memberNames.add(doc.id);
                  }
                }
                
                String description = '';
                if (memberNames.isEmpty) {
                  description = 'Be the first to join this group!';
                } else if (memberNames.length == 1) {
                  description = '${memberNames[0]} is a member';
                } else if (memberNames.length == 2) {
                  description = '${memberNames[0]} and ${memberNames[1]} are members';
                } else {
                  description = '${memberNames[0]}, ${memberNames[1]} and ${memberNames[2]} are members';
                }
                
                return Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            
            const Spacer(),
            
            // Join/Leave Button with Post Add Icon
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_stats')
                  .doc(widget.user.username)
                  .collection('following')
                  .doc(groupName)
                  .snapshots(),
              builder: (context, snapshot) {
                bool isJoined = snapshot.hasData && snapshot.data!.exists;

                return Row(
                  children: [
                    if (isJoined) // Show post add icon only if joined
                      Expanded(
                        child: Container(
                          height: isMobile ? 35 : 40,
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreateGroupPostDialog(groupName),
                            icon: Icon(
                              Icons.post_add, 
                              color: isDark ? Colors.black : Colors.white,
                              size: isMobile ? 16 : 18,
                            ),
                            label: Text(
                              'Post',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: isMobile ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? goldAccent : primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isJoined) 
                      SizedBox(width: isMobile ? 8 : 8),
                    if (isJoined)
                      Expanded(
                        child: SizedBox(
                          height: isMobile ? 35 : 40,
                          child: ElevatedButton(
                            onPressed: () async {
                              DocumentReference ref = FirebaseFirestore.instance
                                  .collection('users_stats')
                                  .doc(widget.user.username)
                                  .collection('following')
                                  .doc(groupName);

                              await ref.delete();
                              _addNotification('${widget.user.username} left "$groupName" group!');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Leave',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!isJoined)
                      Expanded(
                        child: SizedBox(
                          height: isMobile ? 35 : 40,
                          child: ElevatedButton(
                            onPressed: () async {
                              DocumentReference ref = FirebaseFirestore.instance
                                  .collection('users_stats')
                                  .doc(widget.user.username)
                                  .collection('following')
                                  .doc(groupName);

                              await ref.set({
                                'type': 'group', 
                                'joinedAt': FieldValue.serverTimestamp()
                              });

                              _addNotification('${widget.user.username} joined "$groupName" group!');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? goldAccent : primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Join',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Eksaktong Yellow-Gold color mula sa screenshot
    final Color goldAccent = const Color(0xFFFFD700);

    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: Profile (Sumusunod sa dark mode)
          Text(
            'Profile',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87
            ),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- PROFILE PICTURE SECTION ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Gold Border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent, // Naka-base sa circle border lang
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(color: goldAccent, width: 2),
                          ),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String? profileImageUrl;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                profileImageUrl = userData?['profileImage'];
                              }

                              return CircleAvatar(
                                radius: 75,
                                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child: profileImageUrl == null || profileImageUrl.isEmpty
                                    ? Icon(
                                  Icons.person,
                                  size: 80,
                                  color: isDark ? Colors.white : Colors.grey,
                                )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ),
                      // Camera Upload Icon (Yellow Circle)
                      Positioned(
                        right: 15,
                        bottom: 15,
                        child: GestureDetector(
                          onTap: _showProfileImageDialog,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: goldAccent,
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Username & Email
                  Text(
                      widget.user.username,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                  ),
                  Text(
                      widget.user.email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                  const SizedBox(height: 35),

                  // --- STATS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // POSTS COUNT (Heto yung existing mo)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('posts').where('username', isEqualTo: widget.user.username).snapshots(),
                        builder: (context, snapshot) => _buildStatItem(snapshot.hasData ? snapshot.data!.docs.length.toString() : "0", 'Posts'),
                      ),

                      // --- UPDATED FOLLOWERS ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users_stats').doc(widget.user.username).collection('followers').snapshots(),
                        builder: (context, snapshot) => _buildStatItem(snapshot.hasData ? snapshot.data!.docs.length.toString() : "0", 'Followers'),
                      ),

                      // --- UPDATED FOLLOWING ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users_stats').doc(widget.user.username).collection('following').snapshots(),
                        builder: (context, snapshot) => _buildStatItem(snapshot.hasData ? snapshot.data!.docs.length.toString() : "0", 'Following'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // Divider (Konting separation)
                  if(isDark) Divider(color: Colors.white12),

                  // --- SETTINGS ITEMS ---
                  _buildSettingsItem(
                      title: 'Change Username',
                      icon: Icons.edit,
                      onTap: _showChangeUsernameDialog
                  ),
                  _buildSettingsItem(
                      title: 'Dark Mode',
                      icon: Icons.dark_mode,
                      hasToggle: true,
                      toggleValue: widget.isDarkMode,
                      onToggle: widget.onThemeChanged
                  ),
                  _buildSettingsItem(
                      title: 'Notifications',
                      icon: Icons.notifications,
                      hasToggle: true,
                      toggleValue: _notificationsEnabled,
                      onToggle: (v) => setState(() => _notificationsEnabled = v)
                  ),
                ],
              ),
            ),
          ),

          // --- LOGOUT BUTTON (Deep Red) ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => AuthService().logout(),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                // Eksaktong Deep-Red mula sa screenshot
                backgroundColor: const Color(0xFFAC5353),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNotification(String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('notifications')
          .add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'general',
      });
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  void _notifyProfileUpdate(String username, String updateType) async {
    try {
      // Get all followers to notify them
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users_stats')
          .doc(username)
          .collection('followers')
          .get();

      for (var followerDoc in followersSnapshot.docs) {
        final followerUsername = followerDoc.id;

        // Get follower's UID
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: followerUsername)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final followerUid = userSnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(followerUid)
              .collection('notifications')
              .add({
            'message': '$username updated their $updateType',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'profile_update',
            'actor': username,
          });
        }
      }
    } catch (e) {
      print("Error notifying profile update: $e");
    }
  }

  void _notifyFollow(String followerUsername, String followingUsername) async {
    try {
      // Get the user being followed
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: followingUsername)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final followingUid = userSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(followingUid)
            .collection('notifications')
            .add({
          'message': '$followerUsername started following you',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'follow',
          'actor': followerUsername,
        });
      }
    } catch (e) {
      print("Error notifying follow: $e");
    }
  }

  Future<void> _sendNotificationToOwner({
    required String postOwnerUsername,
    required String message,
    required String type,
  }) async {
    // Huwag mag-notif kung ikaw din ang may-ari ng post
    if (postOwnerUsername == widget.user.username) return;

    // 1. Hanapin ang UID ng may-ari ng post
    final ownerDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: postOwnerUsername)
        .limit(1)
        .get();

    if (ownerDoc.docs.isNotEmpty) {
      String ownerUid = ownerDoc.docs.first.id;

      // 2. I-add ang notification sa may-ari
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('notifications')
          .add({
        'message': message,
        'sender': widget.user.username, // Pangalan mo ang makikita nila
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  void _notifyLike(String likerUsername, String postOwnerUsername, String postId) async {
    await _sendNotificationToOwner(
      postOwnerUsername: postOwnerUsername,
      message: '$likerUsername liked your post',
      type: 'like',
    );
  }

  void _notifyComment(String commenterUsername, String postOwnerUsername, String postId) async {
    await _sendNotificationToOwner(
      postOwnerUsername: postOwnerUsername,
      message: '$commenterUsername commented on your post',
      type: 'comment',
    );
  }

  void _notifyGroupJoin(String username, String groupName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('notifications')
          .add({
        'message': 'You joined "$groupName" group',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'group_join',
        'groupName': groupName,
      });
    } catch (e) {
      print("Error notifying group join: $e");
    }
  }

  void _toggleFollow(String targetUsername) async {
    final String myUsername = widget.user.username;

    // Reference para sa 'following' mo at 'followers' ng target
    // Ginagamit natin ang username as document ID para simple
    DocumentReference myFollowingRef = FirebaseFirestore.instance
        .collection('users_stats').doc(myUsername).collection('following').doc(targetUsername);

    DocumentReference targetFollowersRef = FirebaseFirestore.instance
        .collection('users_stats').doc(targetUsername).collection('followers').doc(myUsername);

    var doc = await myFollowingRef.get();

    if (doc.exists) {
      // UNFOLLOW: Burahin ang record sa parehong side
      await myFollowingRef.delete();
      await targetFollowersRef.delete();
    } else {
      // FOLLOW: Mag-add ng record sa parehong side
      await myFollowingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await targetFollowersRef.set({'timestamp': FieldValue.serverTimestamp()});

      // Notify the user being followed
      _notifyFollow(myUsername, targetUsername);
    }
  }

  void _showProfileImageDialog() {
  final TextEditingController imageUrlController = TextEditingController();
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: const Text('Update Profile Picture'),
      content: TextField(
        controller: imageUrlController,
        decoration: const InputDecoration(hintText: 'Paste Image URL here...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (imageUrlController.text.isEmpty) return;
            try {
              // Direct update para mabilis
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .update({'profileImage': imageUrlController.text.trim()});

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Success'), backgroundColor: Colors.green),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed'), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  void _showChangeUsernameDialog() {
  final TextEditingController usernameController = TextEditingController(text: widget.user.username);
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: const Text('Change Username'),
      content: TextField(controller: usernameController),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final newName = usernameController.text.trim();
            if (newName.isEmpty || newName == widget.user.username) return;

            try {
              final oldName = widget.user.username;

              // 1. Update main user doc sa Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .update({'username': newName});

              // 2. I-update ang local object para mag-reflect agad sa UI nang walang logout
              setState(() {
                widget.user.username = newName;
              });

              // 3. Update posts (Batch Update para mabilis)
              final posts = await FirebaseFirestore.instance
                  .collection('posts')
                  .where('username', isEqualTo: oldName)
                  .get();
              
              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (var doc in posts.docs) {
                batch.update(doc.reference, {'username': newName});
              }
              await batch.commit();

              Navigator.pop(context);
              
              // Simple Success Feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Success'), backgroundColor: Colors.green),
              );
              
            } catch (e) {
              Navigator.pop(context);
              // Simple Failed Feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed'), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  Widget _buildStatItem(String count, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Eksaktong Yellow-Gold color mula sa screenshot
    final Color goldAccent = const Color(0xFFFFD700);

    return Column(
      children: [
        Text(
            count,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: goldAccent, // Bilang ay gold
                letterSpacing: -0.5
            )
        ),
        Text(
            label,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey[700] // Label ay greyed out
            )
        ),
      ],
    );
  }

  Widget _buildSettingsItem({required String title, required IconData icon, bool hasToggle = false, bool toggleValue = false, Function(bool)? onToggle, VoidCallback? onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Icon(icon, color: isDark ? goldAccent : primaryColor),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
        trailing: hasToggle
            ? Switch.adaptive(
          value: toggleValue,
          onChanged: onToggle,
          activeColor: isDark ? goldAccent : primaryColor, // Gold toggle sa Dark Mode
        )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildNotificationsPage() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final notifications = snapshot.data!.docs;
                if (notifications.isEmpty) return const Center(child: Text('No notifications'));

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var notificationData = notifications[index].data() as Map<String, dynamic>;
                    String message = notificationData['message'] ?? 'Notification';
                    String type = notificationData['type'] ?? 'general';
                    bool isRead = notificationData['read'] ?? false;
                    Timestamp? timestamp = notificationData['timestamp'];

                    // Get appropriate icon based on type
                    IconData notificationIcon;
                    Color iconColor = primaryColor;

                    switch (type) {
                      case 'follow':
                        notificationIcon = Icons.person_add;
                        break;
                      case 'like':
                        notificationIcon = Icons.favorite;
                        iconColor = Colors.red;
                        break;
                      case 'comment':
                        notificationIcon = Icons.chat_bubble;
                        break;
                      case 'profile_update':
                        notificationIcon = Icons.edit;
                        break;
                      case 'group_join':
                        notificationIcon = Icons.group_add;
                        break;
                      default:
                        notificationIcon = Icons.notifications;
                    }

                    return Card(
                      color: isDark ? const Color(0xFF242424) : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.1),
                          child: Icon(notificationIcon, color: iconColor, size: 20),
                        ),
                        title: Text(
                          message,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: timestamp != null
                            ? Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
                        )
                            : null,
                        trailing: !isRead
                            ? Container(
                          width:8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        )
                            : null,
                        onTap: () async {
                          // Mark as read
                          if (!isRead) {
                            await notifications[index].reference.update({'read': true});
                          }
                        },
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

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNavItem({required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        child: Icon(
          icon,
          size: 30,
          // Gold kapag selected at Dark Mode, kundi primaryColor o grey
          color: isSelected
              ? (isDark ? goldAccent : primaryColor)
              : (isDark ? Colors.white38 : Colors.blueGrey),
        ),
      ),
    );
  }

  void _showCommentSheet(String postId, String postOwnerUsername) {
    final TextEditingController _commentController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6, // Kalahati ng screen ang simula
        maxChildSize: 0.9,     // Pwedeng i-drag pataas
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // --- REAL-TIME COMMENTS LIST ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) return const Center(child: Text('No comments yet. Start the conversation!'));

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                        var commentData = comments[index].data() as Map<String, dynamic>;
                      String username = commentData['username'] ?? 'Anonymous';
                      String initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accentColor,
                          radius: 15,
                          child: Text(initial, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                        title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(commentData['text'] ?? '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                      );
                    },
                  );
                },
              ),
            ),

            // --- INPUT FIELD PARA SA COMMENT ---
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 15, right: 15, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty) {
                        String commentText = _commentController.text;
                        _commentController.clear(); // Clear agad para maganda sa UI

                        // 1. Save the comment in the sub-collection
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .add({
                          'username': widget.user.username,
                          'text': commentText,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        // 2. Send notification to post owner
                        _sendNotificationToOwner(
                          postOwnerUsername: postOwnerUsername, // Ipasa mo ang username ng gumawa ng post
                          message: '${widget.user.username} commented on your post.',
                          type: 'comment',
                        );

                        // 3. Update the main post's commentCount - gamitin lang kung may existing comments
                        final commentsSnapshot = await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('comments')
                            .get();

                        if (commentsSnapshot.docs.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('posts').doc(postId).set({
                            'commentCount': commentsSnapshot.docs.length
                          }, SetOptions(merge: true));
                        } else {
                          // Kung walang existing comments, set to 1
                          await FirebaseFirestore.instance.collection('posts').doc(postId).set({
                            'commentCount': 1
                          }, SetOptions(merge: true));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _resetAllComments() async {
    try {
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();

      // Reset each post's commentCount to 0
      for (var postDoc in postsSnapshot.docs) {
        await FirebaseFirestore.instance.collection('posts').doc(postDoc.id).update({
          'commentCount': 0
        });

        // Delete all comments for this post
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .get();

        for (var commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.delete();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All comments reset successfully!')),
      );
    } catch (e) {
      print("Error resetting comments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting comments: $e')),
      );
    }
  }

  void _handleLike(String postId, List currentLikes, String postOwnerUsername) async {
    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      if (currentLikes.contains(widget.user.username)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([widget.user.username])
        });
      } else {
        // Ibig sabihin bago palang nag-heart
        _sendNotificationToOwner(
          postOwnerUsername: postOwnerUsername,
          message: '${widget.user.username} liked your post.',
          type: 'like',
        );

        // Gagamit tayo ng update, pero kung wala pang field,
        // i-se-set muna natin siya para sigurado.
        await postRef.set({
          'likes': FieldValue.arrayUnion([widget.user.username])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error updating like: $e");
    }
  }

  void _showCreatePostDialog() {
    final TextEditingController _descriptionController = TextEditingController();
    final TextEditingController _mediaLinkController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Create New Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _mediaLinkController,
                decoration: const InputDecoration(labelText: 'Image/Video Link', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_descriptionController.text.isNotEmpty) {
                try {
                  // SAVE TO FIREBASE
                  await FirebaseFirestore.instance.collection('posts').add({
                    'username': widget.user.username,
                    'description': _descriptionController.text,
                    'media': _mediaLinkController.text,
                    'timestamp': FieldValue.serverTimestamp(), // Para tama ang pagkakasunod-sunod
                    'likes': [], // MAHALAGA: Dito magsisimula ang likes list
                    'commentCount': 0, // MAHALAGA: Dito magsisimula ang bilang ng comments
                  });

                  Navigator.pop(context);
                  _addNotification('Post shared to MangaVerse!');

                  // Debug: Print success
                  print('Post saved successfully!');
                } catch (e) {
                  // Debug: Print error
                  print('Error saving post: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving post: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add a description.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupPostDialog(String groupName) {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mediaLinkController = TextEditingController();
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Text('Post to $groupName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _mediaLinkController,
              decoration: const InputDecoration(
                labelText: 'Link (Image, Video, or Reel)', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description', 
                border: OutlineInputBorder()
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_descriptionController.text.isNotEmpty) {
              await FirebaseFirestore.instance.collection('posts').add({
                'username': widget.user.username,
                'description': _descriptionController.text,
                'media': _mediaLinkController.text.trim(), // Trim para iwas error sa spaces
                'timestamp': FieldValue.serverTimestamp(),
                'originGroup': groupName,
                'likes': [],
                'commentCount': 0,
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          child: const Text('Post', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
}
