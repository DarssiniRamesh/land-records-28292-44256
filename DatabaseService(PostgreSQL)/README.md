# DatabaseService (PostgreSQL with PostGIS) for Land Records Management

## Overview

This subdirectory houses the schema and migration scripts for the Land Records Management System database using PostgreSQL with PostGIS extension for GIS/spatial support.

### Key Features
- User management (citizens, officers, admins)
- Land records storing polygons for GIS/spatial land plots
- Applications for mutation, correction, conversion (extensible)
- Secure document and file metadata support
- Payment records (with support for encryption)
- Notifications & audit logs
- Multilingual/i18n support
- Relational integrity and extensibility

### Usage

1. Install PostgreSQL with the PostGIS extension. Enable PostGIS in your database after creation:

   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

2. Run the `init.sql` script to create schema and seed demo data:

   ```bash
   psql -U <db_user> -d <db_name> -f init.sql
   ```

3. Use PostGIS functions for spatial queries on land plots (see the `boundaries` field in `land_records`).

4. For upgrades, use migrations (Alembic, Liquibase, Flyway, or manual diffs).

### Demo Data
- Three users: admin, officer, citizen
- Application types; one sample land plot
- Can be safely deleted post-deployment

### Security
- Sensitive fields (e.g., `payments.sensitive_payload`) must be encrypted on write.
- Store only password hashes (never plaintext) in `users`.
- Assign users the minimum privileges required.

### Schema Extensibility
- Most tables feature JSONB/custom fields (`extra_attributes`, `extra_data`) for future expansion.
- Multilingual content managed via `translations` table.

---

## GIS Reference

To run analytics and spatial queries on `land_records.boundaries`:
```sql
SELECT id, plot_number
FROM land_records
WHERE ST_Contains(
  boundaries,
  ST_SetSRID(ST_MakePoint(<longitude>, <latitude>), 4326)
);
```

## Notes

- Adjust foreign key actions (`ON DELETE SET NULL`/`CASCADE`) as per business rules.
- Encode initial passwords securely in production.
- Polygon coordinates use WGS84 (EPSG:4326).

## License
Intended for use as part of the Land Records Digital Platform.

