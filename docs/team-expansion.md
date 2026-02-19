# Agent Fishbowl: Team Gap Analysis

## Purpose

Map the current agent team against the full roster needed to operate Agent Fishbowl as an autonomous, revenue-generating product at scale. Identifies what exists, what's close and needs modification, and what's missing entirely.

---

## Current Team (from agentfishbowl.com/team)

| # | Agent | Role | Cadence | Status |
|---|-------|------|---------|--------|
| 1 | Product Owner | Backlog prioritization, dispatches work | Daily | Active |
| 2 | Engineer | Implements issues, opens PRs | Task-driven | Active |
| 3 | Reviewer | Code review, approves/merges PRs | Triggered by PRs | Active |
| 4 | Product Manager | Roadmap strategy, alignment checks | Periodic | Active |
| 5 | Tech Lead | Technical standards, architecture, debt identification | Periodic | Active |
| 6 | Triage | Validates incoming issues, checks duplicates, routes to PO | Triggered by new issues | Active |
| 7 | UX Reviewer | Reviews live product for usability issues | Periodic | Active |
| 8 | Site Reliability | Health checks, incident response, remediation | Every 4 hours | Active |
| 9 | Writer | Researches topics, writes blog posts, publishes | Scheduled | Active |

**In progress (not yet on team page):**

| # | Agent | Role | Status |
|---|-------|------|--------|
| 10 | Product Analyst | Market research, competitive analysis | Building now |

---

## Target Team for $1M ARR

### Strategy Layer (slow cycle — weekly/monthly)

These agents think about where the business should go. They need broad business context, not codebase context.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Product Analyst** | Context boundary: needs to hold market data, competitor intel, and trend analysis. Prompt space is consumed by research, not codebase. | Weekly | Web search, RSS/news APIs, analytics dashboards |
| **Product Manager** | Context boundary: synthesizes Analyst research + revenue data + user feedback into strategic roadmap decisions. Different prompt context than execution. | Weekly, or triggered by Analyst output | Goals doc, roadmap, revenue metrics, Analyst reports |

### Execution Management Layer (daily cycle)

These agents translate strategy into work and manage the flow.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Product Owner** | Context boundary: needs full backlog state, current sprint, team capacity. Permission boundary: creates and assigns issues, manages project board. | Daily | GitHub Issues, Project board, backlog state |

### Engineering Layer (task-driven, multiple daily cycles)

These agents write and review code. Scale by adding parallel instances.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Engineer (x3)** | Parallelism: more engineers = more throughput. Each needs full codebase context for their assigned task. 3 is the target for meaningful parallel velocity. | Task-driven, 1-2 cycles/day each | Full codebase read/write, branch creation, PR creation |
| **Reviewer (x2)** | Parallelism: needs to keep pace with 3 engineers. Context boundary: review context is different from implementation context (reading code vs writing it). | Triggered by PRs | Codebase read, PR comments, merge permissions |
| **Tech Lead** | Context boundary: holds architecture-level view of the codebase that individual engineers don't carry. Cadence: periodic scans vs task-driven work. | Periodic (daily or every few days) | Codebase read, issue creation |

### Quality Layer (triggered + periodic)

These agents verify that shipped work is actually correct, not just functional.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **QA Analyst** | Context boundary: needs live product state + expected behavior. Fundamentally different from code review — verifies output accuracy, not code quality. Checks data integrity, requirement fulfillment, claim accuracy. | Triggered by deploys + periodic spot checks | Live site access (visual), API access, database read, acceptance criteria from issues |
| **UX Reviewer** | Context boundary: needs to "see" the UI and evaluate experiential quality. Different tools and evaluation criteria than code or data accuracy. | Periodic | Live site access (visual), screenshot/rendering tools |

### Operations Layer (continuous / near-continuous)

These agents keep the lights on and handle real-time concerns.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Site Reliability** | Cadence boundary: runs on a tight loop independent of all other work. Permission boundary: has deploy rollback access that no other agent should have. | Every 4 hours (checks), immediate (incidents) | Azure Monitor, deployment pipeline, rollback permissions |
| **Customer Ops** | Permission boundary: has access to customer communication channels and limited financial actions (refunds below threshold). Context boundary: holds customer interaction history, not codebase. | Triggered by inbound emails/feedback + periodic check | Email access, Stripe (limited — refunds below threshold), issue creation, feedback channels |
| **Financial Analyst** | Permission/blast radius boundary: has Stripe API access, revenue data, billing data. This data should be isolated from all other agents. Cadence: near-continuous for payment events, daily for reporting. | Near-continuous (payment events), daily (reporting) | Stripe API (read + limited write for dunning), MRR/ARR dashboards, revenue reporting |

### Content & Growth Layer (scheduled)

