const express = require('express');
const router = express.Router();
const friendController = require('../controllers/friendController');
const authMiddleware = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', friendController.getFriends);
router.get('/requests', friendController.getFriendRequests);
router.post('/request', friendController.sendFriendRequest);
router.put('/requests/:id', friendController.respondToFriendRequest);

module.exports = router;
