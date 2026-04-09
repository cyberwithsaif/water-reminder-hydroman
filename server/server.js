require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const waterLogRoutes = require('./routes/waterLogs');
const reminderRoutes = require('./routes/reminders');
const privacyRoutes = require('./routes/privacy');
const adminRoutes = require('./routes/admin');

const app = express();
const path = require('path');

// Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            ...helmet.contentSecurityPolicy.getDefaultDirectives(),
            "upgrade-insecure-requests": null,
            "script-src-attr": ["'unsafe-inline'"],
        },
    },
    hsts: {
        maxAge: 0,
        includeSubDomains: true,
        preload: false
    },
}));
app.use(cors());
app.use(express.json({ limit: '5mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/water-logs', waterLogRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/privacy', privacyRoutes);
app.use('/api/admin', adminRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Test route
app.get('/debug-ping', (req, res) => {
    res.json({ message: 'pong', routes: ['/api/auth', '/privacy/policy'] });
});

// 404
app.use((req, res) => {
    console.log(`[404] ${req.method} ${req.url}`);
    res.status(404).json({ error: 'Not found', path: req.url });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Hydroman API running on port ${PORT}`);
});
