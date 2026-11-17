-- 1. games
CREATE TABLE IF NOT EXISTS games (
	game_id SMALLSERIAL PRIMARY KEY,
	game_name TEXT UNIQUE NOT NULL
);
INSERT INTO games (game_name) VALUES ('Standoff 2') ON CONFLICT DO NOTHING;

-- 2. services
CREATE TABLE IF NOT EXISTS services (
	service_id SMALLSERIAL PRIMARY KEY,
	service_name TEXT UNIQUE NOT NULL
);
INSERT INTO services (service_name) VALUES ('Telegram') ON CONFLICT DO NOTHING;
INSERT INTO services (service_name) VALUES ('Discord') ON CONFLICT DO NOTHING;

-- 3. roles
CREATE TABLE IF NOT EXISTS roles (
	role_id SMALLSERIAL PRIMARY KEY,
	role_name TEXT UNIQUE NOT NULL,
	role_can_manage_bans BOOLEAN NOT NULL
);
INSERT INTO roles (role_name, role_can_manage_bans) VALUES ('User', FALSE) ON CONFLICT DO NOTHING;
INSERT INTO roles (role_name, role_can_manage_bans) VALUES ('Admin', TRUE) ON CONFLICT DO NOTHING;

-- 4. tariffs
CREATE TABLE IF NOT EXISTS tariffs (
	tariff_id SMALLSERIAL PRIMARY KEY,
	tariff_name TEXT UNIQUE NOT NULL,
	tariff_tracking_items_limit SMALLINT NOT NULL,
	tariff_include_user_caching BOOLEAN NOT NULL,
	tariff_include_priority_notification BOOLEAN NOT NULL
);
INSERT INTO tariffs (tariff_name, tariff_tracking_items_limit, tariff_include_user_caching, tariff_include_priority_notification) VALUES 
('Free', 40, FALSE, FALSE), ('Premium', 60, TRUE, FALSE), ('VIP', 100, TRUE, TRUE)
ON CONFLICT (tariff_name) DO NOTHING;

-- 5. tracking_targets
CREATE TABLE IF NOT EXISTS tracking_targets (
    tracking_target_id SMALLSERIAL PRIMARY KEY,
    tracking_target_name TEXT UNIQUE NOT NULL
);
INSERT INTO tracking_targets (tracking_target_name) VALUES ('Monitor'), ('For_sale'), ('For_purchase') ON CONFLICT DO NOTHING;

-- 6. items (RESTRICT вместо CASCADE)
CREATE TABLE IF NOT EXISTS items (
	item_id SERIAL PRIMARY KEY,
	game_id SMALLINT NOT NULL REFERENCES games (game_id) ON DELETE RESTRICT,
	external_item_id BIGINT NOT NULL,
	item_name TEXT,
	external_url TEXT,
	file_path TEXT,
	purchase_price NUMERIC(10, 2),
	sale_price NUMERIC(10, 2),
	previous_purchase_price NUMERIC(10, 2),
	previous_sale_price NUMERIC(10, 2),
	hist_min NUMERIC(10, 2),
	hist_max NUMERIC(10, 2),
	hist_min_updated TIMESTAMPTZ,
	hist_max_updated TIMESTAMPTZ,
	UNIQUE (game_id, external_item_id)
);
CREATE INDEX IF NOT EXISTS idx_items__item_name ON items (item_name);

-- 7. localizations
CREATE TABLE IF NOT EXISTS localizations (
	language_id SMALLSERIAL PRIMARY KEY,
	language_code TEXT UNIQUE NOT NULL,
	language_translation JSONB
);
INSERT INTO localizations (language_code, language_translation) VALUES ('en', '{"switch": "Language switched to English"}') ON CONFLICT DO NOTHING;

-- 8. users
CREATE TABLE IF NOT EXISTS users (
	user_id SERIAL PRIMARY KEY,
	service_id SMALLINT NOT NULL REFERENCES services (service_id) ON DELETE RESTRICT,
	external_user_id BIGINT NOT NULL,
	username TEXT,
	language_id SMALLINT NOT NULL DEFAULT 1 REFERENCES localizations (language_id) ON DELETE SET DEFAULT,
	truth_language TEXT NOT NULL,
	joined TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	tariff_id SMALLINT NOT NULL DEFAULT 1 REFERENCES tariffs (tariff_id) ON DELETE SET DEFAULT,
	role_id SMALLINT NOT NULL DEFAULT 1 REFERENCES roles (role_id) ON DELETE SET DEFAULT,
	UNIQUE (service_id, external_user_id)
);

-- 9. notify_subscriptions
CREATE TABLE IF NOT EXISTS notify_subscriptions (
	notify_subscription_id SERIAL PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
	item_id INTEGER NOT NULL REFERENCES items (item_id) ON DELETE RESTRICT,
	preferred_price NUMERIC(10, 2),
	tracking_target_id SMALLINT NOT NULL DEFAULT 1 REFERENCES tracking_targets (tracking_target_id) ON DELETE RESTRICT,
	UNIQUE (user_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_notify_subscriptions__user_id ON notify_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS idx_notify_subscriptions__item_id ON notify_subscriptions (item_id);

-- 10. blacklist
CREATE TABLE IF NOT EXISTS blacklist (
	user_id INTEGER PRIMARY KEY NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
	banned_by INTEGER NOT NULL REFERENCES users (user_id) ON DELETE RESTRICT,
	ban_reason TEXT,
	banned_from TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. system_data
CREATE TABLE IF NOT EXISTS system_data (
	system_data_key TEXT PRIMARY KEY,
	system_data_value JSONB NOT NULL
);