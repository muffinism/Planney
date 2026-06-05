const db = require('./db');

async function initDb() {
    try {
        console.log('Initializing database tables...');
        
        await db.query(`
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                email VARCHAR(255) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                username VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);

        await db.query(`
            CREATE TABLE IF NOT EXISTS trips (
                id INT AUTO_INCREMENT PRIMARY KEY,
                trip_title VARCHAR(255) NOT NULL,
                start_date DATE NOT NULL,
                end_date DATE NOT NULL,
                initiator_username VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);

        await db.query(`
            CREATE TABLE IF NOT EXISTS itineraries (
                id INT AUTO_INCREMENT PRIMARY KEY,
                trip_id INT NOT NULL,
                agenda_title VARCHAR(255) NOT NULL,
                start_datetime DATETIME NOT NULL,
                end_datetime DATETIME NOT NULL,
                agenda_details TEXT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
            )
        `);

        await db.query(`
            CREATE TABLE IF NOT EXISTS friendships (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                friend_id INT NOT NULL,
                status VARCHAR(50) DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_friendship (user_id, friend_id)
            )
        `);

        try {
            await db.query("ALTER TABLE friendships ADD COLUMN status VARCHAR(50) DEFAULT 'pending'");
        } catch (_) {
        }

        await db.query(`
            CREATE TABLE IF NOT EXISTS trip_members (
                trip_id INT NOT NULL,
                user_id INT NOT NULL,
                PRIMARY KEY (trip_id, user_id),
                FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        `);

        const [existingTrips] = await db.query('SELECT id, initiator_username FROM trips');
        for (const trip of existingTrips) {
            const [users] = await db.query('SELECT id FROM users WHERE username = ?', [trip.initiator_username]);
            if (users.length > 0) {
                const userId = users[0].id;
                await db.query('INSERT IGNORE INTO trip_members (trip_id, user_id) VALUES (?, ?)', [trip.id, userId]);
            }
        }
        
        console.log('✅ MySQL Tables initialized or already exist.');
    } catch (error) {
        console.error('❌ Database Initialization failed:', error.message);
        throw error;
    }
}

module.exports = initDb;
