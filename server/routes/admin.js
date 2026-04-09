const express = require('express');
const pool = require('../db/pool');
const jwt = require('jsonwebtoken');

const router = express.Router();

// Fixed Admin Credentials
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'hydroman2026';
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_admin_secret_key_123';

// ─── LOGIN ───
router.post('/login', (req, res) => {
    const { username, password } = req.body;
    
    if (username === ADMIN_USERNAME && password === ADMIN_PASSWORD) {
        const token = jwt.sign({ role: 'admin' }, JWT_SECRET, { expiresIn: '24h' });
        return res.json({ token, message: 'Welcome Admin' });
    }
    
    return res.status(401).json({ error: 'Invalid credentials' });
});

// ─── MIDDLEWARE ───
const adminAuth = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No admin token provided' });
    }

    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err || decoded.role !== 'admin') {
            return res.status(401).json({ error: 'Invalid admin token' });
        }
        next();
    });
};

router.use(adminAuth);

// ─── DASHBOARD STATS ───
router.get('/dashboard', async (req, res) => {
    try {
        const totalUsers = await pool.query('SELECT COUNT(*) FROM users');
        const activeToday = await pool.query("SELECT COUNT(DISTINCT user_id) FROM water_logs WHERE timestamp::date = current_date AND deleted = FALSE");
        const totalWaterMl = await pool.query('SELECT SUM(amount_ml) FROM water_logs WHERE deleted = FALSE');
        const totalLogs = await pool.query('SELECT COUNT(*) FROM water_logs WHERE deleted = FALSE');

        res.json({
            users: parseInt(totalUsers.rows[0].count),
            activeToday: parseInt(activeToday.rows[0].count),
            totalWaterMl: parseInt(totalWaterMl.rows[0].sum || 0),
            totalLogs: parseInt(totalLogs.rows[0].count)
        });
    } catch (err) {
        console.error('Admin dashboard error:', err);
        res.status(500).json({ error: 'Failed to load dashboard data' });
    }
});

// ─── GET USERS ───
router.get('/users', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT u.id, u.name, u.phone, u.gender, u.daily_goal_ml, 
                   COUNT(w.id) as log_count, 
                   COALESCE(SUM(w.amount_ml), 0) as total_drank,
                   u.created_at
            FROM users u
            LEFT JOIN water_logs w ON w.user_id = u.id AND w.deleted = FALSE
            GROUP BY u.id
            ORDER BY u.created_at DESC
        `);

        res.json(result.rows);
    } catch (err) {
        console.error('Admin users error:', err);
        res.status(500).json({ error: 'Failed to load users' });
    }
});


// GET /api/admin/feedback
router.get('/feedback', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT f.id, f.message, f.created_at, u.name, u.phone 
             FROM feedback f 
             JOIN users u ON f.user_id = u.id 
             ORDER BY f.created_at DESC`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Fetch feedback error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;