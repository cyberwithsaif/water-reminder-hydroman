const express = require('express');
const pool = require('../db/pool');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All routes require auth
router.use(authMiddleware);

// GET /api/reminders
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, time, label, is_enabled, icon, updated_at
       FROM reminders
       WHERE user_id = $1
       ORDER BY time ASC`,
            [req.userId]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Get reminders error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/reminders/sync — batch upsert
router.post('/sync', async (req, res) => {
    try {
        const { reminders } = req.body;

        if (!Array.isArray(reminders) || reminders.length === 0) {
            return res.status(400).json({ error: 'No reminders provided' });
        }

        const upserted = [];

        for (const r of reminders) {
            const result = await pool.query(
                `INSERT INTO reminders (id, user_id, time, label, is_enabled, icon, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         ON CONFLICT (id) DO UPDATE SET
           time = EXCLUDED.time,
           label = EXCLUDED.label,
           is_enabled = EXCLUDED.is_enabled,
           icon = EXCLUDED.icon,
           updated_at = NOW()
         RETURNING id, time, label, is_enabled, icon, updated_at`,
                [r.id, req.userId, r.time, r.label || '', r.is_enabled !== false, r.icon || 'water_drop']
            );
            upserted.push(result.rows[0]);
        }

        res.json({ synced: upserted.length, reminders: upserted });
    } catch (err) {
        console.error('Sync reminders error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
