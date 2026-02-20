-- Hydroman Database Schema
-- Run: psql -U hydroman_user -d hydroman -f init.sql

CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  phone         VARCHAR(20) UNIQUE NOT NULL,
  name          VARCHAR(100) DEFAULT '',
  gender        VARCHAR(20) DEFAULT 'male',
  weight_kg     DECIMAL(5,2) DEFAULT 70.0,
  daily_goal_ml INTEGER DEFAULT 2500,
  wake_time     VARCHAR(5) DEFAULT '07:00',
  sleep_time    VARCHAR(5) DEFAULT '23:00',
  weight_unit   VARCHAR(5) DEFAULT 'kg',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS otp_codes (
  id         SERIAL PRIMARY KEY,
  phone      VARCHAR(20) NOT NULL,
  code       VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS water_logs (
  id         VARCHAR(64) PRIMARY KEY,  -- UUID from app
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_ml  INTEGER NOT NULL,
  cup_type   VARCHAR(20) DEFAULT 'glass',
  timestamp  TIMESTAMPTZ NOT NULL,
  deleted    BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reminders (
  id         VARCHAR(64) PRIMARY KEY,  -- UUID from app
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  time       VARCHAR(5) NOT NULL,      -- HH:mm
  label      VARCHAR(100) DEFAULT '',
  is_enabled BOOLEAN DEFAULT TRUE,
  icon       VARCHAR(50) DEFAULT 'water_drop',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast sync queries
CREATE INDEX IF NOT EXISTS idx_water_logs_user_updated ON water_logs(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_codes(phone, expires_at);
