# Concept: Shadow Mode

Shadow Mode is the practice of **running the new blackboard system alongside the old pipeline without affecting production behavior**. It is the first phase of the incremental migration strategy.

---

## Definition

In Shadow Mode, existing crews and audit workers continue to operate exactly as before. The only change is that their outputs are **also** written to the Blackboard as facts. No existing behavior is modified, no existing data flows are interrupted.

```
Crew runs as normal
      |
      +---> Returns result to SpaceCat (existing behavior, unchanged)
      |
      +---> Also writes result to Blackboard as a fact (new, shadow)
            (failure here is logged but does NOT affect the main flow)
```

Shadow Mode is a **write-only validation** phase. Facts are written to the Blackboard for monitoring and quality validation, but nothing reads from the Blackboard yet.

---

## Migration Phases

Shadow Mode is Phase 1 of a five-phase migration strategy:

| Phase | Name | Blackboard Role | SpaceCat Changes | Risk |
|-------|------|-----------------|------------------|------|
| **1** | **Shadow Mode** | Write-only (crews also publish facts) | None | Zero |
| **2** | Internal Reuse | Read-before-compute (check Blackboard first) | None | Low |
| **3** | Event Emission | Emit events when facts change | None | Low |
| **4** | SpaceCat Integration | SpaceCat reads from Blackboard | Proxy layer added | Medium |
| **5** | Full Event-Driven | SpaceCat subscribes to fact events | Remove direct calls | Medium |

Each phase can be rolled back independently without data loss.

---

## Publisher/Consumer Mixins for Dual-Write

The migration uses mixins to add Blackboard interaction to existing crews:

### FactPublisherMixin (Phase 1 - Shadow Mode)

```python
class FactPublisherMixin:
    async def publish_fact(self, key, value, *, page_id=None, website_id=None, ...):
        """Publish a crew output as a fact. Failure is logged but non-blocking."""
        try:
            await self.fact_repo.create(session, FactCreate(key=key, value=value, ...))
        except Exception as e:
            logger.warning(f"Shadow write failed: {e}")  # Never affects main flow
```

### FactConsumerMixin (Phase 2 - Internal Reuse)

```python
class FactConsumerMixin:
    async def get_or_compute(self, key, compute_fn, *, max_age_hours=24):
        """Get from Blackboard cache or compute and store."""
        cached = await self.get_fact(key, ...)
        if cached:
            return cached  # Cache hit - skip LLM call
        result = await compute_fn()
        await self.publish_fact(key, result, ...)
        return result
```

---

## Write-Only Validation During Shadow Phase

During Shadow Mode, the team validates:
- **Data quality**: Are the facts being written correctly? Do they match the expected schema?
- **Volume**: How many facts per crew per day? What is the database growth rate?
- **Latency**: Does the shadow write add measurable latency to crew execution? (Target: <100ms)
- **Failure rate**: How often do shadow writes fail? (Should be near zero)

No customer-facing behavior changes. If problems are discovered, the shadow writes can be disabled via feature flags without any rollback needed.

---

## Feature Flags

```python
BLACKBOARD_MODE = os.getenv("BLACKBOARD_MODE", "shadow")
# "disabled" - No blackboard interaction
# "shadow"   - Write only, don't read (Phase 1)
# "read_write" - Full caching enabled (Phase 2)
# "primary"  - Blackboard is source of truth (Phase 4+)
```

Individual facts can also be toggled:

```python
BLACKBOARD_FLAGS = {
    "read_page_type": True,       # Read d_page_type from Blackboard
    "read_webpage_context": True,  # Read d_webpage_context from Blackboard
    "write_all_facts": True,      # Write all outputs to Blackboard
}
```

---

## Further Reading

- [migrations/roadmap-migration.md](../migrations/roadmap-migration.md) - Full migration roadmap with all five phases
- [migrations/STATUS.md](../migrations/STATUS.md) - Current migration progress

---

*Source: [migrations/roadmap-migration.md](../migrations/roadmap-migration.md)*
