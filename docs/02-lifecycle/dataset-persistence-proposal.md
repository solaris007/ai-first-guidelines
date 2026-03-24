# Dataset Persistence Format Proposal

## Problem Statement

The current `create_dataset.py` implementation has several issues:

1. **Test cases hardcoded in Python** - Difficult to edit, review in PRs, or version independently
2. **Commented-out tests** - No clean way to enable/disable test cases
3. **No schema validation** - Easy to make structural mistakes in test case definitions
4. **No separation of concerns** - Test data mixed with test execution logic

## Requirements

A good dataset persistence format should:

1. **Version-controllable** - Git-friendly, easy to review in PRs
2. **Human-editable** - Easy for non-developers to add/modify test cases
3. **Validatable** - Schema enforcement to catch errors early
4. **Extensible** - Easy to add new fields without breaking existing tooling
5. **Ecosystem-compatible** - Works with existing ML/AI tooling

**Note:** Page content (`page_content`) is scraped dynamically at dataset upload time and stored in Langfuse, not in the source files.

---

## Format Analysis

### 1. YAML

**Example:**
```yaml
dataset:
  name: "alt_text_crew_comprehensive"
  version: "1.0.0"

test_cases:
  - id: "person_id_ceo"
    enabled: true
    category: "person_id"
    scenario: "Person identification - CEO photo"

    input:
      image_url: "https://www.adobe.com/about-adobe/leaders/shantanu-narayen/media_12d8d3c63822589c21147c09d3a1e821c92e8dec0.jpg"
      page_url: "https://www.adobe.com/about-adobe/leaders/shantanu-narayen.html"
      detected_language: "en"
      xpath: "/html/body/main/div/img[1]"

    expected_output:
      description: "Alt-text should identify 'Shantanu Narayen, CEO'"
      language: "en"
      is_decorative: false
      person: "Shantanu Narayen"
      role: "CEO"
```

| Pros | Cons |
|------|------|
| Human-readable and editable | Indentation-sensitive (easy to break) |
| Supports inline comments | Requires `pyyaml` library |
| Handles nested structures naturally | Larger file size than JSON |
| Good for configuration-style data | Less common in ML ecosystems |
| Multi-line strings supported | Harder to append records |

**Best for:** Human-edited configuration, documentation-heavy datasets

---

### 2. JSONL (JSON Lines)

**Example:**
```jsonl
{"_meta": {"dataset_name": "alt_text_crew_comprehensive", "version": "1.0.0"}}
{"id": "person_id_ceo", "enabled": true, "category": "person_id", "scenario": "Person identification - CEO photo", "input": {"image_url": "https://www.adobe.com/...", "page_url": "https://www.adobe.com/about-adobe/leaders/shantanu-narayen.html", "detected_language": "en", "xpath": "/html/body/main/div/img[1]"}, "expected_output": {"description": "Alt-text should identify 'Shantanu Narayen, CEO'", "language": "en", "is_decorative": false, "person": "Shantanu Narayen", "role": "CEO"}}
```

| Pros | Cons |
|------|------|
| Standard ML/AI format (OpenAI, HuggingFace) | No comments supported |
| Stream-friendly (process line by line) | Long lines hard to read/edit |
| Easy to append new records | Less human-readable |
| Built-in `json` module (no dependencies) | Git diffs can be noisy |
| JSON Schema validation | Nested structures on single line |

**Best for:** ML pipelines, programmatic generation, large datasets

---

### 3. CSV (Comma-Separated Values)

**Example:**
```csv
id,enabled,category,scenario,image_url,page_url,detected_language,xpath,expected_description,expected_language,expected_is_decorative,expected_person,expected_role
person_id_ceo,true,person_id,Person identification - CEO photo,https://www.adobe.com/about-adobe/leaders/shantanu-narayen/media_12d8d3c63822589c21147c09d3a1e821c92e8dec0.jpg,https://www.adobe.com/about-adobe/leaders/shantanu-narayen.html,en,/html/body/main/div/img[1],"Alt-text should identify 'Shantanu Narayen, CEO'",en,false,Shantanu Narayen,CEO
person_id_cfo,true,person_id,Person identification - CFO photo,https://www.adobe.com/about-adobe/leaders/media_185a172c96d9994c6158bc2d811c3e47e8602e8cb.png,https://www.adobe.com/about-adobe/leaders.html,en,/html/body/main/section/div[2]/img[1],"Alt-text should identify 'Dan Durn, CFO'",en,false,Dan Durn,CFO
```

| Pros | Cons |
|------|------|
| Universal spreadsheet compatibility | Flat structure only (no nesting) |
| Excel/Google Sheets editable | Escaping commas in values is error-prone |
| Smallest file size | No type information (all strings) |
| Built-in `csv` module | Adding fields requires schema migration |
| Easy to understand structure | No comments supported |
| Great for tabular data | Poor for complex nested objects |

**Best for:** Simple tabular data, spreadsheet workflows, non-technical editors

