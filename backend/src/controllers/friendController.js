const db = require('../config/db');

exports.getFriends = async (req, res) => {
    const userId = req.user.id;

    try {
        const query = `
            SELECT u.id, u.username, u.email 
            FROM users u
            JOIN friendships f ON (u.id = f.friend_id AND f.user_id = ? AND f.status = 'accepted') 
                               OR (u.id = f.user_id AND f.friend_id = ? AND f.status = 'accepted')
            ORDER BY u.username ASC
        `;
        const [rows] = await db.query(query, [userId, userId]);
        return res.json(rows);
    } catch (error) {
        console.error('Retrieve friends error:', error);
        return res.status(500).json({ error: 'Server error retrieving friends.' });
    }
};

exports.getFriendRequests = async (req, res) => {
    const userId = req.user.id;

    try {
        const incomingQuery = `
            SELECT f.id AS request_id, u.id AS user_id, u.username, u.email 
            FROM friendships f
            JOIN users u ON f.user_id = u.id
            WHERE f.friend_id = ? AND f.status = 'pending'
            ORDER BY f.created_at DESC
        `;
        const [incoming] = await db.query(incomingQuery, [userId]);

        const outgoingQuery = `
            SELECT f.id AS request_id, u.id AS user_id, u.username, u.email 
            FROM friendships f
            JOIN users u ON f.friend_id = u.id
            WHERE f.user_id = ? AND f.status = 'pending'
            ORDER BY f.created_at DESC
        `;
        const [outgoing] = await db.query(outgoingQuery, [userId]);

        return res.json({ incoming, outgoing });
    } catch (error) {
        console.error('Retrieve friend requests error:', error);
        return res.status(500).json({ error: 'Server error retrieving friend requests.' });
    }
};

exports.sendFriendRequest = async (req, res) => {
    const userId = req.user.id;
    const { username } = req.body;

    if (!username || username.trim().length === 0) {
        return res.status(400).json({ error: 'Username is required.' });
    }

    const targetUsername = username.trim();

    try {
        const [users] = await db.query('SELECT id, email, username FROM users WHERE username = ?', [targetUsername]);
        if (users.length === 0) {
            return res.status(404).json({ error: `User "${targetUsername}" not found.` });
        }

        const targetUser = users[0];

        if (targetUser.id === userId) {
            return res.status(400).json({ error: 'You cannot send a friend request to yourself.' });
        }

        const [existing] = await db.query(
            'SELECT id, user_id, friend_id, status FROM friendships WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
            [userId, targetUser.id, targetUser.id, userId]
        );

        if (existing.length > 0) {
            const rel = existing[0];
            if (rel.status === 'accepted') {
                return res.status(400).json({ error: `You are already friends with ${targetUsername}.` });
            } else if (rel.status === 'pending') {
                if (rel.user_id === userId) {
                    return res.status(400).json({ error: `Friend request already sent to ${targetUsername}.` });
                } else {
                    await db.query('UPDATE friendships SET status = "accepted" WHERE id = ?', [rel.id]);
                    return res.status(200).json({
                        message: `Mutual request! You are now friends with ${targetUsername}.`,
                        isAccepted: true
                    });
                }
            }
        }

        await db.query('INSERT INTO friendships (user_id, friend_id, status) VALUES (?, ?, "pending")', [userId, targetUser.id]);

        return res.status(201).json({
            message: `Friend request sent to ${targetUsername} successfully.`
        });
    } catch (error) {
        console.error('Send friend request error:', error);
        return res.status(500).json({ error: 'Server error sending friend request.' });
    }
};

exports.respondToFriendRequest = async (req, res) => {
    const userId = req.user.id;
    const requestId = req.params.id;
    const { action } = req.body;

    if (!action || (action !== 'accept' && action !== 'decline')) {
        return res.status(400).json({ error: 'Action is required and must be "accept" or "decline".' });
    }

    try {
        const [requests] = await db.query('SELECT * FROM friendships WHERE id = ?', [requestId]);
        if (requests.length === 0) {
            return res.status(404).json({ error: 'Friend request not found.' });
        }

        const request = requests[0];

        if (action === 'accept') {
            if (request.friend_id !== userId) {
                return res.status(403).json({ error: 'Access denied. Only the recipient can accept a friend request.' });
            }

            await db.query('UPDATE friendships SET status = "accepted" WHERE id = ?', [requestId]);
            return res.json({ message: 'Friend request accepted successfully.' });
        } else if (action === 'decline') {
            if (request.friend_id !== userId && request.user_id !== userId) {
                return res.status(403).json({ error: 'Access denied.' });
            }

            await db.query('DELETE FROM friendships WHERE id = ?', [requestId]);
            return res.json({ message: 'Friend request declined/cancelled successfully.' });
        }
    } catch (error) {
        console.error('Respond to friend request error:', error);
        return res.status(500).json({ error: 'Server error responding to friend request.' });
    }
};
