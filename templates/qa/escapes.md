<!--
TEMPLATE. Copy to qa/escapes.md. Keep the eight columns. The main session adds a row whenever the
owner finds by hand a bug that QA passed, before fixing it, and fills every column. A row is closed
only when its last column names a change to a tool, skill or agent, not just a pin.
-->
# Escapes

Every bug the owner finds by hand that QA passed. Each entry says why QA missed it, the pin that now
catches it, the question the eyes pass asks on every changed screen, which run could have caught it,
and what changed in the tooling so its *kind* isn't missed again. The main session adds an entry
whenever the owner reports one, before fixing it. **An escape is closed only when a tool, skill or
agent changed** (the last column), not by a pin alone: a pin catches that bug, a tool catches its
kind.

`qa-eyes` reads the **Ask** line of every entry and adds it to its fixed questions.

| # | Found | What the owner saw | Why QA missed it | Pin | Ask | Which run could have caught it | What changed in the tooling |
|---|---|---|---|---|---|---|---|
