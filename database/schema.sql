-- moneytracker schema (SQLite / Turso). Safe to run many times.
-- Run with: npm run db:migrate
-- Money is stored as integer minor units (MAD * 100). Times are unix ms.

PRAGMA foreign_keys = ON;

-- ---------- auth ----------

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,          -- always lowercase
  name          TEXT NOT NULL DEFAULT '',
  email_verified INTEGER NOT NULL DEFAULT 0,
  currency      TEXT NOT NULL DEFAULT 'MAD',
  theme         TEXT NOT NULL DEFAULT 'dark',  -- dark | light
  phone         TEXT NOT NULL DEFAULT '',
  bio           TEXT NOT NULL DEFAULT '',
  run_at        TEXT NOT NULL DEFAULT '06:00',
  week_start    TEXT NOT NULL DEFAULT 'Monday',
  bg_mode       TEXT NOT NULL DEFAULT 'auto',
  bg_url        TEXT NOT NULL DEFAULT '',
  usd_rate_minor INTEGER NOT NULL DEFAULT 1000,
  usdt_rate_minor INTEGER NOT NULL DEFAULT 1100,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- Password hashes live apart from users. Google-only users have no row here.
CREATE TABLE IF NOT EXISTS passwords (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  hash          TEXT NOT NULL,                 -- pbkdf2$iterations$salt$hash
  updated_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id            TEXT PRIMARY KEY,
  user_id       TEXT REFERENCES users(id) ON DELETE CASCADE,  -- null until signed in
  data          TEXT NOT NULL,                 -- JSON from remix session
  created_at    INTEGER NOT NULL,
  expires_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user_idx    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS sessions_expires_idx ON sessions(expires_at);

-- Linked login providers (Google today).
CREATE TABLE IF NOT EXISTS oauth_accounts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider      TEXT NOT NULL,
  provider_account_id TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  UNIQUE (provider, provider_account_id)
);
CREATE INDEX IF NOT EXISTS oauth_user_idx ON oauth_accounts(user_id);

-- ---------- images ----------

CREATE TABLE IF NOT EXISTS user_images (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL DEFAULT 'avatar',   -- avatar | cover | other
  source        TEXT NOT NULL DEFAULT 'upload',   -- upload | google
  url           TEXT NOT NULL,                    -- remote url or your storage key
  mime          TEXT,
  size_bytes    INTEGER,
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS user_images_user_idx ON user_images(user_id, kind, is_active);

-- ---------- app data ----------

CREATE TABLE IF NOT EXISTS quick_buys (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  icon          TEXT NOT NULL DEFAULT 'Tag',
  price_minor   INTEGER NOT NULL DEFAULT 0,
  sort          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS quick_buys_user_idx ON quick_buys(user_id, sort);

CREATE TABLE IF NOT EXISTS income_sources (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  mode          TEXT NOT NULL DEFAULT 'manual',   -- auto | manual
  amount_minor  INTEGER NOT NULL DEFAULT 0,       -- for auto sources
  every         TEXT,                             -- day | week | month (auto)
  created_at    INTEGER NOT NULL,
  type          TEXT NOT NULL DEFAULT 'manual',
  config        TEXT NOT NULL DEFAULT '{}',
  currency      TEXT NOT NULL DEFAULT 'MAD',
  active        INTEGER NOT NULL DEFAULT 1,
  sort          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS income_sources_user_idx ON income_sources(user_id);

CREATE TABLE IF NOT EXISTS incomes (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_id     TEXT REFERENCES income_sources(id) ON DELETE SET NULL,
  amount_minor  INTEGER NOT NULL,
  day           TEXT NOT NULL,                    -- YYYY-MM-DD
  created_at    INTEGER NOT NULL,
  meta          TEXT NOT NULL DEFAULT '{}',
  ext_key       TEXT NOT NULL DEFAULT '',
  usd_minor     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS incomes_day_idx ON incomes(user_id, day);
-- one payout per source per day (auto income and once-a-day manual sources)
CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_uq ON incomes(user_id, ext_key) WHERE ext_key <> '';

CREATE TABLE IF NOT EXISTS purchases (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  qty           INTEGER NOT NULL DEFAULT 1,
  unit_minor    INTEGER NOT NULL,                 -- price each
  total_minor   INTEGER NOT NULL,
  day           TEXT NOT NULL,                    -- YYYY-MM-DD
  debt_id       TEXT,                             -- set when it is a debt payment
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS purchases_day_idx ON purchases(user_id, day);

-- People are never deleted; paid ones are just hidden from the picker.
CREATE TABLE IF NOT EXISTS people (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS debts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  person_id     TEXT NOT NULL REFERENCES people(id),
  kind          TEXT NOT NULL DEFAULT 'money',    -- money | item
  item_name     TEXT,                             -- e.g. cigarette
  item_qty      INTEGER,
  amount_minor  INTEGER NOT NULL DEFAULT 0,       -- owed now
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS debts_user_idx ON debts(user_id, person_id);

CREATE TABLE IF NOT EXISTS debt_payments (
  id            TEXT PRIMARY KEY,
  debt_id       TEXT NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_minor  INTEGER NOT NULL,
  purchase_id   TEXT REFERENCES purchases(id) ON DELETE SET NULL,
  created_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS goals (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  target_minor  INTEGER NOT NULL DEFAULT 0,
  saved_minor   INTEGER NOT NULL DEFAULT 0,
  is_wish       INTEGER NOT NULL DEFAULT 0,
  done_at       INTEGER,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS goals_user_idx ON goals(user_id);

CREATE TABLE IF NOT EXISTS goal_items (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id       TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  price_minor   INTEGER NOT NULL DEFAULT 0,
  done_at       INTEGER,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS goal_items_goal_idx ON goal_items(goal_id);
CREATE INDEX IF NOT EXISTS goal_items_user_idx ON goal_items(user_id);

CREATE TABLE IF NOT EXISTS notes (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body          TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS notes_user_idx ON notes(user_id, created_at);

-- ---------- trading ----------

CREATE TABLE IF NOT EXISTS trade_sessions (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  day           TEXT NOT NULL,
  deposit_minor INTEGER NOT NULL,
  rate_minor    INTEGER NOT NULL,
  purchase_id   TEXT,
  income_id     TEXT,
  status        TEXT NOT NULL DEFAULT 'open',
  pnl_minor     INTEGER NOT NULL DEFAULT 0,
  return_usdt_minor INTEGER NOT NULL DEFAULT 0,
  return_mad_minor  INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  settled_at    INTEGER
);
CREATE INDEX IF NOT EXISTS trade_sessions_user_idx ON trade_sessions(user_id, status, created_at);

CREATE TABLE IF NOT EXISTS trade_results (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id    TEXT NOT NULL REFERENCES trade_sessions(id) ON DELETE CASCADE,
  game          TEXT NOT NULL,
  idx           INTEGER NOT NULL,
  won           INTEGER NOT NULL,
  pnl_minor     INTEGER NOT NULL,
  state         TEXT NOT NULL DEFAULT 'done',
  asset         TEXT NOT NULL DEFAULT '',
  tf            INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  UNIQUE (session_id, game, idx)
);
CREATE INDEX IF NOT EXISTS trade_results_user_idx ON trade_results(user_id, created_at);