#### CSV Flattening Strategy

Since CSV doesn't support nested structures, we need to flatten the schema:

| Nested Field | Flattened Column |
|--------------|------------------|
| `input.image_url` | `image_url` |
| `input.page_url` | `page_url` |
| `input.detected_language` | `detected_language` |
| `expected_output.description` | `expected_description` |
| `expected_output.language` | `expected_language` |
| `expected_output.is_decorative` | `expected_is_decorative` |
| `expected_output.person` | `expected_person` |
| `expected_output.role` | `expected_role` |

#### CSV with Metadata Sidecar

To handle dataset-level metadata, use a separate file:

```
datasets/
├── alt_text_comprehensive.csv          # Test cases
└── alt_text_comprehensive.meta.json    # Dataset metadata
```

**Metadata file (`alt_text_comprehensive.meta.json`):**
```json
{
  "dataset_name": "alt_text_crew_comprehensive",
  "version": "1.0.0",
  "description": "Comprehensive evaluation dataset for AltText Crew",
  "schema_version": "1.0",
  "categories": ["accuracy", "accessibility", "localization", "person_id"]
}
```

---

## Comparison Matrix

| Feature | YAML | JSONL | CSV |
|---------|------|-------|-----|
| **Human readability** | ★★★★★ | ★★☆☆☆ | ★★★★☆ |
| **Human editability** | ★★★★☆ | ★★☆☆☆ | ★★★★★ (spreadsheet) |
| **Nested structures** | ★★★★★ | ★★★★★ | ★☆☆☆☆ |
| **Comments** | ★★★★★ | ☆☆☆☆☆ | ☆☆☆☆☆ |
| **Append new records** | ★★☆☆☆ | ★★★★★ | ★★★★☆ |
| **ML ecosystem** | ★★☆☆☆ | ★★★★★ | ★★★☆☆ |
| **Schema validation** | ★★★☆☆ | ★★★★★ | ★★☆☆☆ |
| **Git diffs** | ★★★★★ | ★★☆☆☆ | ★★★★☆ |
| **File size** | ★★★☆☆ | ★★★★☆ | ★★★★★ |
| **No dependencies** | ☆☆☆☆☆ | ★★★★★ | ★★★★★ |
| **Spreadsheet editing** | ☆☆☆☆☆ | ☆☆☆☆☆ | ★★★★★ |

---

## Recommendation

### Primary: YAML

**Rationale:**
1. Human-readable and easy to edit directly in IDE or text editor
2. Supports inline comments for documenting test cases
3. Handles nested structures naturally (input, expected_output)
4. Clean git diffs - easy to review changes in PRs
5. Multi-line strings supported for complex descriptions

### Secondary: CSV for Non-Technical Contributors

**Rationale:**
1. Spreadsheet-compatible for PMs/QA to add test cases
2. Provide CSV → YAML conversion script
3. Use CSV as "intake" format, YAML as "source of truth"

### Hybrid Workflow

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Google Sheet   │────▶│  Export CSV  │────▶│  Convert to     │
│  (contributors) │     │              │     │  YAML           │
└─────────────────┘     └──────────────┘     └────────┬────────┘
                                                      │
                                                      ▼
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Langfuse       │◀────│  Load to     │◀────│  YAML           │
│  (runtime)      │     │  Langfuse    │     │  (source of     │
└─────────────────┘     └──────────────┘     │   truth in git) │
                                             └─────────────────┘
```

---

## Proposed Directory Structure

```
app/evaluation/alt_text_crew/
├── datasets/
│   ├── alt_text_comprehensive.yaml     # Source of truth
│   └── alt_text_comprehensive.csv      # Optional: for spreadsheet editing
├── scripts/
│   ├── load_dataset.py                 # YAML → Langfuse (scrapes page_content dynamically)
│   ├── export_dataset.py               # Langfuse → YAML
│   ├── csv_to_yaml.py                  # CSV → YAML conversion
│   └── validate_dataset.py             # Schema validation (Pydantic)
├── create_dataset.py                   # Existing (to be deprecated)
├── run_baseline.py
└── ...
```

---

## Implementation Plan

### Phase 1: YAML Foundation
1. Define Pydantic models for alt-text test cases (schema validation)
2. Create `load_dataset.py` to load YAML → Langfuse (with dynamic page scraping)
3. Migrate existing test cases from `create_dataset.py` to YAML
4. Add `validate_dataset.py` for Pydantic-based schema validation

### Phase 2: CSV Workflow (Optional)
1. Create `csv_to_yaml.py` converter
2. Document spreadsheet workflow for contributors
3. Add CSV template with column descriptions

### Phase 3: Bidirectional Sync
1. Create `export_dataset.py` to export Langfuse → YAML
2. Document sync workflow for keeping git and Langfuse in sync

---

## Open Questions

1. **Dataset versioning:** How to handle breaking schema changes?
   - Semantic versioning in metadata?
   - Migration scripts?
