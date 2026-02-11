# For Domain Experts: Growing Into Production

**Companion to [AI-First Leadership](ai-first-leadership.md)**

If you are a domain expert - an SEO specialist, a GEO analyst, a content strategist, a paid traffic expert - who has learned to build software with AI tools, this section is for you.

You are not an intruder. You are a new category of contributor that did not exist five years ago, and the organizational structures have not caught up to you yet. The pre-AI-first model where domain experts filed tickets and waited three sprints for engineers to build the wrong thing was not a golden age - it was a bottleneck that cost customers and revenue. Your ability to ship your own ideas is genuinely valuable.

That said, the production concerns in the leadership document are real. Code that works on your machine and code that works reliably at scale for thousands of users are different things. Learning the difference is not gatekeeping - it is a skill you can develop.

## The Domain Expert Development Path

Think of production readiness as a progression, not a gate:

1. **Sandbox**: Prototype in isolated environments. Validate ideas, test hypotheses, demonstrate feasibility. No production risk. This is where weekend prototypes and quick experiments belong.
2. **Fluid layer with review**: Submit PRs to fluid-layer services with full engineer review. Learn from the feedback. Understand why the reviewer asks for error handling, connection limits, and timeout logic. Every review is a lesson.
3. **Fluid layer with ownership**: Own a fluid-layer service in production. Set up monitoring. Join the on-call rotation for your services. Learn what it means when your code breaks at scale - not as a punishment, but as an education.
4. **Durable-aware contributor**: Understand the substrate boundary well enough to know when your change touches durable infrastructure. When it does, submit it for architecture review without being asked. The guardrails become instincts.

This progression takes months, not weeks. That is normal. Engineers spend years developing production judgment. The difference is that you bring domain expertise no engineer can match. An SEO specialist who understands connection pooling builds better audit tools than an engineer who learned SEO from a JIRA ticket.

## Your Engineering Buddy

This progression works best with support. Your team's existing mentoring structures should pair you with a specific engineer who:

- Reviews your PRs and explains the why behind their feedback, not just the what
- Is your first call when something breaks in your service
- Proactively flags when your changes are approaching a substrate boundary
- Gradually shifts from "reviewing everything" to "reviewing durable-layer changes only" as you progress

The assignment should be explicit: "Jenna is your production buddy" is better than "ask the team if you need help." Engineers who serve as production buddies should have this reflected in their workload and performance reviews - it is real work, not charity.

## Fluid vs Durable: Concrete Examples

The substrate boundary can feel abstract. Here are concrete examples of what falls where, so you can develop the instinct for classifying your own work:

| Change | Layer | Why |
|--------|-------|-----|
| A new dashboard that reads from existing APIs | **Fluid** | Consumes data, does not change how data is stored or served |
| An audit script that writes results to a new S3 bucket | **Fluid** (borderline) | Creates a new storage location, but isolated - does not affect existing data flows |
| Adding a column to a shared database table | **Durable** | Schema changes affect every service that reads from that table |
| Modifying an API response format | **Durable** | Every downstream consumer must handle the new format or break |
| A cron job that sends weekly email reports | **Fluid** | Self-contained feature, failure does not cascade |
| Changing the authentication flow for an existing service | **Durable** | Authentication is load-bearing infrastructure - a bug locks out all users |
| A new internal tool that queries production databases read-only | **Fluid** (with review) | Read-only is safe, but the queries could affect database performance under load |

The rule of thumb: if your change could break something you did not build, it is probably durable. If your change breaks only your own feature, it is fluid. When in doubt, ask your engineering buddy - that is exactly what they are there for.

## What You Can Expect

- **Thorough code review that teaches, not just rejects.** If engineers are only saying "this is wrong" without explaining why, that is a failure of mentorship, not a signal that you do not belong.
- **Guardrails that protect you.** Automated checks that flag when your code touches shared resources, blast radius assessments in PR templates, staging environments that behave like production - these exist to make you safe, not to slow you down.
- **Credit for your contributions.** Domain experts who ship through proper channels, learn from reviews, and grow into production ownership should be recognized and celebrated. Your path is harder than an engineer's because you are learning two disciplines simultaneously.

## What You Owe in Return

- **Respect the review process.** When an engineer says "this needs more work," they are not saying your idea is bad. They are saying the implementation needs hardening. The idea and the implementation are different things.
- **Do not route around guardrails.** If the CI pipeline flags your change as a durable substrate modification, do not ask for an exception. Ask what you need to learn.
- **Accept that blast radius matters more than complexity.** Your one-line config change might have a larger blast radius than a thousand-line feature. Learn to assess impact, not just effort.
- **Invest in operational skills.** Learn to read logs, set up alerts, and understand what a healthy deployment looks like. Even if your first response to a page is "acknowledge, assess, escalate," that is better than silence.

The goal is not to turn domain experts into engineers. It is to create contributors who combine deep domain knowledge with enough production awareness to be safe and effective. That combination is more valuable than either skill set alone.

---

## See Also

- [AI-First Leadership](ai-first-leadership.md) - The full leadership document
- [Substrate Model](../01-foundations/substrate-model.md) - Durable vs fluid layers
- [Philosophy](../01-foundations/philosophy.md) - Core AI-first principles
