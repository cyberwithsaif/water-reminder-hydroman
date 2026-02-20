const express = require('express');
const pool = require('../db/pool');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All routes require auth
router.use(authMiddleware);

// GET /api/profile
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, email, name, gender, weight_kg, daily_goal_ml,
              wake_time, sleep_time, weight_unit, updated_at
       FROM users WHERE id = $1`,
            [req.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Profile not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Get profile error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/profile
router.put('/', async (req, res) => {
    try {
        const { name, gender, weight_kg, daily_goal_ml, wake_time, sleep_time, weight_unit } = req.body;

        const result = await pool.query(
            `UPDATE users SET
        name = COALESCE($1, name),
        gender = COALESCE($2, gender),
        weight_kg = COALESCE($3, weight_kg),
        daily_goal_ml = COALESCE($4, daily_goal_ml),
        wake_time = COALESCE($5, wake_time),
        sleep_time = COALESCE($6, sleep_time),
        weight_unit = COALESCE($7, weight_unit),
        updated_at = NOW()
       WHERE id = $8
       RETURNING id, email, name, gender, weight_kg, daily_goal_ml, wake_time, sleep_time, weight_unit, updated_at`,
            [name, gender, weight_kg, daily_goal_ml, wake_time, sleep_time, weight_unit, req.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Profile not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Update profile error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
