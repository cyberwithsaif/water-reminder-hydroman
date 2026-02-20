const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db/pool');
const msg91Widget = require('../services/msg91_widget');

const router = express.Router();

// POST /api/auth/send-otp
router.post('/send-otp', async (req, res) => {
    try {
        const { phone } = req.body;

        if (!phone || phone.length < 10) {
            return res.status(400).json({ error: 'Valid phone number is required' });
        }

        // Invalidate old OTPs for this phone
        await pool.query(
            `UPDATE otp_codes SET used = TRUE WHERE phone = $1 AND used = FALSE`,
            [phone]
        );

        // Send OTP via MSG91 Widget (local service)
        const result = await msg91Widget.sendOtp(phone);

        if (result.success && result.reqId) {
            const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

            // Store reqId in database for verification (use placeholder code)
            await pool.query(
                `INSERT INTO otp_codes (phone, code, req_id, expires_at) VALUES ($1, $2, $3, $4)`,
                [phone, '000000', result.reqId, expiresAt]
            );

            console.log(`[OTP] Sent to ${phone} via MSG91 Widget, reqId: ${result.reqId}`);

            res.json({
                success: true,
                message: result.message || 'OTP sent successfully',
            });
        } else {
            console.error(`[OTP] MSG91 Widget send failed for ${phone}:`, result.message);
            res.status(500).json({ error: result.message || 'Failed to send OTP' });
        }
    } catch (err) {
        console.error('Send OTP error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/auth/verify-otp
router.post('/verify-otp', async (req, res) => {
    try {
        const { phone, code } = req.body;

        if (!phone || !code) {
            return res.status(400).json({ error: 'Phone and OTP code are required' });
        }

        let verified = false;

        // Get the reqId from database
        const reqIdResult = await pool.query(
            `SELECT id, req_id FROM otp_codes
             WHERE phone = $1 AND used = FALSE AND expires_at > NOW() AND req_id IS NOT NULL
             ORDER BY created_at DESC LIMIT 1`,
            [phone]
        );

        if (reqIdResult.rows.length === 0) {
            return res.status(401).json({ error: 'No pending OTP found or OTP expired' });
        }

        const reqId = reqIdResult.rows[0].req_id;
        const otpId = reqIdResult.rows[0].id;

        // Verify via MSG91 Widget (local service)
        const verifyResult = await msg91Widget.verifyOtp(reqId, code);

        if (verifyResult.success) {
            verified = true;
            console.log(`[OTP] Verified ${phone} via MSG91 Widget`);

            // Mark OTP as used
            await pool.query(
                `UPDATE otp_codes SET used = TRUE WHERE id = $1`,
                [otpId]
            );
        } else {
            console.log(`[OTP] MSG91 Widget verify failed for ${phone}:`, verifyResult.message);
            return res.status(401).json({ error: verifyResult.message || 'Invalid OTP' });
        }

        // Invalidate all remaining OTPs for this phone
        await pool.query(
            `UPDATE otp_codes SET used = TRUE WHERE phone = $1 AND used = FALSE`,
            [phone]
        );

        // Find or create user
        let userResult = await pool.query(
            `SELECT id, phone, name, gender, weight_kg, daily_goal_ml,
                    wake_time, sleep_time, weight_unit
             FROM users WHERE phone = $1`,
            [phone]
        );

        let isNewUser = false;

        if (userResult.rows.length === 0) {
            userResult = await pool.query(
                `INSERT INTO users (phone) VALUES ($1)
                 RETURNING id, phone, name, gender, weight_kg, daily_goal_ml,
                           wake_time, sleep_time, weight_unit`,
                [phone]
            );
            isNewUser = true;
        }

        const user = userResult.rows[0];

        // Generate JWT
        const token = jwt.sign(
            { userId: user.id },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
        );

        res.json({ token, user, is_new_user: isNewUser });
    } catch (err) {
        console.error('Verify OTP error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/auth/me
const authMiddleware = require('../middleware/auth');
router.get('/me', authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, phone, name, gender, weight_kg, daily_goal_ml,
                    wake_time, sleep_time, weight_unit
             FROM users WHERE id = $1`,
            [req.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Auth me error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
