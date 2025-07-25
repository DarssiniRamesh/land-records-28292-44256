-- Initial setup and schema for Land Records Management System (PostgreSQL/PostGIS)
-- Includes extensions, tables, relations, constraints, initial demo/sample data

-- 1. Enable PostGIS (spatial data support)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. User Management
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    full_name VARCHAR(128),
    phone VARCHAR(32),
    role VARCHAR(32) NOT NULL, -- 'citizen', 'officer', 'admin'
    language_preference VARCHAR(8) DEFAULT 'en', -- For i18n
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    date_joined TIMESTAMP DEFAULT now(),
    last_login TIMESTAMP
);

-- 3. Land Records, with GIS geometry (polygon)
CREATE TABLE IF NOT EXISTS land_records (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(id),
    plot_number VARCHAR(64) NOT NULL,
    address VARCHAR(256),
    area DECIMAL(12,2) NOT NULL, -- in square meters
    land_type VARCHAR(32), -- 'agricultural', 'residential', etc.
    boundaries GEOMETRY(POLYGON, 4326), -- spatial boundaries in WGS84
    extra_attributes JSONB, -- extensible attributes, e.g., soil type
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- 4. Application Types
CREATE TABLE IF NOT EXISTS application_types (
    id SERIAL PRIMARY KEY,
    type_key VARCHAR(32) NOT NULL UNIQUE, -- e.g., 'mutation', 'correction'
    display_label_en VARCHAR(64), -- English
    display_label_hi VARCHAR(64) -- Hindi
);

-- 5. Applications for mutation/corrections/etc.
CREATE TABLE IF NOT EXISTS applications (
    id SERIAL PRIMARY KEY,
    applicant_id INTEGER REFERENCES users(id),
    land_record_id INTEGER REFERENCES land_records(id),
    application_type_id INTEGER REFERENCES application_types(id),
    status VARCHAR(32) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', etc.
    submission_date TIMESTAMP DEFAULT now(),
    reviewed_by INTEGER REFERENCES users(id), -- Officer/admin user ID
    review_date TIMESTAMP,
    remarks VARCHAR(512),
    supporting_documents JSONB, -- list of uploaded document IDs
    extra_data JSONB
);

-- 6. Documents: metadata
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER REFERENCES users(id),
    application_id INTEGER REFERENCES applications(id),
    filename VARCHAR(256) NOT NULL,
    file_url VARCHAR(512) NOT NULL,
    file_type VARCHAR(32),
    uploaded_at TIMESTAMP DEFAULT now(),
    is_verified BOOLEAN DEFAULT false,
    meta JSONB
);

-- 7. Secure Payment Records
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    application_id INTEGER REFERENCES applications(id),
    user_id INTEGER REFERENCES users(id),
    amount DECIMAL(12,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT now(),
    payment_method VARCHAR(32),
    payment_status VARCHAR(24) DEFAULT 'initiated',
    transaction_reference VARCHAR(128),
    sensitive_payload BYTEA -- For encrypted data (if needed)
);

-- 8. Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(128),
    message VARCHAR(512),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT now(),
    notification_type VARCHAR(32)
);

-- 9. Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(128),
    description VARCHAR(512),
    entity_type VARCHAR(32), -- 'user', 'land_record', etc.
    entity_id INTEGER,
    timestamp TIMESTAMP DEFAULT now(),
    ip_address VARCHAR(64),
    extra_data JSONB
);

-- 10. Multilingual Content Support (simple i18n/translation table)
CREATE TABLE IF NOT EXISTS translations (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(32) NOT NULL, -- e.g., 'application_type', 'notification'
    entity_id INTEGER NOT NULL,
    language VARCHAR(8) NOT NULL, -- e.g., 'en', 'hi'
    field VARCHAR(64) NOT NULL, -- e.g., 'display_label'
    translation TEXT NOT NULL
);

-- 11. Demo/sample data for Users (Admin, Officer, Citizen)
INSERT INTO users (username, password_hash, email, full_name, role, is_active, is_verified)
VALUES
('admin1', 'demo_hashed_pw1', 'admin1@demo.com', 'Chief Admin', 'admin', true, true),
('officer1', 'demo_hashed_pw2', 'officer1@demo.com', 'Officer Rama', 'officer', true, true),
('citizen1', 'demo_hashed_pw3', 'citizen1@demo.com', 'Citizen Kumar', 'citizen', true, true)
ON CONFLICT (username) DO NOTHING;

-- 11b. Demo Application Types
INSERT INTO application_types (type_key, display_label_en, display_label_hi)
VALUES
('mutation', 'Mutation Request', 'म्युटेशन अनुरोध'),
('correction', 'Record Correction', 'रिकॉर्ड सुधार'),
('conversion', 'Land Type Conversion', 'भूमि प्रकार परिवर्तन')
ON CONFLICT (type_key) DO NOTHING;

-- 11c. Demo land record with sample polygon for citizen1
INSERT INTO land_records (owner_id, plot_number, address, area, land_type, boundaries, extra_attributes)
VALUES (
  (SELECT id FROM users WHERE username='citizen1'),
  'PLT-001', 'Sector 5, Village Demo',
  1234.50, 'agricultural',
  ST_GeomFromText('POLYGON((77.1 28.6, 77.2 28.6, 77.2 28.7, 77.1 28.7, 77.1 28.6))', 4326),
  '{"soil_type": "alluvial"}'
)
ON CONFLICT DO NOTHING;

-- Indexes for search speed (Example: plot_number search)
CREATE INDEX IF NOT EXISTS idx_landrecords_plotnumber ON land_records(plot_number);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 12. General Referential Integrity (optional: add ON DELETE SET NULL/CASCADE as appropriate)
-- (Already set via references, adjust in migrations as per business rules.)

-- This file can be used directly for schema initialization or as the first Alembic/Liquibase migration.
-- For production deploys, sensitive data like password_hash must be securely hashed and rotated.

-- End of init.sql
