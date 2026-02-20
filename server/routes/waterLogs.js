const express = require('express');
const pool = require('../db/pool');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All routes require auth
router.use(authMiddleware);

// GET /api/water-logs?since=<ISO timestamp>
router.get('/', async (req, res) => {
    try {
        const { since } = req.query;
        let query, params;

        if (since) {
            query = `SELECT id, amount_ml, cup_type, timestamp, deleted, updated_at
               FROM water_logs
               WHERE user_id = $1 AND updated_at > $2
               ORDER BY timestamp DESC`;
            params = [req.userId, since];
        } else {
            query = `SELECT id, amount_ml, cup_type, timestamp, deleted, updated_at
               FROM water_logs
               WHERE user_id = $1
               ORDER BY timestamp DESC`;
            params = [req.userId];
        }

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error('Get water logs error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/water-logs/sync — batch upsert
router.post('/sync', async (req, res) => {
    try {
        const { logs } = req.body;

        if (!Array.isArray(logs) || logs.length === 0) {
            return res.status(400).json({ error: 'No logs provided' });
        }

        const upserted = [];

        for (const log of logs) {
            const result = await pool.query(
                `INSERT INTO water_logs (id, user_id, amount_ml, cup_type, timestamp, updated_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         ON CONFLICT (id) DO UPDATE SET
           amount_ml = EXCLUDED.amount_ml,
           cup_type = EXCLUDED.cup_type,
           timestamp = EXCLUDED.timestamp,
           updated_at = NOW()
         RETURNING id, amount_ml, cup_type, timestamp, deleted, updated_at`,
                [log.id, req.userId, log.amount_ml, log.cup_type || 'glass', log.timestamp]
            );
            upserted.push(result.rows[0]);
        }

        res.json({ synced: upserted.length, logs: upserted });
    } catch (err) {
        console.error('Sync water logs error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// DELETE /api/water-logs/:id — soft delete
router.delete('/:id', async (req, res) => {
    try {
        const result = await pool.query(
            `UPDATE water_logs SET deleted = TRUE, updated_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
            [req.params.id, req.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Log not found' });
        }

        res.json({ deleted: true, id: req.params.id });
    } catch (err) {
        console.error('Delete water log error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
