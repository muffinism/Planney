const db = require('../config/db');

const isEndDateBeforeStartDate = (start, end) => {
    const startDate = new Date(start);
    const endDate = new Date(end);
    return endDate < startDate;
};

exports.createTrip = async (req, res) => {
    const { trip_title, start_date, end_date, initiator_username, members } = req.body;

    if (!trip_title || !start_date || !end_date || !initiator_username) {
        return res.status(400).json({ error: 'All fields (trip_title, start_date, end_date, initiator_username) are required.' });
    }

    if (trip_title.trim().length < 3) {
        return res.status(400).json({ error: 'Trip title must be at least 3 characters long.' });
    }

    if (isEndDateBeforeStartDate(start_date, end_date)) {
        return res.status(400).json({ error: 'End date cannot be earlier than start date.' });
    }

    try {
        const [result] = await db.query(
            'INSERT INTO trips (trip_title, start_date, end_date, initiator_username) VALUES (?, ?, ?, ?)',
            [trip_title.trim(), start_date, end_date, initiator_username.trim()]
        );

        const tripId = result.insertId;

        const [creatorUsers] = await db.query('SELECT id FROM users WHERE username = ?', [initiator_username.trim()]);
        const creatorId = creatorUsers.length > 0 ? creatorUsers[0].id : req.user.id;
        
        await db.query('INSERT INTO trip_members (trip_id, user_id) VALUES (?, ?)', [tripId, creatorId]);

        if (Array.isArray(members) && members.length > 0) {
            for (const memberId of members) {
                const parsedId = parseInt(memberId);
                if (parsedId !== creatorId) {
                    await db.query('INSERT IGNORE INTO trip_members (trip_id, user_id) VALUES (?, ?)', [tripId, parsedId]);
                }
            }
        }

        return res.status(201).json({
            message: 'Trip created successfully',
            trip_id: tripId,
            trip: {
                id: tripId,
                trip_title: trip_title.trim(),
                start_date,
                end_date,
                initiator_username: initiator_username.trim()
            }
        });
    } catch (error) {
        console.error('Create trip error:', error);
        return res.status(500).json({ error: 'Server error during trip creation.' });
    }
};

exports.getTrips = async (req, res) => {
    const userId = req.user.id;

    try {
        const query = `
            SELECT t.* 
            FROM trips t
            JOIN trip_members tm ON t.id = tm.trip_id
            WHERE tm.user_id = ?
            ORDER BY t.start_date ASC
        `;
        const [rows] = await db.query(query, [userId]);
        return res.json(rows);
    } catch (error) {
        console.error('Retrieve trips error:', error);
        return res.status(500).json({ error: 'Server error retrieving trips.' });
    }
};

exports.getTripById = async (req, res) => {
    const tripId = req.params.id;
    const userId = req.user.id;

    try {
        const [membership] = await db.query(
            'SELECT 1 FROM trip_members WHERE trip_id = ? AND user_id = ?',
            [tripId, userId]
        );
        if (membership.length === 0) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this trip.' });
        }

        const [trips] = await db.query('SELECT * FROM trips WHERE id = ?', [tripId]);
        if (trips.length === 0) {
            return res.status(404).json({ error: 'Trip not found.' });
        }

        const trip = trips[0];

        const [itineraries] = await db.query(
            'SELECT * FROM itineraries WHERE trip_id = ? ORDER BY start_datetime ASC',
            [tripId]
        );
        trip.itineraries = itineraries;

        const [members] = await db.query(`
            SELECT u.id, u.username, u.email 
            FROM users u
            JOIN trip_members tm ON u.id = tm.user_id
            WHERE tm.trip_id = ?
            ORDER BY u.username ASC
        `, [tripId]);
        trip.members = members;

        return res.json(trip);
    } catch (error) {
        console.error('Retrieve trip detail error:', error);
        return res.status(500).json({ error: 'Server error retrieving trip details.' });
    }
};

exports.updateTrip = async (req, res) => {
    const tripId = req.params.id;
    const userId = req.user.id;
    const { trip_title, start_date, end_date, initiator_username, members } = req.body;

    if (!trip_title || !start_date || !end_date || !initiator_username) {
        return res.status(400).json({ error: 'All fields (trip_title, start_date, end_date, initiator_username) are required.' });
    }

    if (trip_title.trim().length < 3) {
        return res.status(400).json({ error: 'Trip title must be at least 3 characters long.' });
    }

    if (isEndDateBeforeStartDate(start_date, end_date)) {
        return res.status(400).json({ error: 'End date cannot be earlier than start date.' });
    }

    try {
        const [trips] = await db.query('SELECT initiator_username FROM trips WHERE id = ?', [tripId]);
        if (trips.length === 0) {
            return res.status(404).json({ error: 'Trip not found.' });
        }

        const trip = trips[0];
        if (trip.initiator_username !== req.user.username) {
            return res.status(403).json({ error: 'Access denied. Only the trip initiator can update the trip.' });
        }

        await db.query(
            'UPDATE trips SET trip_title = ?, start_date = ?, end_date = ?, initiator_username = ? WHERE id = ?',
            [trip_title.trim(), start_date, end_date, initiator_username.trim(), tripId]
        );

        if (Array.isArray(members)) {
            const [creatorUsers] = await db.query('SELECT id FROM users WHERE username = ?', [initiator_username.trim()]);
            const creatorId = creatorUsers.length > 0 ? creatorUsers[0].id : userId;

            await db.query('DELETE FROM trip_members WHERE trip_id = ?', [tripId]);
            await db.query('INSERT INTO trip_members (trip_id, user_id) VALUES (?, ?)', [tripId, creatorId]);

            for (const memberId of members) {
                const parsedId = parseInt(memberId);
                if (parsedId !== creatorId) {
                    await db.query('INSERT IGNORE INTO trip_members (trip_id, user_id) VALUES (?, ?)', [tripId, parsedId]);
                }
            }
        }

        return res.json({ message: 'Trip updated successfully' });
    } catch (error) {
        console.error('Update trip error:', error);
        return res.status(500).json({ error: 'Server error updating trip.' });
    }
};

