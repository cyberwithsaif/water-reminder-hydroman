document.addEventListener('DOMContentLoaded', () => {
    checkAuth();

    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }

    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logout);
    }
});

function checkAuth() {
    const token = localStorage.getItem('hydroman_admin_token');
    if (token) {
        document.getElementById('login-container').style.display = 'none';
        document.getElementById('app-content').style.display = 'block';
        loadDashboard(token);
        loadUsers(token);
        loadFeedback(token);
        updateTimestamp();
        startAutoRefresh(token);
    } else {
        document.getElementById('login-container').style.display = 'block';
        document.getElementById('app-content').style.display = 'none';
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('login-error');

    try {
        const res = await fetch('/api/admin/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await res.json();
        if (res.ok) {
            localStorage.setItem('hydroman_admin_token', data.token);
            checkAuth();
        } else {
            errorDiv.textContent = data.error || 'Login failed';
            errorDiv.style.display = 'block';
        }
    } catch (err) {
        errorDiv.textContent = 'Network error. Please check server.';
        errorDiv.style.display = 'block';
    }
}

function logout() {
    localStorage.removeItem('hydroman_admin_token');
    if (refreshInterval) clearInterval(refreshInterval);
    checkAuth();
}

async function loadDashboard(token) {
    try {
        const res = await fetch('/api/admin/dashboard', {
            headers: { 'Authorization': 'Bearer ' + token }
        });

        if (res.status === 401) return logout();

        const data = await res.json();

        document.getElementById('stat-users').textContent = data.users || 0;
        document.getElementById('stat-active').textContent = data.activeToday || 0;
        document.getElementById('stat-water').textContent = ((data.totalWaterMl || 0) / 1000).toFixed(1);
        document.getElementById('stat-logs').textContent = data.totalLogs || 0;
    } catch (err) {
        console.error('Failed to load dashboard:', err);
    }
}

async function loadUsers(token) {
    try {
        const res = await fetch('/api/admin/users', {
            headers: { 'Authorization': 'Bearer ' + token }
        });

        if (res.status === 401) return logout();

        const users = await res.json();
        const tbody = document.getElementById('users-table-body');
        tbody.innerHTML = '';

        users.forEach(u => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>#${u.id}</td>
                <td>${u.name || '<span class="text-muted">No Name</span>'}</td>
                <td>${u.phone}</td>
                <td>${u.daily_goal_ml}</td>
                <td>${u.total_drank}</td>
                <td><span class="badge bg-secondary">${u.log_count}</span></td>
                <td>${new Date(u.created_at).toLocaleDateString()}</td>
            `;
            tbody.appendChild(tr);
        });
    } catch (err) {
        console.error('Failed to load users:', err);
    }
}


async function loadFeedback(token) {
    try {
        const res = await fetch('/api/admin/feedback', {
            headers: { 'Authorization': 'Bearer ' + token }
        });

        if (res.status === 401) return logout();

        const feedback = await res.json();
        const tbody = document.getElementById('feedback-table-body');
        if (!tbody) return;
        tbody.innerHTML = '';

        feedback.forEach(f => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${new Date(f.created_at).toLocaleString()}</td>
                <td>${f.name || '<span class="text-muted">No Name</span>'}</td>
                <td>${f.phone}</td>
                <td>${f.message}</td>
            `;
            tbody.appendChild(tr);
        });
    } catch (err) {
        console.error('Failed to load feedback:', err);
    }
}

let refreshInterval;

function startAutoRefresh(token) {
    if (refreshInterval) clearInterval(refreshInterval);

    // Refresh every 10 seconds
    refreshInterval = setInterval(() => {
        console.log('Auto-refreshing data...');
        loadDashboard(token);
        loadUsers(token);
        loadFeedback(token);
        updateTimestamp();
    }, 10000);
}

function updateTimestamp() {
    const el = document.getElementById('last-update');
    if (el) {
        el.textContent = 'Last updated: ' + new Date().toLocaleTimeString();
    }
}
