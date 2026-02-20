const axios = require('axios');

/**
 * MSG91 Widget API Service
 * Direct implementation of MSG91 Widget for Hydroman
 * Based on onrides MSG91 widget integration
 */
class MSG91Widget {
    constructor() {
        // MSG91 Widget API endpoints
        this.sendOtpUrl = 'https://api.msg91.com/api/v5/widget/sendOtp';
        this.retryOtpUrl = 'https://api.msg91.com/api/v5/widget/retryOtp';
        this.verifyOtpUrl = 'https://api.msg91.com/api/v5/widget/verifyOtp';
    }

    get authKey() {
        return process.env.MSG91_AUTH_KEY || '';
    }

    get widgetId() {
        return process.env.MSG91_WIDGET_ID || '';
    }

    /**
     * Format phone number to include country code
     */
    formatPhone(phone) {
        let cleanPhone = phone.replace(/\D/g, '');
        if (cleanPhone.length === 10) {
            cleanPhone = '91' + cleanPhone;
        } else if (!cleanPhone.startsWith('91')) {
            cleanPhone = '91' + cleanPhone;
        }
        return cleanPhone;
    }

    /**
     * Send OTP via MSG91 Widget API
     * @param {string} phone - Phone number (with or without country code)
     * @returns {Promise<Object>} Object containing success status and reqId
     */
    async sendOtp(phone) {
        const wid = this.widgetId;
        if (!wid) {
            console.error('❌ MSG91 Error: widgetId is EMPTY (check .env)');
            return { success: false, message: 'Widget ID not configured' };
        }

        try {
            const cleanPhone = this.formatPhone(phone);
            console.log(`📤 Sending OTP to ${cleanPhone} via MSG91 Widget API...`);
            console.log(`🔑 Widget ID: ${wid.substring(0, 8)}...`);

            const response = await axios.post(this.sendOtpUrl, {
                widgetId: wid,
                identifier: cleanPhone
            }, {
                headers: {
                    'authkey': this.authKey,
                    'Content-Type': 'application/json'
                }
            });

            console.log(`📥 MSG91 Send Response [${response.status}]:`, JSON.stringify(response.data));

            if (response.data.type === 'success') {
                // Widget API returns the request ID in the 'message' field
                const reqId = response.data.message;
                console.log('✅ MSG91 OTP Send Success, reqId:', reqId);
                return {
                    success: true,
                    reqId: reqId,
                    message: 'OTP sent successfully'
                };
            } else {
                console.error('❌ MSG91 Send Failed:', response.data);
                return {
                    success: false,
                    message: response.data.message || 'Failed to send OTP'
                };
            }
        } catch (error) {
            console.error('❌ MSG91 Send HTTP Error:', error.response?.status, error.response?.data || error.message);
            return {
                success: false,
                message: error.response?.data?.message || 'Network error while sending OTP'
            };
        }
    }

    /**
     * Retry OTP via MSG91 Widget API
     * @param {string} reqId - Request ID from sendOtp response
     * @param {string} retryChannel - Optional: 'sms', 'voice', 'email', 'whatsapp'
     * @returns {Promise<Object>} Success status
     */
    async retryOtp(reqId, retryChannel) {
        const wid = this.widgetId;
        if (!reqId) {
            return { success: false, message: 'Request ID is required' };
        }
        if (!wid) {
            return { success: false, message: 'Widget ID not configured' };
        }

        try {
            console.log(`🔄 Retrying OTP for reqId: ${reqId}, channel: ${retryChannel || 'default'}`);

            const payload = {
                widgetId: wid,
                reqId: reqId
            };

            if (retryChannel) {
                payload.retryChannel = retryChannel;
            }

            const response = await axios.post(this.retryOtpUrl, payload, {
                headers: {
                    'authkey': this.authKey,
                    'Content-Type': 'application/json'
                }
            });

            console.log(`📥 MSG91 Retry Response [${response.status}]:`, JSON.stringify(response.data));

            if (response.data.type === 'success') {
                console.log('✅ MSG91 OTP Retry Success');
                return { success: true, message: 'OTP resent successfully' };
            } else {
                console.error('❌ MSG91 Retry Failed:', response.data);
                return { success: false, message: response.data.message || 'Failed to retry OTP' };
            }
        } catch (error) {
            console.error('❌ MSG91 Retry HTTP Error:', error.response?.status, error.response?.data || error.message);
            return {
                success: false,
                message: error.response?.data?.message || 'Network error while retrying OTP'
            };
        }
    }

    /**
     * Verify OTP via MSG91 Widget API
     * @param {string} reqId - Request ID from sendOtp response
     * @param {string} otp - OTP entered by user
     * @returns {Promise<Object>} Object containing success status
     */
    async verifyOtp(reqId, otp) {
        const wid = this.widgetId;
        if (!reqId || !otp) {
            return { success: false, message: 'Request ID and OTP are required' };
        }
        if (!wid) {
            return { success: false, message: 'Widget ID not configured' };
        }

        try {
            console.log(`🔍 Verifying OTP for reqId: ${reqId}...`);

            const response = await axios.post(this.verifyOtpUrl, {
                widgetId: wid,
                reqId: reqId,
                otp: otp
            }, {
                headers: {
                    'authkey': this.authKey,
                    'Content-Type': 'application/json'
                }
            });

            console.log(`📥 MSG91 Verify Response [${response.status}]:`, JSON.stringify(response.data));

            if (response.data.type === 'success') {
                console.log('✅ MSG91 OTP Verify Success');
                return {
                    success: true,
                    message: 'OTP verified successfully'
                };
            } else {
                console.error('❌ MSG91 Verify Failed:', response.data);
                return { success: false, message: response.data.message || 'Invalid OTP' };
            }
        } catch (error) {
            console.error('❌ MSG91 Verify HTTP Error:', error.response?.status, error.response?.data || error.message);
            return {
                success: false,
                message: error.response?.data?.message || 'Network error while verifying OTP'
            };
        }
    }
}

// Export singleton instance
module.exports = new MSG91Widget();
