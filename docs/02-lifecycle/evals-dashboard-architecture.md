# Evals Tracker Architecture

## Overview

The Evals Tracker provides visibility into evaluation coverage across opportunity types, displaying aggregate scores from Langfuse and tracking evaluation adoption progress. Types are grouped by business workstreams (Accessibility, On-page SEO, Tech SEO, etc.) in a collapsible accordion UI.

**URL**: `/v1/evals/dashboard`

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Browser                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  eval_dashboard.html (shell: header, skeleton, theme, JS)           │    │
│  │         │                                                           │    │
│  │         │ fetch('/v1/evals/dashboard/content')                      │    │
│  │         ▼                                                           │    │
│  │  eval_dashboard_content.html (async-loaded fragment)                │    │
│  │  ┌──────────────┐  ┌──────────────────┐  ┌───────────────────┐      │    │
│  │  │ Coverage     │  │ Workstream       │  │ Recent Runs       │      │    │
│  │  │ Metric Cards │  │ Accordion Tables │  │ Table             │      │    │
│  │  └──────────────┘  │ + Score Popovers │  └───────────────────┘      │    │
│  │                    └──────────────────┘                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FastAPI Server                                      │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                  Auth Layer (IMS / require_auth)                 │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │  EvalDashboardRoutes (TTL cache: 30 min)                         │       │
│  │  GET /v1/evals/login              → HTML login page (public)     │       │
│  │  GET /v1/evals/dashboard          → HTML shell                   │       │
│  │  GET /v1/evals/dashboard/content  → HTML content fragment        │       │
│  │  GET /v1/evals/dashboard/data     → JSON EvalDashboardData       │       │
│  │  GET /v1/evals/types/{type_name}  → JSON OpportunityTypeEvalStatus│      │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                  EvalDashboardService                            │       │
│  │  ┌────────────────────┐  ┌───────────────────────────────────┐   │       │
│  │  │ discover_evals     │  │ _get_langfuse_metrics_for_        │   │       │
│  │  │ (local files)      │  │  opportunity_type (scores, tests) │   │       │
│  │  ├────────────────────┤  ├───────────────────────────────────┤   │       │
│  │  │ _extract_category  │  │ _get_recent_runs                  │   │       │
│  │  │ (workstreams.py)   │  │ (Langfuse API)                    │   │       │
│  │  └────────────────────┘  └───────────────────────────────────┘   │       │
│  └──────────────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
┌──────────────────────┐      ┌──────────────────────────────────────────────┐
│   Local File System  │      │              Langfuse API                    │
│  ┌────────────────┐  │      │  ┌────────────────┐  ┌────────────────────┐  │
│  │ evaluation/    │  │      │  │ datasets.list  │  │ datasets.get_runs  │  │
│  │ ├─ alt_text/   │  │      │  └────────────────┘  └────────────────────┘  │
│  │ │  ├─ eval_    │  │      │  ┌────────────────┐  ┌────────────────────┐  │
│  │ │  │  config   │  │      │  │ get_dataset    │  │ run_items.list     │  │
│  │ │  ├─ evalua-  │  │      │  │ (item counts)  │  │ (run items)        │  │
│  │ │  │  tors.py  │  │      │  └────────────────┘  └────────────────────┘  │
│  │ │  ├─ crew_    │  │      │  ┌────────────────┐                          │
│  │ │  │  factory  │  │      │  │ trace.get      │                          │
│  │ │  └─ datasets/│  │      │  │ (scores)       │                          │
│  │ ├─ metatags/   │  │      │  └────────────────┘                          │
│  │ ├─ gen_faq/    │  │      └──────────────────────────────────────────────┘
│  │ └─ workstreams │  │
│  │    .py         │  │
│  └────────────────┘  │
└──────────────────────┘
```

## Components

### 1. Data Models (`app/models/eval_dashboard.py`)

```python
EvaluatorScore              # Individual evaluator score with name, value, count, description, evaluator_type ("rule"/"llm")
EvalInfo                    # Discovered eval folder info (name, datasets, evaluators, crew path)
EvalRunInfo                 # Recent run info (run_name, dataset, item_count, date, evaluated_by)
OpportunityTypeEvalStatus   # Status for each opp type (category, has_eval, scores, test_cases)
CategoryCoverage            # Coverage stats per workstream (total, with_evals, percentage)
EvalDashboardData           # Complete response: metrics, types, types_by_category, warnings
```

### 2. Workstream Mapping (`app/evaluation/workstreams.py`)

Maps every `OpportunityTypeEnum` member to a business workstream via `WorkstreamEnum`. Used by the dashboard to group opportunity types in the accordion UI.

| Workstream | Examples |
|-----------|----------|
| Accessibility | alttext, accessibility_remediation, codefix_accessibility |
| Brand Presence | brand_presence, detect/refresh/aggregate/categorize variants |
| CWV (Page Speed) | guidance_cwv, performance_optimization, prerender |
| Forms | hfvlconv, hpvlfn, hpvlfv, forms_a11y, detect_form_details |
| On-page SEO | hotlctr, faqs, readability |
| Security | codefix_security_vulnerabilities |
| SEM (Paid Media) | hihbr, paid_cookie_consent, no_cta_above_the_fold |
| Tech SEO | broken_links, metatags, structured_data_remediation |
| Others | traffic_analysis, llm_error_pages, detect_page_intent, etc. |

`noop` is excluded from the dashboard entirely.

### 3. Service Layer (`app/services/eval_dashboard_service.py`)

#### Core Methods

| Method | Purpose |
|--------|---------|
| `discover_evals()` | Scan `evaluation/` folders for eval configs |
| `build_opportunity_type_mapping()` | Build OpportunityTypeEnum value → list[EvalInfo] mapping |
| `async get_dashboard_data()` | Main entry point — collects all dashboard metrics |

#### Eval Discovery (Local Files)

| Method | Purpose |
|--------|---------|
| `_parse_opportunity_types()` | Parse `opportunity_types` from `eval_config.yaml` |
| `_discover_datasets()` | Find dataset file names from `datasets/*.yaml` |
| `_count_evaluators()` | Count evaluator classes in `evaluators.py` |
| `_discover_evaluators()` | Parse evaluator names, docstrings, and type (rule/llm from parent class) from `evaluators.py` |
| `_discover_crew_path()` | Parse `crew_factory.py` imports to find crew module path |

#### Langfuse Integration

| Method | Purpose |
|--------|---------|
| `_get_langfuse_dataset_names()` | Read `dataset.name` field from each YAML in `datasets/` |
| `_find_langfuse_dataset_by_name()` | Match YAML name to Langfuse dataset (handles versioned names) |
| `_get_langfuse_dataset_item_count()` | Get total item count for a Langfuse dataset |
| `_get_scores_for_dataset()` | Fetch scores from most recent run (limited to 50 traces) |
| `async _get_langfuse_metrics_for_opportunity_type()` | Aggregate scores, test cases, evaluator count across all datasets for a type |
| `_get_recent_runs()` | Fetch recent runs from Langfuse (last 30 days, max 20) |

#### Categorization & Grouping

| Method | Purpose |
|--------|---------|
| `_extract_category()` | Map an opportunity type to its workstream name via `get_workstream()` |
| `_group_by_category()` | Group types by workstream; sort by coverage descending |

#### Error Handling

| Method | Purpose |
|--------|---------|
| `_add_warning()` | Add deduplicated warning message |
| `_handle_langfuse_error()` | Classify Langfuse errors (network vs API); 404s are silently skipped |

### 4. Routes (`app/routes/eval_dashboard_routes.py`)

| Endpoint | Auth | Response | Description |
|----------|------|----------|-------------|
| `GET /v1/evals/login` | None (public) | HTML | Login page with "Sign in with Okta" button; shown on auth errors and after logout |
| `GET /v1/evals/dashboard` | `require_auth` (cookie) | HTML | Shell page with header, skeleton, JS; pre-renders content from cache |
| `GET /v1/evals/dashboard/content` | `require_auth` (cookie) | HTML fragment | Data-dependent content; accepts `?refresh=true` to bust cache |
| `GET /v1/evals/dashboard/data` | `validate_api_access` (token) | JSON | Full `EvalDashboardData` response |
| `GET /v1/evals/types/{type_name}` | `validate_api_access` (token) | JSON | `OpportunityTypeEvalStatus` for a single type |

- **TTL Cache**: 30-minute `cachetools.TTLCache` on dashboard data
- **Pre-rendering**: When cache is warm, the HTML shell includes pre-rendered content to avoid the skeleton flash

### 5. Templates

#### `app/templates/eval_login.html` (Login Page)

Standalone login page shown on auth errors and after logout. Not shown on first visit (unauthenticated users are auto-redirected to Okta).

| Section | Description |
|---------|-------------|
| Branding | Dashboard icon, title |
| Error Alert | Conditionally shown when `?error=` query param is present (red-tinted) |
| Sign-in Button | Okta icon + "Sign in with Okta" → links to `/api/auth/login?next=...` |
| Theme Toggle | Light / Dark / System modes (shares `localStorage` with dashboard) |

#### `app/templates/eval_dashboard.html` (Shell)

| Section | Description |
|---------|-------------|
| Header | Title, subtitle, timestamp, user avatar, hard refresh button, logout, theme toggle |
| Loading Skeleton | Pulse-animated placeholder cards and rows (hidden when content is pre-loaded) |
| Error State | Error message with retry button |
| Theme Toggle | Light / Dark / System modes with `localStorage` persistence |
| Async Loader | `fetch()` to `/v1/evals/dashboard/content`, injects HTML into `#dashboard-content` |

#### `app/templates/eval_dashboard_content.html` (Content Fragment)

| Section | Description |
|---------|-------------|
| Summary Cards | 4 cards: Coverage %, Opportunities with Evals, Missing Evals, Recent Runs (30d) |
| Workstream Accordion | Collapsible sections per workstream with coverage bar in header |
| Filter Pills | All / With Eval / No Eval — filters rows across all accordion sections |
| Opportunity Table | Per-workstream table: name, status badge, eval crews, test cases, evaluators, score |
| Score Popovers | Clickable badges showing per-evaluator breakdown grouped by type (LLM-Based / Rule-Based) with info tooltips |
| Recent Runs | Table of recent Langfuse runs (run name, dataset, evaluated by, items, date) |
| Toast Warnings | Dismissible warning toasts (e.g., Langfuse unreachable, network errors) |

## Data Flow

### 1. Eval Discovery (Local Files)

```
evaluation/
├── alt_text_crew/
│   ├── eval_config.yaml    → opportunity_types: [guidance:missing-alt-text]
│   ├── evaluators.py       → class names, docstrings, name attributes
│   ├── crew_factory.py     → crew import path
│   └── datasets/
│       └── *.yaml          → dataset.name field → Langfuse dataset name
├── metatags_crew/
├── gen_faq_crew/
└── workstreams.py          → OpportunityTypeEnum → WorkstreamEnum mapping
```

### 2. Score Fetching (Langfuse API)

```
1. Read dataset.name from each datasets/*.yaml      → e.g., "alt_text_crew_comprehensive_dataset"
2. datasets.list()                                   → Get all Langfuse datasets
3. Match YAML names to Langfuse datasets             → Handles versioned names (e.g., name_v1.0.0)
4. get_dataset(name)                                 → Get dataset item count (for has_eval threshold)
5. datasets.get_runs(dataset_name)                   → Get runs for dataset
6. Sort by created_at, take most recent
7. dataset_run_items.list(dataset_id, run_name)      → Get run items (limited to 50 traces)
8. trace.get(trace_id)                               → Get trace with scores
9. Aggregate scores by evaluator name
```

### 3. `has_eval` Criteria

An opportunity type is considered to have an evaluation when **both** conditions are met:
1. At least one local eval folder is mapped to it (via `eval_config.yaml`)
2. The combined Langfuse datasets have **>= 20 test cases**

### 4. Authentication Flow

```
GET /v1/evals/dashboard (no session)
    → 302 to /api/auth/login?next=...     (auto-redirect to Okta)
    → Okta auth succeeds                  → 302 to /v1/evals/dashboard
    → Okta auth fails                     → 302 to /v1/evals/login?error=...&next=...
                                            (login page with error message)

GET /api/auth/logout
    → Clears session cookie
    → 302 to /v1/evals/login              (login page with "Sign in with Okta" button)
```

### 5. Dashboard Rendering

```
GET /v1/evals/dashboard (browser)
    │
    ├── Returns eval_dashboard.html (shell)
    │   └── If cache warm: pre-rendered content inline (no skeleton flash)
    │
    └── JS fetch('/v1/evals/dashboard/content')
            │
            ▼
        EvalDashboardRoutes._get_cached_dashboard_data()
            │ (TTL cache: 30 min)
            ▼
        EvalDashboardService.get_dashboard_data()
            │
            ├── build_opportunity_type_mapping()     → Type → [EvalInfo] mapping
            ├── For each OpportunityTypeEnum:
            │   ├── _extract_category()              → Workstream name
            │   └── _get_langfuse_metrics_for_       → Scores, test cases, evaluators
            │       opportunity_type()
            ├── _group_by_category()                 → Accordion grouping
            ├── _get_recent_runs()                   → Recent Langfuse runs
            │
            └── Return EvalDashboardData
                    │
                    ▼
              Jinja2: eval_dashboard_content.html
                    │
                    ▼
              HTML fragment injected into shell
```

## Score Color Coding

| Score Range | Color | CSS Class |
|-------------|-------|-----------|
| >= 80% | Green | `.score-high` |
| 50-79% | Yellow | `.score-medium` |
| < 50% | Red | `.score-low` |

## Popover Behavior

- **Click score badge** → Toggle popover visibility (moved to `<body>` to escape overflow clipping)
- **Click outside** → Close with slide-down animation
- **Arrow pointer** → CSS `::before` pseudo-element; direction (up/down/right) adapts to viewport space; tall popovers fall back to left-side positioning with right-pointing arrow
- **Info icons** → Show evaluator description tooltip on hover (fixed positioning)

## Performance Considerations

| Concern | Mitigation |
|---------|------------|
| Langfuse API latency | TTL cache (30 min) on dashboard data |
| Large datasets | Limit to 50 traces per dataset for score fetching |
| Historical runs | Only fetch most recent run per dataset |
| Slow initial load | Skeleton loading animation; async content fetch |
| Repeat page loads | Pre-rendered content from cache (no skeleton flash) |
| Langfuse unavailable | Graceful degradation with toast warnings |

## File Structure

```
app/
├── auth/
│   └── dependencies.py                 # require_auth (cookie), validate_api_access (token)
├── evaluation/
│   └── workstreams.py                  # WorkstreamEnum, OPPORTUNITY_WORKSTREAM_MAP
├── models/
│   └── eval_dashboard.py              # Pydantic models (CamelCaseModel)
├── services/
│   └── eval_dashboard_service.py      # Business logic
├── routes/
│   ├── auth_routes.py                 # Okta OIDC login/callback/logout
│   └── eval_dashboard_routes.py       # API endpoints (5 routes)
├── templates/
│   ├── eval_login.html                # Login page (auth errors, post-logout)
│   ├── eval_dashboard.html            # Shell template (header, skeleton, JS)
│   └── eval_dashboard_content.html    # Content fragment template (cards, accordion, tables)
└── tests/services/
    └── test_eval_dashboard_service.py # Unit tests (19 tests)
```

## Adding New Evaluations

To add a new evaluation to the dashboard:

1. Create folder: `evaluation/<crew_name>/`
2. Add `eval_config.yaml`:
   ```yaml
   opportunity_types:
     - guidance:your-opportunity-type
   ```
3. Add `evaluators.py` with evaluator classes:
   ```python
   class YourEvaluator:
       """Description shown in dashboard info icon."""
       name = "your_evaluator"
   ```
4. Add `datasets/` folder with dataset YAML files (must include `dataset.name` field):
   ```yaml
   dataset:
     name: "your_crew_dataset_name"
   test_cases:
     - id: test_1
       enabled: true
   ```
5. Ensure the opportunity type is mapped in `evaluation/workstreams.py`
6. Upload >= 20 test cases to Langfuse for the type to show as "Has Eval"
7. Dashboard auto-discovers on next page load (or after cache TTL expires)

## Dependencies

- **Langfuse**: Score storage and retrieval
- **Jinja2**: HTML templating (two-template architecture)
- **FastAPI**: Web framework
- **Pydantic**: Data validation (CamelCaseModel)
- **cachetools**: TTL caching for dashboard data
- **PyYAML**: Parsing `eval_config.yaml` and dataset YAML files
- **requests**: HTTP error classification in Langfuse error handling