These agents drive awareness and acquisition. Separated because content creation and distribution strategy require different contexts and tools.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Content Creator** | Context boundary: needs topic research, brand voice, SEO data, and draft space. Prompt is fully consumed by writing, not strategy. Outputs content that aligns with goals provided by the Marketing Strategist. | Scheduled (2-3x/week) | Web search, RSS feeds, blog CMS, Captain AI pipeline, image generation |
| **Marketing Strategist** | Context boundary: needs analytics data — SEO gaps, traffic patterns, social engagement, conversion metrics. Outputs directives ("write about X because there's a gap"), not content itself. | Weekly | Analytics dashboards, SEO tools, social metrics, content performance data |

### Governance & Culture Layer (triggered + low frequency)

These agents handle cross-cutting concerns that don't belong to any single domain.

| Agent | Why It's a Separate Agent | Cadence | Key Access/Tools |
|-------|---------------------------|---------|------------------|
| **Escalation Lead** | Context boundary: must be loaded with the specific dispute context only, ideally a different model or fully independent context from the disputing agents. Triggered only when loops are detected (2+ back-and-forth cycles). | Triggered (loop detection) | Read-only access to the dispute thread, write access limited to a single resolution comment |
| **VP of Human Ops** | Cadence/purpose boundary: operates on a completely different objective than every other agent. Not optimizing for throughput or quality — optimizing for culture, engagement, and the watchability of the fishbowl. | Weekly or lower | Activity feed read, issue creation (suggestion-tagged only), social/image posting |

---

## Gap Analysis: Current → Target

### ✅ Keep As-Is (no changes needed)

| Agent | Notes |
|-------|-------|
| **Product Owner** | Role is well-defined and working. No changes. |
| **Engineer** (x1 currently) | Role works. Scaling is addressed below. |
| **Reviewer** (x1 currently) | Role works. Scaling is addressed below. |
| **Product Manager** | Already handles roadmap strategy. See modification below for expanded inputs. |
| **Tech Lead** | Bonus agent not in the original $1M spec — genuinely valuable, keep it. |
| **UX Reviewer** | Already in place and doing the right job. |
| **Site Reliability** | Already in place with 4-hour health checks and remediation playbooks. |

### ⚠️ Modify (close but needs evolution)

| Agent | Current State | Modification Needed |
|-------|--------------|---------------------|
| **Triage → fold into Product Owner** | Triage currently validates incoming issues, checks duplicates, and routes to PO. | This is pure intake filtering — it's a PO sub-task, not a distinct agent role. The context and tools overlap almost entirely with the PO. Fold Triage's responsibilities into the PO and eliminate the standalone agent. One fewer agent to maintain, and the PO already needs to understand every inbound issue anyway. |
| **Product Manager** | Currently manages roadmap and checks strategic alignment. | Expand inputs to include revenue metrics from the Financial Analyst and market research from the Product Analyst. The PM becomes the synthesis layer: Analyst provides research, Financial Analyst provides revenue signals, PM makes strategic calls. No role rename needed, just broader input sources. |
| **Writer → Content Creator** | Currently researches topics, writes blog posts, publishes. | Rename to Content Creator. Scope stays focused on content production, but it now takes direction from the Marketing Strategist rather than self-selecting topics. Still owns research, writing, SEO optimization, and publishing. Loses the strategic "what should I write about" decision — that moves to the Marketing Strategist. |

### 🆕 Add (new agents needed)

| Agent | Why It's Needed |
|-------|----------------|
| **QA Analyst** | Nobody is currently verifying output accuracy. Code review catches code bugs, UX review catches visual bugs, but no one checks whether data displayed is actually correct (e.g., the active agent count being wrong). This is the credibility gap — a hiring manager seeing wrong data on the live site undermines the entire demo. |
| **Escalation Lead** | No conflict resolution mechanism exists. As you scale to 3 engineers + 2 reviewers, disagreement loops will become a real failure mode. Without a tie-breaker, disputes either loop forever (burning tokens) or escalate to the human (defeating autonomy). |
| **Customer Ops** | No agent currently handles inbound customer communication, support requests, or has authority to take limited customer-facing actions like refunds. With revenue comes support burden. |
| **Financial Analyst** | No agent monitors Stripe, tracks MRR/ARR, flags churn, handles dunning for failed payments, or reports revenue trends. Essential for a revenue-generating business and the data needs strict access isolation. |
| **Marketing Strategist** | No agent currently analyzes content performance, identifies SEO gaps, tracks conversion metrics, or directs content strategy based on data. The Writer self-selects topics. For revenue growth, content needs to be strategic, not just consistent. |
| **VP of Human Ops** | No agent injects personality, culture, or unexpected engagement into the team. The fishbowl currently shows pure task execution, which is impressive but not fun to watch. This agent makes the showcase more compelling and produces shareable social content. |

### 📈 Scale (add instances of existing roles)

| Agent | Current Count | Target Count |
|-------|--------------|-------------|
| **Engineer** | 1 | 3 |
| **Reviewer** | 1 | 2 |

---

## Full Target Roster Summary