exports.deleteTrip = async (req, res) => {
    const tripId = req.params.id;

    try {
        const [trips] = await db.query('SELECT initiator_username FROM trips WHERE id = ?', [tripId]);
        if (trips.length === 0) {
            return res.status(404).json({ error: 'Trip not found.' });
        }

        const trip = trips[0];
        if (trip.initiator_username !== req.user.username) {
            return res.status(403).json({ error: 'Access denied. Only the trip initiator can delete the trip.' });
        }

        await db.query('DELETE FROM trips WHERE id = ?', [tripId]);

        return res.json({ message: 'Trip deleted successfully' });
    } catch (error) {
        console.error('Delete trip error:', error);
        return res.status(500).json({ error: 'Server error deleting trip.' });
    }
};

exports.addItinerary = async (req, res) => {
    const tripId = req.params.id;
    const userId = req.user.id;
    const { agenda_title, start_datetime, end_datetime, agenda_details } = req.body;

    if (!agenda_title || !start_datetime || !end_datetime) {
        return res.status(400).json({ error: 'Agenda title, start datetime, and end datetime are required.' });
    }

    if (agenda_title.trim().length < 3) {
        return res.status(400).json({ error: 'Agenda title must be at least 3 characters long.' });
    }

    if (isEndDateBeforeStartDate(start_datetime, end_datetime)) {
        return res.status(400).json({ error: 'End date/time cannot be earlier than start date/time.' });
    }

    try {
        const [membership] = await db.query(
            'SELECT 1 FROM trip_members WHERE trip_id = ? AND user_id = ?',
            [tripId, userId]
        );
        if (membership.length === 0) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this trip.' });
        }

        const [result] = await db.query(
            'INSERT INTO itineraries (trip_id, agenda_title, start_datetime, end_datetime, agenda_details) VALUES (?, ?, ?, ?, ?)',
            [tripId, agenda_title.trim(), start_datetime, end_datetime, agenda_details ? agenda_details.trim() : null]
        );

        return res.status(201).json({
            message: 'Itinerary activity added successfully',
            itinerary_id: result.insertId,
            itinerary: {
                id: result.insertId,
                trip_id: parseInt(tripId),
                agenda_title: agenda_title.trim(),
                start_datetime,
                end_datetime,
                agenda_details: agenda_details ? agenda_details.trim() : null
            }
        });
    } catch (error) {
        console.error('Add itinerary activity error:', error);
        return res.status(500).json({ error: 'Server error during itinerary activity addition.' });
    }
};

exports.updateItinerary = async (req, res) => {
    const tripId = req.params.id;
    const itineraryId = req.params.itineraryId;
    const userId = req.user.id;
    const { agenda_title, start_datetime, end_datetime, agenda_details } = req.body;

    if (!agenda_title || !start_datetime || !end_datetime) {
        return res.status(400).json({ error: 'Agenda title, start datetime, and end datetime are required.' });
    }

    if (isEndDateBeforeStartDate(start_datetime, end_datetime)) {
        return res.status(400).json({ error: 'End date/time cannot be earlier than start date/time.' });
    }

    try {
        const [membership] = await db.query(
            'SELECT 1 FROM trip_members WHERE trip_id = ? AND user_id = ?',
            [tripId, userId]
        );
        if (membership.length === 0) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this trip.' });
        }

        await db.query(
            'UPDATE itineraries SET agenda_title = ?, start_datetime = ?, end_datetime = ?, agenda_details = ? WHERE id = ? AND trip_id = ?',
            [agenda_title.trim(), start_datetime, end_datetime, agenda_details ? agenda_details.trim() : null, itineraryId, tripId]
        );

        return res.json({ message: 'Itinerary updated successfully' });
    } catch (error) {
        console.error('Update itinerary error:', error);
        return res.status(500).json({ error: 'Server error updating itinerary.' });
    }
};

exports.deleteItinerary = async (req, res) => {
    const tripId = req.params.id;
    const itineraryId = req.params.itineraryId;
    const userId = req.user.id;

    try {
        const [membership] = await db.query(
            'SELECT 1 FROM trip_members WHERE trip_id = ? AND user_id = ?',
            [tripId, userId]
        );
        if (membership.length === 0) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this trip.' });
        }

        await db.query('DELETE FROM itineraries WHERE id = ? AND trip_id = ?', [itineraryId, tripId]);
        return res.json({ message: 'Itinerary deleted successfully' });
    } catch (error) {
        console.error('Delete itinerary error:', error);
        return res.status(500).json({ error: 'Server error deleting itinerary.' });
    }
};