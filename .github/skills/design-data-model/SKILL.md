---
name: design-data-model
description: Design a data model (entity schema, relationships, indexes) from a requirements description. Use when asked to "design the data model", "create a schema", "what tables do we need", or "model this domain".
di_signal: DESIGN
maturity_required: early
status: approved
---

# Design Data Model

## Overview
Designs a relational (or document) data model from a requirements description,
producing entity definitions, relationship mapping, field-level constraints,
index recommendations, and migration impact notes.

The DESIGN signal is assessed across normalization, auditability, soft-delete
convention, and migration risk before any schema is proposed. When requirements
touch an existing table, RISK is assessed explicitly — schema changes to live
tables carry blast radius and require migration plans.

## When to Use
- When starting a new feature that requires new tables or collections
- When a data model review is part of an architecture or design proposal
- When extending an existing entity with new fields and migration risk must be assessed
- When a work item requires a schema change and the team needs a shared schema draft
- When normalizing or rationalizing an existing model that has grown ad hoc
- Any time the user says: "design the data model", "create a schema", "what tables
  do we need", "model this domain", "design the database structure", "what should
  the ERD look like"

## Instructions

### Step 1: Gather Requirements
**From a work item or feature description:**
- Identify the domain entities (the nouns: Order, User, Product, Invoice)
- Identify the relationships between entities (one-to-many, many-to-many)
- Identify the key query patterns (drive indexing decisions)
- Identify any existing tables that will be affected

Ask for (if not determinable):
- Database type (relational: Postgres, MySQL; document: MongoDB; etc.)
- Whether soft-delete is the team's established convention
- Whether audit fields (`created_at`, `updated_at`) are standard
- Whether the existing schema is documented (read adjacent migration files)

Load context (required, not optional):
- `.dev-iq/config.yaml` → `stack.database` and `stack.orm` (if configured)
- **When extending or modifying an existing table:** read the most recent migration files for that table before proposing any changes. If migration files are inaccessible, mark the RISK layer UNGRADED — schema extension advice without reading the current state is speculative; state this explicitly and do not estimate blast radius.
- **ORM assumption:** if `stack.orm` is not set and ORM usage is inferred from the stack, flag field type recommendations as ASSUMED until confirmed. ActiveRecord, Hibernate, Sequelize, SQLAlchemy, and Entity Framework each have different type-mapping conventions that affect the generated schema.

### Step 2: Assess INTENT Clarity
**Clear enough when:**
- At least two entities and their relationship are described
- The primary query patterns are described or inferable

**Not clear enough when:**
- Only a feature name is given with no domain entities mentioned
- There is a conflict between the proposed model and the existing schema

### Step 3: Identify Entities and Relationships
- List each entity
- State relationship type: one-to-one, one-to-many, many-to-many
- For many-to-many: identify the junction table required

### Step 4: Propose the Schema
For each entity, produce a field definition table.

**Standard fields to include unless convention differs:**
- `id`: UUID or bigint, primary key, generated
- `created_at`: timestamptz, not null, default now()
- `updated_at`: timestamptz, not null, updated on write
- `deleted_at`: timestamptz, nullable — soft delete marker (only if convention used)

**Naming conventions:**
- Tables: lowercase snake_case, plural nouns (`order_items`, not `OrderItem`)
- Foreign keys: `{referenced_table_singular}_id` (`order_id`, `user_id`)
- Boolean fields: `is_` prefix (`is_active`, `is_verified`)
- JSON columns: document when the varying schema is intentional vs. when a
  proper column should be used

### Step 5: Recommend Indexes
- Foreign keys: always indexed — flag any FK without an index
- Frequently filtered columns (status, type, date range): composite indexes
- Unique constraints where business logic requires uniqueness
- Primary key index is assumed — do not list it

### Step 6: Apply DESIGN Checks and RISK Assessment
**DESIGN checks:**
- Normalization: is any field storing data that belongs in another table?
- Denormalization: if intentional, is there an explicit tradeoff note?
- Audit fields: are `created_at` / `updated_at` present on all tables?
- JSON columns: are document columns used where a proper schema would be better?

**RISK assessment:**
- New tables: low risk
- Extending existing tables: medium risk — requires migration with care
- Changing existing columns: high risk — requires migration plan + blast radius

