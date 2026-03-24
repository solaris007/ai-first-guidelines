# Repository Sync Plan

## Overview

This document tracks the consolidation effort between three related repositories:

| Repository | Purpose | Current DB | Target |
|------------|---------|------------|--------|
| **mystique** (this repo) | Blackboard fact processing, agents, API | Aurora PostgreSQL | Aurora |
| **mysticat-data-service** | Data persistence layer, REST API | Aurora PostgreSQL | Aurora |
| **spacecat** | Audit orchestration (17 microservices) | ~~DynamoDB~~ Aurora PostgreSQL | **DATA MIGRATED** (2026-03-01) — 9.5M records moved to Aurora. DynamoDB read-only backup, pending decommission. |
| **spacecat-infrastructure** | Terraform IaC for AWS resources | Manages Aurora + DynamoDB | Aurora only |

### Mysticat = SpaceCat 2.0

**Mysticat** is the next-generation platform replacing SpaceCat, composed of:
- **mystique** (this repo) - Blackboard/control, agents, fact processing (internal dashboards only)
- **mysticat-data-service** - Data persistence layer, REST API (customer UI talks to this)
- **Customer UI** - Dashboard that interacts **only** with mysticat-data-service

SpaceCat's 17 microservices will be consolidated into this simpler architecture.

## Current State

**As of 2026-03-01:** DynamoDB → PostgreSQL data migration complete across all environments (dev, stage, prod). 9.5M records migrated across 29 entities. All 13 SpaceCat lambdas now backed by Aurora PostgreSQL via PostgREST. DynamoDB table `spacecat-services-data` is read-only backup, pending decommission. CODEOWNERS lock on `spacecat-shared-data-access` is lifted.

