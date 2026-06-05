const express = require('express');
const router = express.Router();
const tripController = require('../controllers/tripController');
const authMiddleware = require('../middleware/auth');

router.use(authMiddleware);

router.post('/', tripController.createTrip);
router.get('/', tripController.getTrips);
router.get('/:id', tripController.getTripById);
router.put('/:id', tripController.updateTrip);
router.delete('/:id', tripController.deleteTrip);
router.put('/:id/itinerary/:itineraryId', tripController.updateItinerary);
router.delete('/:id/itinerary/:itineraryId', tripController.deleteItinerary);
router.post('/:id/itinerary', tripController.addItinerary);

module.exports = router;