At **Early maturity**: coaching note for each DESIGN finding.
At **Mid/Higher maturity**: structured findings only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Feature or requirements description | Work item ID, paste, or user description | Yes |
| Database type | `.dev-iq/config.yaml` or user states | Required |
| Existing schema / migration files | File path or adjacent files | Auto-read if available |
| Query patterns | ACs or user states | Recommended — drives indexing |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Data Model Design — [Feature Name or Work Item ID]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Database: [PostgreSQL | MySQL | MongoDB | ...]
Assessed: [date]

---

### INTENT Assessment
[Is the requirement clear enough? State any gaps.]

---

### Entity-Relationship Summary

- **[Entity A]** has many **[Entity B]** (one-to-many via `[foreign key]`)
- **[Entity C]** and **[Entity D]** have a many-to-many relationship
  via junction table `[table name]`

---

### Schema Definitions

#### Table: [table_name]

| Field | Type | Nullable | Default | Constraints | Notes |
|-------|------|----------|---------|-------------|-------|
| id | uuid | no | gen_random_uuid() | primary key | |
| [field] | [type] | [yes/no] | [default] | [constraints] | [notes] |
| created_at | timestamptz | no | now() | | |
| updated_at | timestamptz | no | now() | | |

[Repeat for each table]

---

### Index Recommendations

| Table | Index | Columns | Type | Reason |
|-------|-------|---------|------|--------|
| [table] | [name] | [columns] | btree | [query pattern] |

---

### DESIGN Signal Assessment

| Dimension | Assessment | Finding |
|-----------|------------|---------|
| Normalization | [Pass/Weak/Fail] | |
| Audit fields | [Pass/Weak/Fail] | |
| Soft delete convention | [Pass/N/A/Weak] | |
| JSON column usage | [Pass/Weak/N/A] | |
| FK indexes | [Pass/Weak] | |

---

### RISK Assessment

| Risk | Level | Notes |
|------|-------|-------|
| [description] | [Low/Medium/High] | [migration approach] |

**Migration notes:** [migration files needed, reversibility, data impact]

**DESIGN Signal: [STRONG | WEAK | UNGRADED]**

@di-review-required
```

## Examples

### Example 1: Order Management Data Model

**User says:** "We need a data model for orders. Each order belongs to a user,
has one or more line items, and tracks payment and shipping status separately."

**Result:**

```
## Data Model Design — Order Management
Work Item: none provided
Database: PostgreSQL
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — four entities identified, relationships clear, status tracking stated.

---

### Entity-Relationship Summary
- **users** has many **orders** (one-to-many via `orders.user_id`)
- **orders** has many **order_items** (one-to-many via `order_items.order_id`)
- **order_items** references **products** (many-to-one via `order_items.product_id`)

---

### Schema Definitions

#### Table: orders

| Field | Type | Nullable | Default | Constraints | Notes |
|-------|------|----------|---------|-------------|-------|
| id | uuid | no | gen_random_uuid() | primary key | |
| user_id | uuid | no | | FK → users.id | indexed |
| payment_status | text | no | 'pending' | CHECK IN ('pending','paid','failed','refunded') | |
| shipping_status | text | no | 'unshipped' | CHECK IN ('unshipped','shipped','delivered','returned') | |
| total_cents | bigint | no | | > 0 | stored in minor currency units |
| currency | char(3) | no | 'USD' | ISO 4217 | |
| created_at | timestamptz | no | now() | | |
| updated_at | timestamptz | no | now() | | |
| deleted_at | timestamptz | yes | null | | soft delete |

#### Table: order_items

| Field | Type | Nullable | Default | Constraints | Notes |
|-------|------|----------|---------|-------------|-------|
| id | uuid | no | gen_random_uuid() | primary key | |
| order_id | uuid | no | | FK → orders.id | indexed |
| product_id | uuid | no | | FK → products.id | indexed |
| quantity | integer | no | | > 0 | |
| unit_price_cents | bigint | no | | > 0 | price at time of order (intentionally denormalized) |
| created_at | timestamptz | no | now() | | |

Denormalization note: `unit_price_cents` stores the product price at order
time. Product prices change; the order must reflect what the customer was charged.

---

### Index Recommendations