**As of 2026-02-02:** mystique points to Aurora and blackboard/control tables are live. Dashboard migration Phase 1 complete.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CURRENT ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  mystique (this repo)              mysticat-data-service                   │
│  ┌─────────────────────┐           ┌─────────────────────┐                  │
│  │ Blackboard Models:  │           │ Domain Models:      │                  │
│  │ (LIVE ON AURORA)    │           │ - Site (794 rows)   │                  │
│  │ - Fact              │           │ - Organization (655)│                  │
│  │ - FactDependency    │           │ - Opportunity (10.9K│                  │
│  │ - SiteConfig        │           │ - Audit (206K)      │                  │
│  │ - TenantConfig      │           │ - Suggestion (404K) │                  │
│  │ - TierDefinition    │           │ - Entitlement (28)  │                  │
│  │ - Scan, TaskQueue   │           │ - 28 more tables... │                  │
│  │ - EventLog + 4 more │           │                     │                  │
│  └─────────┬───────────┘           └─────────┬───────────┘                  │
│            │ R/W own tables                   │ R/W own tables               │
│            │ READ data-service tables          │                              │
│            └─────────────┬───────────────────┘                               │
│                          ▼                                                   │
│               ┌──────────────────────┐                                       │
│               │  Aurora PostgreSQL   │  mysticat-data cluster                │
│               │  34 + 11 = 45 tables │  Engine: aurora-postgresql 16.4       │
│               │  All tables live     │  Host: mysticat-data.cluster-*.rds   │
│               └──────────────────────┘                                       │
│                                                                             │
│  Old RDS (mystique-dev-temp) ──► DEPRECATED, no longer used                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Aurora Connection

| Property | Value |
|----------|-------|
| **Cluster** | `mysticat-data` (aurora-postgresql 16.4, IAM auth enabled) |
| **Host** | `mysticat-data.cluster-c9w0gya2e46s.us-east-1.rds.amazonaws.com` |
| **Database** | `mysticat` |
| **User** | `master` |
| **Password** | In AWS Secrets Manager: `spacecat-terraform-secrets` → key `aurora_master_password` |
| **AWS Account** | `682033462621` (profile: `spacecat_dev`) |
| **Schema** | `public` (single schema, managed by Alembic) |

## Aurora Schema (Live - 34 Tables)

All tables in `public` schema. No custom PostgreSQL enum types - all status/type fields use `varchar`. All tables follow the pattern: `id` (UUID, `gen_random_uuid()`), `created_at`, `updated_at`, `updated_by`.

### Core Domain (owned by data-service)

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `organizations` | 655 | `ims_org_id` (unique), `config` (JSONB), `fulfillable_items` (JSONB) | Root entity. Adobe IMS org. |
| `sites` | 794 | `organization_id` FK, `base_url` (unique per org), `delivery_type`, `hlx_config` (JSONB), `config` (JSONB), `audit_config` (JSONB) | `is_live`, `audits_disabled` booleans |
| `entitlements` | 28 | `organization_id` FK, `product_code` (varchar), `tier` (varchar), `valid_from`, `valid_to` | Unique on `(org_id, product_code)` |
| `projects` | ~50 | `organization_id` FK, `name` (unique per org) | Grouping for sites |
| `configurations` | 1 | `handlers` (JSONB), `jobs` (JSONB), `queues` (JSONB), `slack_roles` (JSONB) | Singleton global config |

### Audit & Opportunity Pipeline

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `audits` | 206K | `site_id` FK, `audit_type`, `audited_at`, `audit_result` (JSONB), `scores` (JSONB) | Indexed on `(site_id, audit_type, audited_at)` |
| `opportunities` | 10.9K | `site_id` FK, `audit_id` FK, `type`, `status`, `origin`, `data` (JSONB), `tags` (JSONB) | Status: NEW/IGNORED/etc. Origin: AUTOMATION |
| `suggestions` | 404K | `opportunity_id` FK, `type`, `status`, `rank`, `data` (JSONB) | Status: OUTDATED, etc. |
| `fix_entities` | - | `opportunity_id` FK, `status` | Fix tracking |
| `fix_entity_suggestions` | - | `fix_entity_id` FK, `suggestion_id` FK | M:N junction |
| `audit_urls` | - | `site_id` FK, `url` (unique per site), `by_customer` | URLs to audit |

### LLMO / Brand Presence

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `brand_presence` | 0 | `site_id` FK, `model`, `date`, `category`, `topics`, `region`, `origin` | Empty in current Aurora |
| `brand_presence_sources` | 0 | `brand_presence_id` FK, `site_id` FK, `hostname`, `content_type`, `is_owned` | Empty in current Aurora |
| `brand_presence_prompts_by_date` | - | `site_id`, `model`, `date`, `category`, `topics`, `prompt`, `region`, `origin` | Unique composite index |
| `brand_presence_topics_by_date` | - | `site_id`, `model`, `date`, `category`, `topics`, `region`, `origin` | Unique composite index |
| `brand_metrics_weekly` | - | `site_id` FK, `week`, `model`, `category`, `region`, `topics` | Weekly aggregations |
| `brand_vs_competitors` | - | `site_id` FK, `competitor`, `date`, `model`, `category`, `region` | Competitor comparison |

### Analytics & Pages

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `site_top_pages` | 31K | `site_id` FK, `url`, `traffic`, `source`, `geo` | Unique on `(site_id, url, source, geo)` |
| `site_top_forms` | - | `site_id` FK, `url`, `form_views`, `form_submissions`, `source`, `geo` | Form analytics |
| `page_citabilities` | - | `site_id` FK, `url` (unique per site) | LLMO citability scores |
| `page_intents` | - | `site_id` FK, `url` (unique per site) | Page intent classification |
| `key_events` | - | `site_id` FK, `name`, `type`, `time` | e.g. "Go Live", "Multiple 404s detected" |

### User & Enrollment

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `site_enrollments` | - | `site_id` FK, `entitlement_id` FK | Unique on `(site_id, entitlement_id)` |
| `trial_users` | - | `organization_id` FK, `email_id`, `status`, `started_at`, `expires_at` | Unique on `(org_id, email_id)` |
| `trial_user_activities` | - | `trial_user_id` FK, `entitlement_id` FK, `site_id` FK, `activity_type`, `activity_data` (JSONB) | Usage tracking |
| `api_keys` | - | `hashed_api_key` (unique), `ims_org_id`, `ims_user_id` | API authentication |

### Scraping & Import

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `scrape_jobs` | - | `type`, `status`, `options` (JSONB), `expires_at` | 120-day default TTL |
| `scrape_urls` | 311K | `scrape_job_id` FK, `url`, `job_status`, `result_url` | Large table |
| `import_jobs` | - | `status`, `started_at` | Partial index on active jobs |
| `import_urls` | - | `import_job_id` FK, `status` | URLs being imported |
| `site_candidates` | - | `base_url`, `source`, `status`, `site_id` FK, `hlx_config` (JSONB) | Site discovery |

### Other

| Table | Rows | Key Columns | Notes |
|-------|------|-------------|-------|
| `handler_overrides` | - | `handler_type`, `entity_type`, `entity_id`, `enabled` | Per-site handler toggles |
| `reports` | - | `site_id` FK, `report_type`, `status` | Generated reports |
| `experiments` | - | `site_id` FK, `status` | A/B test tracking |
| `async_jobs` | - | `topic`, `status` | Async task tracking |
| `alembic_version` | 1 | `version_num` | Schema migration tracker |

### FK Graph

```
organizations
├── sites (organization_id)
│   ├── audits (site_id)
│   │   └── opportunities (audit_id)
│   │       ├── suggestions (opportunity_id)
│   │       └── fix_entities (opportunity_id)
│   │           └── fix_entity_suggestions (fix_entity_id, suggestion_id)
│   ├── opportunities (site_id)
│   ├── brand_presence (site_id)
│   │   └── brand_presence_sources (brand_presence_id, site_id)
│   ├── site_top_pages (site_id)
│   ├── site_top_forms (site_id)
│   ├── audit_urls (site_id)
│   ├── key_events (site_id)
│   ├── experiments (site_id)
│   ├── reports (site_id)
│   ├── page_citabilities (site_id)
│   ├── page_intents (site_id)
│   ├── site_candidates (site_id)
│   ├── site_enrollments (site_id, entitlement_id)
│   └── trial_user_activities (site_id)
├── entitlements (organization_id)
│   ├── site_enrollments (entitlement_id)
│   └── trial_user_activities (entitlement_id)
├── projects (organization_id)
│   └── sites (project_id)
└── trial_users (organization_id)
    └── trial_user_activities (trial_user_id)

scrape_jobs
└── scrape_urls (scrape_job_id)

import_jobs
└── import_urls (import_job_id)
```

## Overlapping Models (Detailed)

| Concept | mystique (blackboard) | Aurora (data-service) | Incompatibilities |
|---------|----------------------|----------------------|-------------------|
| **Site** | `SiteConfig`: `site_id`, `config_overrides` (JSONB), scheduling params | `sites`: `base_url`, `delivery_type`, `hlx_config`, `config`, `audit_config` (all JSONB) | Different scope: scheduling config vs master record. mystique `site_id` references Aurora `sites.id` |
| **Tenant/Org** | `TenantConfig`: `organization_id`, `tier_id`, `config_overrides` (JSONB) | `organizations`: `ims_org_id`, `config` (JSONB), `fulfillable_items` (JSONB) | mystique `organization_id` = Aurora `organizations.id`. Config shapes differ. |
| **Entitlements** | `EntitlementTier` enum (aspirational, to be aligned), `TierDefinition` (config layer) | `entitlements.tier`: `FREE_TRIAL`/`PAID`; `product_code`: `ACO`/`ASO`/`LLMO` | Align mystique enum to Aurora's binary tiers. `TierDefinition` adds dynamic config on top. |
| **Opportunity** | Fact producers emit opportunity-related assertions | `opportunities`: full CRUD with `type`, `status`, `origin`, `data` (JSONB), `tags` (JSONB) | mystique produces; data-service stores. No conflict - complementary. |
| **Audit** | Referenced by fact producers for triggering | `audits`: full CRUD with `audit_type`, `audit_result` (JSONB), `scores` (JSONB) | Read-only from mystique. No conflict. |
| **Brand Presence** | LLMO fact producers | `brand_presence` + `brand_presence_sources` + 3 more tables | Tables exist but empty in Aurora. Mystique produces; data-service stores. |

### Entitlement Tier Alignment

Aurora's current tiers are the source of truth. mystique's `EntitlementTier` enum was aspirational - start from the binary model and evolve.

```
Aurora entitlements (current reality)
─────────────────────────────────────
product_code   tier           count
ACO            FREE_TRIAL     2
ASO            FREE_TRIAL     8
ASO            PAID           9
LLMO           FREE_TRIAL     5
LLMO           PAID           4

valid_from / valid_to: never populated (all NULL)
```

**Plan:** Start with Aurora's binary `FREE_TRIAL`/`PAID` per product code. A site can be enrolled in multiple products via `site_enrollments → entitlements`. mystique's `TierDefinition` provides the dynamic configuration layer on top, keyed on `(product_code, tier)` - what producers to run, page limits, scan frequency per product/tier combination. Shared intermediary facts (`o_html`, `d_markdown`, etc.) are computed once even when both products need them.

mystique's `EntitlementTier` enum should be updated to match Aurora: `free_trial`, `paid` (drop the aspirational `paid_starter`/`paid_standard`/`paid_enterprise` for now).

Per-goal page limits and scheduling complexity are a separate concern - see [proposal-per-goal-limits-and-throttling.md](future/proposal-per-goal-limits-and-throttling.md).

### Scheduling Model: Site-Driven (not Tier-Driven)

The current `TierScheduler` iterates `tier → tenant → site`. This assumed tiers are the top-level grouping. With Aurora as the source of truth, **the site is the scheduling entry point** - tiers are a config lookup, not an iterator.

```
Aurora data model (what drives scheduling):
───────────────────────────────────────────
organizations
└── sites
    └── site_enrollments → entitlements (product_code, tier)
                           └── TierDefinition(product_code, tier) ← config lookup

Scheduling flow:
───────────────
1. Query sites due for scanning
   (from Aurora: sites + site_enrollments + entitlements + last scan time)
2. For each site, look up enrolled products:
   e.g., site X → ASO/PAID + LLMO/FREE_TRIAL
3. For each enrollment, get TierDefinition(product_code, tier):
   - ASO/PAID:       goals=[broken-links, meta-tags, cwv], page_limit=200, frequency=weekly
   - LLMO/FREE_TRIAL: goals=[brand-presence, citability], page_limit=50, frequency=monthly
4. Merge goal sets across products, compute shared intermediaries once
5. Run producers per the merged config
```

**Key shift:** `TierScheduler` becomes `Scheduler` (or `SiteScheduler`). The `TierDefinition` table stays - it's where you configure what each `(product_code, tier)` combination delivers. But it's no longer the iteration axis. `control_site_config` provides per-site overrides on top.

**Implication for `control_tenant_config`:** With site-driven scheduling, tenant-level config is less central. Tenant config becomes "defaults for all sites in this org" rather than a scheduling tier. The cascade simplifies to:
```
TierDefinition(product_code, tier) → control_site_config (override) → scan (runtime)
```

## Consolidation Strategy

### Decision: Single Aurora Database

**Decided 2025-01-26:** Consolidate into one Aurora PostgreSQL database with direct table access by owning service.

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                          TARGET ARCHITECTURE (Mysticat)                              │
├──────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   INTERNAL                                              EXTERNAL                     │
│   ┌─────────────────────┐                              ┌─────────────────────┐      │
│   │ Internal Dashboards │                              │    Customer UI      │      │
│   │ (control, bb debug) │                              │                     │      │
│   └──────────┬──────────┘                              └──────────┬──────────┘      │
│              │                                                    │                  │
│              ▼                                                    ▼                  │
│  mystique                                              mysticat-data-service        │
│  (blackboard + control + agents)                       (REST API)                   │
│  ┌──────────────────────────────┐                     ┌──────────────────────────┐  │
│  │ OWNS:                        │                     │ OWNS:                    │  │
│  │ - blackboard_fact             │                     │ - sites                  │  │
│  │ - blackboard_fact_dependency  │  direct DB read     │ - organizations          │  │
│  │ - control_scan               │◄───────────────────►│ - opportunities          │  │
│  │ - control_task_queue         │  (non-owned tables) │ - audits                 │  │
│  │ - control_event_log          │                     │ - brand_presence         │  │
│  │ - control_tenant_config      │                     │ - entitlements           │  │
│  │ - control_site_config        │                     │ - (28 more tables)       │  │
│  │ - control_* (6 more)         │                     │                          │  │
│  └──────────────┬───────────────┘                     └──────────┬───────────────┘  │
│                 │                                                │                   │
│                 │          direct DB access (owned tables)       │                   │
│                 └──────────────────────┬─────────────────────────┘                   │
│                                        ▼                                             │
│                     ┌──────────────────────────────────┐                             │
│                     │        Aurora PostgreSQL         │                             │
│                     │      (spacecat-infrastructure)   │                             │
│                     │                                  │                             │
│                     │  public schema (all 34+11 tables)│                             │
│                     │  Managed by Alembic              │                             │
│                     └──────────────────────────────────┘                             │
│                                                                                      │
│  SpaceCat (17 microservices) ──────► DATA MIGRATED to Aurora (2026-03-01)            │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### Access Patterns

| Component | DB Access | Notes |
|-----------|-----------|-------|
| **mystique** | Direct R/W to owned tables; direct read for data-service tables | Internal dashboards for control/bb debug |
| **data-service** | Direct R/W to owned tables; can read facts for API | Customer UI talks **only** to this |
| **Customer UI** | None (API only) | All data via mysticat-data-service REST API |
| **Internal dashboards** | Via mystique | Control loop monitoring, fact debugging |

**Decision:** Direct DB reads for non-owned tables (for now). API in future for decoupling.

### Phase 1: Create Blackboard Tables on Aurora ✅ COMPLETE (2026-02-02)

No data migration from old RDS needed - blackboard tables created fresh via direct migration.

**Tables created (all 11, via direct migration on Aurora):**
- [x] `blackboard_fact` - Fact storage with JSONB value
- [x] `blackboard_fact_dependency` - Relationships between facts
- [x] `control_cascade_policy` - Cascade trigger rules
- [x] `control_run` - Individual producer execution records
- [x] `control_tier_definition` - Processing tier definitions (composite PK: `product_code, tier`)
- [x] `control_tenant_config` - Tier configuration overlay per tenant (DEPRECATED)
- [x] `control_site_config` - Scheduling overlay per site (simplified, no tenant FK)
- [x] `control_opportunity_type_config` - Per-opportunity-type configuration
- [x] `control_scan` - Tier/tenant processing runs
- [x] `control_task_queue` - Distributed task queue for HA
- [x] `control_event_log` - Persistent event log for cascade

All 11 models defined in `app/db/blackboard_models.py`. Use `blackboard_` and `control_` prefixes to avoid collision with data-service tables.

**Schema formalized:** [spacecat-infrastructure PR #277](https://github.com/adobe/spacecat-infrastructure/pull/277) — idempotent SQL migration with all 11 tables + indexes + seed data.

**Decision:** Keep `control_site_config`/`control_tenant_config` separate from `sites`/`organizations`.

Rationale: Config override cascade requires separate tables:
```
global_config → tier_config → tenant_configs → site_configs → scan (runtime)
```
Each level can override settings from the level above. Merging would conflate master data with scheduling config.

### Phase 2: Migrate mystique to Aurora ✅ MOSTLY COMPLETE

1. ~~Update mystique `DATABASE_URL` to point to Aurora~~ ✅ Done (`.envrc`, `localstack.env` updated 2026-02-02)
2. ~~Run migration to create blackboard tables on Aurora~~ ✅ Done (direct migration, all 11 tables)
3. [ ] Remove duplicate model definitions (if any)
4. ~~Add read-only queries for data-service tables~~ ✅ Done (`aurora_service.py` — raw SQL queries for sites, organizations, entitlements, enrollments)
5. [ ] Test fact computation with real site/org data

### Phase 3: Infrastructure PR (spacecat-infrastructure) ✅ PARTIALLY DONE

The Aurora cluster already exists.

- [x] Formalize blackboard/control table schemas — [PR #277](https://github.com/adobe/spacecat-infrastructure/pull/277)
- [ ] Ensure mystique ECS tasks have network access to Aurora
- [ ] Add IAM/security group rules for mystique → Aurora
- [ ] Update Secrets Manager with shared credentials (or separate per-service)

## Files to Modify

### mystique (this repo)
- `app/db/blackboard_models.py` - Already has all 11 models with correct table names
- `app/db/init.py` - Ensure `create_all` works against Aurora (may need schema handling)
- `app/models/blackboard.py` - Update Pydantic schemas if needed
- `app/services/control/` - Add read-only queries for `sites`/`organizations`/`entitlements`
- `app/config/` - DATABASE_URL now points to Aurora (done)

### mysticat-data-service
- `alembic/versions/` - Migration to add blackboard/control tables
- OR: mystique runs its own Alembic migrations against the shared DB

### spacecat-infrastructure
- `modules/aurora/` - Ensure schema supports both services
- May need new module for shared schema management

## Related Documentation

- [mysticat-data-service README](../../../mysticat-data-service/README.md)
- [mysticat-data-service TODO](../../../mysticat-data-service/TODO.md)
- [spacecat-infrastructure](../../../spacecat-infrastructure/README.md)
- [Blackboard Architecture](./CLAUDE.md)

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-01-26 | Document current state | Need visibility before consolidation |
| 2025-01-26 | **Single Aurora DB** | Simpler ops, single source of truth, direct access for owned tables |
| 2025-01-26 | **Direct table ownership** | Each service writes only to its tables, can read others |
| 2025-01-26 | **Direct DB reads** (for now) | Simpler, faster; API in future for decoupling |
| 2025-01-26 | **Keep configs separate** | Config cascade: global → tier → tenant → site → scan |
| 2025-01-26 | **SpaceCat → Mysticat** | SpaceCat deprecated; replaced by Mysticat (mystique + data-service + UI) |
| 2026-02-02 | **No blackboard data migration** | Old RDS blackboard data is dev/test only. Create tables fresh on Aurora. |
| 2026-02-02 | **Aurora schema catalogued** | 34 tables in `public` schema, no custom enums, all varchar status fields |
| 2026-02-02 | **Align tiers to Aurora** | Start from Aurora's binary `FREE_TRIAL`/`PAID`. `TierDefinition` adds config on top. Evolve together. |
| 2026-02-02 | **mystique DATABASE_URL → Aurora** | `.envrc` and `localstack.env` updated. Old RDS credentials commented out. |
| 2026-02-02 | **Site-driven scheduling** | Sites are the scheduling entry point, not tiers. `TierDefinition(product_code, tier)` is config lookup, not iteration axis. |
| 2026-02-02 | **Blackboard tables created on Aurora** | All 11 tables created directly via migration script. Schema formalized in [spacecat-infrastructure PR #277](https://github.com/adobe/spacecat-infrastructure/pull/277). |
| 2026-02-02 | **AuroraService for direct DB reads** | `aurora_service.py` provides raw SQL queries for sites, orgs, products, enrollments. No ORM models for data-service tables. |
| 2026-02-02 | **Dashboard migration Phase 1** | Sites tab (primary), Product Config tab, 7 new API endpoints, TierDefinition composite PK, all verified against live Aurora data. |
| 2026-03-01 | **DynamoDB → PostgreSQL migration complete** | 9.5M records across 29 entities migrated to Aurora in all environments. All 13 SpaceCat lambdas now backed by Aurora PostgreSQL via PostgREST. DynamoDB read-only backup pending decommission. |