| # | Agent | Layer | Why This Agent Exists | Status | Action |
|---|-------|-------|----------------------|--------|--------|
| 1 | Product Analyst | Strategy | Conducts market research and competitive analysis so the PM can make strategic decisions based on data, not guesses. | Building now | Complete build, ensure output feeds PM |
| 2 | Product Manager | Strategy | Synthesizes research, revenue signals, and user feedback into roadmap decisions — the strategic brain that decides *what* the company builds and why. | Active | Modify — expand inputs (revenue + research from Analyst and Financial Analyst) |
| 3 | Product Owner | Execution Mgmt | Translates strategy into actionable work — owns the backlog, prioritizes issues, dispatches tasks, and keeps the engineering team moving on the right things. | Active | Modify — absorb Triage responsibilities |
| 4 | Engineer #1 | Engineering | Picks up issues, implements full-stack changes, and opens PRs — the builder that turns backlog items into working software. | Active | Keep |
| 5 | Engineer #2 | Engineering | Parallel throughput — same role as Engineer #1, exists because one engineer can't keep pace with the backlog when the team is operating at scale. | New | Add |
| 6 | Engineer #3 | Engineering | Parallel throughput — third instance to sustain continuous delivery velocity across the product. | New | Add |
| 7 | Reviewer #1 | Engineering | Code quality gate — reviews every PR for correctness, standards, and maintainability before anything merges to main. | Active | Keep |
| 8 | Reviewer #2 | Engineering | Parallel review capacity — keeps PR queue from backing up when three engineers are shipping simultaneously. | New | Add |
| 9 | Tech Lead | Engineering | Holds the architecture-level view of the codebase, identifies technical debt and cross-cutting patterns that individual engineers miss in task-scoped work. | Active | Keep |
| 10 | QA Analyst | Quality | Verifies that shipped work is *actually correct* — catches data accuracy bugs, requirement gaps, and claim mismatches that code review and UI review can't see. | **New** | Build |
| 11 | UX Reviewer | Quality | Evaluates the live product through the user's eyes — catches usability friction, accessibility gaps, and visual inconsistencies that don't show up in code. | Active | Keep |
| 12 | Site Reliability | Operations | Keeps the lights on — monitors system health, responds to incidents, executes remediation, and ensures the deployed product stays up and performant. | Active | Keep |
| 13 | Customer Ops | Operations | Handles the customer relationship — responds to inbound support, processes refunds below threshold, and routes product issues to the backlog so paying users feel heard. | **New** | Build |
| 14 | Financial Analyst | Operations | Owns the revenue picture — monitors Stripe, tracks MRR/ARR, flags churn risk, handles dunning, and feeds revenue signals to the PM for strategic decisions. | **New** | Build |
| 15 | Content Creator | Content & Growth | Produces the content — researches, writes, optimizes, and publishes blog posts and articles based on strategic direction from the Marketing Strategist. | Active (as Writer) | Modify — rename, take direction from Marketing Strategist |
| 16 | Marketing Strategist | Content & Growth | Analyzes content performance, identifies SEO gaps and growth opportunities, and directs the Content Creator on *what* to produce based on data, not intuition. | **New** | Build |
| 17 | Escalation Lead | Governance | Breaks ties — invoked only when agents enter disagreement loops, reads both positions, makes a binding call, and documents the reasoning so disputes don't burn tokens or stall work. | **New** | Build |
| 18 | VP of Human Ops | Culture | Injects personality and culture into the agent team — proposes unexpected ideas, runs retros, creates shareable moments, and makes the fishbowl worth watching beyond pure task execution. | **New** | Build |
| — | ~~Triage~~ | ~~Execution Mgmt~~ | ~~Was validating incoming issues, but this is a PO sub-task with identical context and tools — not worth a standalone agent.~~ | ~~Active~~ | **Remove — fold into PO** |

**Total: 18 agents (from current 10)**

---

## Implementation Decisions

Decisions made during the build-out planning session:

### Specialized Engineering Roles (replaces multi-instance model)
- **Engineer** — Full-stack application code
- **Infrastructure Engineer** — Cloud resources, CI/CD, IaC, deployment
- **Reviewer** — Code review and quality gate
- Concurrency comes from spinning up more runners, not duplicating workflows
- The old multi-instance model (Alpha/Bravo/Charlie) was removed in favor of role specialization

### Triage Agent
- **Keep online** for now — fold into PO in a later phase
- No changes to triage in this build-out

### Renames
- **Writer → Content Creator**: Full clean rename across all artifacts (prompt, wrapper, workflow, labels, CLAUDE.md, README). No backwards compatibility shims.

### Scope Boundaries
- **Product Analyst**: Shapes the product offering — pricing, packaging, conversion experiments, competitive positioning. Proposes to PM.
- **Financial Analyst**: Tracks revenue vs costs, P&L, churn, dunning, margin analysis. Recommends operational changes (e.g., "furlough an engineer" if costs exceed revenue).

### Build Order
- Build as if all 18 agents exist simultaneously. No phasing — cross-references assume the full roster.

### Avatars
- Generate [Robohash](https://robohash.org/) avatars for each agent during creation. Store in blob storage under `avatars/` container.
