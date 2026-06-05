const express = require('express');
const cors = require('cors');
const db = require('./config/db');
const initDb = require('./config/db_init');
const authRoutes = require('./routes/authRoutes');
const tripRoutes = require('./routes/tripRoutes');
const friendRoutes = require('./routes/friendRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/friends', friendRoutes);

app.get('/', (req, res) => {
    res.json({ message: "Trip Planner API is up and running!" });
});

async function testDbConnection() {
    try {
        const [rows] = await db.query('SELECT 1 + 1 AS solution');
        console.log('✅ Connected to MySQL Database successfully.');
        
        await initDb();
    } catch (error) {
        console.error('❌ Database connection/initialization failed:', error.message);
        process.exit(1); 
    }
}

app.listen(PORT, async () => {
    console.log(`🚀 Server listening on port ${PORT}`);
    await testDbConnection();
});
