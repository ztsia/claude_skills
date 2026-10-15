# Escapes

Every bug the owner finds by hand that QA passed. Each entry says why QA missed it, the pin that now
catches it, and the question the eyes pass asks on every changed screen so its *kind* isn't missed
again. The main session adds an entry whenever the owner reports one, before fixing it. Copy this
file to `qa/escapes.md`.

`qa-eyes` reads the **Ask** line of every entry and adds it to its fixed questions.

| # | Found | What the owner saw | Why QA missed it | Pin | Ask |
|---|---|---|---|---|---|
| E1 | Sen, after its walking skeleton | Every screen felt dense and overwhelming: nearly all text one size, section headings smaller and greyer than what they head, every chip and button drawn a full 48 px; then most screens read as plain lists where facts and actions look alike | QA checked what passes or fails (axe, target sizes, journeys), never how a screen feels to read. Nobody looked at a screen as a person would, and density has no rule to fail | Size and structure pins in the e2e suite; the catalogue's trees and pixels show any screen that changes | Is it calm or crowded: one thing to look at first, room between groups, every heading bigger than what it heads, facts and actions looking different? |
