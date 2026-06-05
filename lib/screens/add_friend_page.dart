import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/colors.dart';
import '../widgets/navbar.dart';
import '../widgets/header.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  int _currentTab = 0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.fetchFriends();
      authProvider.fetchFriendRequests();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetUsername = _usernameController.text.trim();
    
    final success = await authProvider.sendFriendRequest(targetUsername);

    if (mounted) {
      if (success) {
        _usernameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request sent to @$targetUsername!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to send request.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _handleRequest(int requestId, String action, String username) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.respondToFriendRequest(requestId, action);

    if (mounted) {
      String msg = '';
      if (action == 'accept') {
        msg = success ? 'You are now friends with @$username!' : 'Failed to accept request.';
      } else {
        msg = success ? 'Request with @$username removed.' : 'Failed to decline request.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : Colors.redAccent));
    }
  }

  Color _getAvatarColor(int index) {
    final colors = [PlanneyColors.purple, PlanneyColors.blue, PlanneyColors.orange, PlanneyColors.green, PlanneyColors.yellow];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: PlanneyColors.bg,
      appBar: const PlanneyHeader(title: 'Friends'),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PlanneyColors.pink,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: PlanneyColors.pink.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Expand Your Circle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Invite friends using their Planney username.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: PlanneyColors.text),
                          decoration: InputDecoration(
                            hintText: '@username',
                            hintStyle: const TextStyle(color: PlanneyColors.textMuted, fontWeight: FontWeight.w600),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter username' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: authProvider.isLoading ? null : _submit,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: authProvider.isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: PlanneyColors.divider, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTab == 0 ? PlanneyColors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Friends', style: TextStyle(fontWeight: FontWeight.w900, color: _currentTab == 0 ? Colors.white : PlanneyColors.textMuted)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _currentTab == 0 ? Colors.black.withOpacity(0.2) : PlanneyColors.bg, borderRadius: BorderRadius.circular(10)),
                            child: Text('${authProvider.friends.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _currentTab == 0 ? Colors.white : PlanneyColors.textMuted)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTab == 1 ? PlanneyColors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Requests', style: TextStyle(fontWeight: FontWeight.w900, color: _currentTab == 1 ? Colors.white : PlanneyColors.textMuted)),
                          if (authProvider.incomingRequests.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                              child: Text('${authProvider.incomingRequests.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: RefreshIndicator(
              color: PlanneyColors.purple,
              onRefresh: () async {
                await authProvider.fetchFriends();
                await authProvider.fetchFriendRequests();
              },
              child: _currentTab == 0 ? _buildFriendsList(authProvider) : _buildRequestsList(authProvider),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PlanneyNavbar(currentIndex: 2),  
    );
  }

  Widget _buildFriendsList(AuthProvider authProvider) {
    if (authProvider.friends.isEmpty) {
      return _buildEmptyState(Icons.people_alt_rounded, 'No friends yet', 'Add friends using their username above to start planning trips together!');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: authProvider.friends.length,
      itemBuilder: (context, index) {
        final friend = authProvider.friends[index];
        final avatarColor = _getAvatarColor(index);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PlanneyColors.divider, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24, backgroundColor: avatarColor,
                child: Text(friend['username'][0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${friend['username']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                    const SizedBox(height: 2),
                    Text(friend['email'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PlanneyColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: PlanneyColors.bg, shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded, color: PlanneyColors.purple, size: 20),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(AuthProvider authProvider) {
    if (authProvider.incomingRequests.isEmpty && authProvider.outgoingRequests.isEmpty) {
      return _buildEmptyState(Icons.mark_email_read_rounded, 'No pending requests', 'You are all caught up!');
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        if (authProvider.incomingRequests.isNotEmpty) ...[
          const Text('Incoming Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
          const SizedBox(height: 16),
          ...authProvider.incomingRequests.map((req) => _buildRequestCard(req, isIncoming: true)).toList(),
        ],
        if (authProvider.outgoingRequests.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Sent Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
          const SizedBox(height: 16),
          ...authProvider.outgoingRequests.map((req) => _buildRequestCard(req, isIncoming: false)).toList(),
        ],
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, {required bool isIncoming}) {
    final username = request['username'] as String? ?? 'User';
    final email = request['email'] as String? ?? '';
    final requestId = request['request_id'] as int;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PlanneyColors.divider, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22, backgroundColor: PlanneyColors.bg,
            child: Text(initial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PlanneyColors.textMuted)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$username', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PlanneyColors.textMuted)),
              ],
            ),
          ),
          
          if (isIncoming) ...[
            InkWell(
              onTap: () => _handleRequest(requestId, 'decline', username),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), shape: BoxShape.circle), 
                child: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _handleRequest(requestId, 'accept', username),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: PlanneyColors.green, shape: BoxShape.circle), 
                child: const Icon(Icons.check_rounded, size: 20, color: Colors.black87),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => _handleRequest(requestId, 'decline', username), 
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(100)), 
                child: Row(
                  children: const [
                    Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                    SizedBox(width: 6),
                    Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.redAccent)),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: PlanneyColors.divider, width: 2)), child: Icon(icon, size: 48, color: PlanneyColors.textMuted)),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PlanneyColors.text)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PlanneyColors.textMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}