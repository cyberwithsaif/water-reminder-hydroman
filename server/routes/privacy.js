const express = require('express');
const router = express.Router();

// Privacy Policy HTML content
const privacyPolicyHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Hydroman</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f7f6;
        }
        .container {
            background: #fff;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 { color: #2196F3; border-bottom: 2px solid #2196F3; padding-bottom: 10px; }
        h2 { color: #1976D2; margin-top: 30px; }
        p { margin-bottom: 15px; }
        ul { margin-bottom: 15px; }
        .footer {
            margin-top: 50px;
            text-align: center;
            font-size: 0.9em;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Privacy Policy for Hydroman</h1>
        <p><strong>Effective Date: March 8, 2026</strong></p>

        <p>Welcome to Hydroman ("we," "our," or "us"). Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use the Hydroman mobile application.</p>

        <h2>1. Information We Collect</h2>
        <p>To provide you with the best hydration tracking experience, we collect the following types of information:</p>
        <ul>
            <li><strong>Personal Information:</strong> Name and gender (to personalize your experience).</li>
            <li><strong>Health-Related Data:</strong> Weight and daily hydration goals (used locally to calculate your needs).</li>
            <li><strong>Usage Data:</strong> Water intake logs, including the amount and time of consumption.</li>
            <li><strong>Device Information:</strong> Unique device identifiers to facilitate account synchronization across multiple devices.</li>
        </ul>

        <h2>2. How We Use Your Information</h2>
        <p>Your data is used for the following purposes:</p>
        <ul>
            <li>To personalize your hydration targets and reminders.</li>
            <li>To synchronize your data across devices so you never lose your progress.</li>
            <li>To provide rewards and specialized offers based on your hydration achievements.</li>
            <li>To improve app performance and user experience.</li>
        </ul>

        <h2>3. Data Storage and Security</h2>
        <p>We take the security of your data seriously. Your information is stored securely on our servers and locally on your device using encrypted storage where applicable. We use industry-standard security measures to prevent unauthorized access, disclosure, or modification of your data.</p>

        <h2>4. Data Sharing</h2>
        <p>We do not sell, trade, or otherwise transfer your personal information to outside parties. Your data is used exclusively within the Hydroman ecosystem to serve your hydration goals.</p>

        <h2>5. Your Rights</h2>
        <p>You have the right to access, update, or delete your personal information at any time through the app settings. If you choose to delete your account, all your data will be permanently removed from our servers.</p>

        <h2>6. Third-Party Services</h2>
        <p>Hydroman may include links to third-party websites (e.g., infexor.com) for rewards. These third-party sites have separate and independent privacy policies. We, therefore, have no responsibility or liability for the content and activities of these linked sites.</p>

        <h2>7. Changes to This Policy</h2>
        <p>We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Effective Date."</p>

        <h2>8. Contact Us</h2>
        <p>If you have any questions about this Privacy Policy, please contact us at support@infexor.com.</p>

        <div class="footer">
            &copy; 2026 infexor.com. All rights reserved.
        </div>
    </div>
</body>
</html>
`;

router.get('/policy', (req, res) => {
    res.send(privacyPolicyHtml);
});

module.exports = router;