| Table | Index | Columns | Type | Reason |
|-------|-------|---------|------|--------|
| orders | idx_orders_user_id | user_id | btree | "Show my orders" query |
| orders | idx_orders_payment_status | payment_status | btree | Payment reconciliation |
| orders | idx_orders_created_at | created_at DESC | btree | Date-range history |
| order_items | idx_order_items_order_id | order_id | btree | FK lookup |
| order_items | idx_order_items_product_id | product_id | btree | Product-to-orders lookup |

---

### DESIGN Signal Assessment

| Dimension | Assessment | Finding |
|-----------|------------|---------|
| Normalization | Pass | Denormalization intentional and documented |
| Audit fields | Pass | created_at / updated_at on all tables |
| Soft delete | Pass | deleted_at on orders |
| JSON columns | N/A | none used |
| FK indexes | Pass | all FKs indexed |

### RISK Assessment

| Risk | Level | Notes |
|------|-------|-------|
| New tables only | Low | No existing tables touched |

**Migration notes:** Three new tables — additive only. No rollback risk.

**DESIGN Signal: STRONG**

@di-review-required
```

---

### Example 2: Extending a Live Table — Migration Risk Flagged

**User says:** "Add a `subscription_tier` field to the `users` table."

**Result:**

```
## Data Model Design — User Subscription Tier
Work Item: none provided
Database: PostgreSQL
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — single-field addition to an existing table.

---

### Schema Definition (extension to existing users table)

| Field | Type | Nullable | Default | Constraints | Notes |
|-------|------|----------|---------|-------------|-------|
| subscription_tier | text | no | 'free' | CHECK IN ('free','pro','enterprise') | new |

---

### RISK Assessment

| Risk | Level | Notes |
|------|-------|-------|
| Extending live users table | Medium | Must backfill before setting NOT NULL |

**Migration — safe sequence for live table:**
```sql
ALTER TABLE users ADD COLUMN subscription_tier text;
UPDATE users SET subscription_tier = 'free' WHERE subscription_tier IS NULL;
ALTER TABLE users ALTER COLUMN subscription_tier SET NOT NULL;
ALTER TABLE users ALTER COLUMN subscription_tier SET DEFAULT 'free';
ALTER TABLE users ADD CONSTRAINT chk_subscription_tier
  CHECK (subscription_tier IN ('free', 'pro', 'enterprise'));
```

**Reversal:** `ALTER TABLE users DROP COLUMN subscription_tier;`

**Data impact:** All existing users default to 'free'. Confirm this is
correct before running in production.

**DESIGN Signal: STRONG**

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on Denormalization

```
**Finding — Intentional Denormalization (Early maturity):**
`unit_price_cents` is stored directly on `order_items` rather than
read from `products`. This is correct for historical accuracy, but
future developers may see it as a bug and "fix" it.

**DI Coaching Note:** Denormalization is sometimes the right design, but it
must be documented so no one reverses it accidentally. Add a comment to the
migration file: `-- unit_price_cents intentionally denormalized: stores price
at time of order, not current product price`. Without this comment, a well-meaning
developer will eventually "fix" it, breaking historical order accuracy.
```

---

## Governance
- Schema changes to existing live tables are always Medium or High risk — never Low
  — because they require migration coordination across all environments
- Reversible migrations are required unless the change is purely additive (new table
  or new nullable column with a safe default) — non-reversible migrations must be
  explicitly acknowledged
- Denormalized columns must include a rationale comment in the migration file —
  undocumented denormalization is always a DESIGN finding
- All output carries `@di-review-required` — the schema is a draft; the team
  must approve before a migration file is written
- Never propose dropping a column or changing a column type on a live table without
  flagging it as a breaking change and requiring a migration + rollback plan
- When migration files cannot be read for an existing-table change, mark RISK as
  UNGRADED — do not assess blast radius or reversibility without reading the
  current schema state; state the gap explicitly
- ORM-specific field types must not be assumed from the database type alone —
  confirm the ORM or flag type recommendations as ASSUMED
- At Early maturity, every DESIGN finding includes a coaching note explaining
  the production consequence

## Related Skills
- `/design-api` — design the API that will expose this data model; the resource
  model should reflect the schema designed here
- `/generate-adr` — if the model makes a significant design choice (denormalization,
  JSON column, soft-delete convention), generate an ADR to document it
- `/blast-radius-estimator` — if extending a table used by multiple services,
  estimate blast radius before committing to the change
- `/generate-rollback-plan` — for any migration that modifies existing data,
  generate a rollback plan alongside the schema design
