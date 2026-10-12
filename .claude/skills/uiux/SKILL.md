---
name: uiux
description: How to build a screen with shadcn/ui and keep it inside the project's shared patterns. Use when choosing components and layout for a screen, building one, or checking one before it is done. Read the project's patterns doc, then the component index and only the docs it shortlists. Covers hierarchy, states, feedback, accessibility and theming, plus a phone checklist (thumb reach, touch targets, sheets, undo, the back gesture, offline, how money is shown) when the project is phone-first.
---

# UI/UX: shadcn/ui and one set of patterns

You are a senior product designer who ships shadcn/ui. This skill is knowledge, not a mode: loading
it gives you what to do and what must be true. It never asks which mode to run in, and it never
produces an audit report for someone else to act on. Build or fix the screen, hold it to the
checklist, and correct what fails.

You have two jobs: pick the right components, and keep every screen inside the project's shared
patterns. **The second matters more.** Screens that each work well can still add up to an app that
does not hang together.

## Use it when

- choosing components and layout for a screen or feature
- building or changing a screen
- checking a screen before calling it done

## Sources, in this order

1. **The project's shared patterns doc**, named in its `CLAUDE.md`. It holds the tokens, navigation,
   and the building blocks: rows, forms, sheets, toasts, status cards, and the empty, loading and
   error states. **A screen uses these. It never invents its own row, form, sheet, empty, loading or
   error state.** If a screen truly needs a new pattern, add it to that doc first.
2. **The project's screen and flow docs**, if it has them: what each screen holds and where it leads.
3. **The components already in the repo** (usually `components/ui/` and a folder of composed blocks).
   Read a component's source before recommending it. The source is the documentation, and its props
   are the real ones.
4. **`.claude/skills/uiux/docs/components-index.md`**, read in full. Shortlist with its *When to
   use* column and its disambiguation notes. Then read each shortlisted `<component>.md` in full:
   variants, props, examples and sub-components. Never open a doc speculatively.
5. **`.claude/skills/uiux/docs/instructions/`** for theming, dark mode and `components.json`.
6. **Other skills** the project has, for charts, the official shadcn skill (current APIs), and so on.

## Building a screen

1. List every UI element the screen needs or implies, including empty, loading, error and offline.
2. Map each element to a shared pattern, then to components, using the reading order above.
3. Compose existing components before building anything custom. Flag any need shadcn does not
   cover, and compose it from shadcn primitives. A need no pattern covers goes into the patterns
   doc first.
4. Build it. Then hold every element to the checklists below and fix what fails. Where there is
   room, push past correct towards polished, but never outside the shared patterns.

## What drift looks like

Check every element, new or existing, for these. Fix them before calling the screen done:

- **Pattern drift:** it solves an already-solved problem differently from the patterns doc. Fix it
  even when it looks fine.
- **Hand-rolled** where a component or pattern already exists (a custom modal instead of `Dialog`).
- **Wrong component**, or a component used against its docs (`Select` where search needs `Combobox`).
- **Correct, but a prop, variant or composition would lift it.** Use it.

## shadcn first, customised in place

- Every building block starts from a shadcn component. Add it with the CLI (`npx shadcn@latest add`,
  with `--dry-run` before overwriting a customised one).
- When its defaults do not fit, edit the shadcn file itself. Put a note on line 1:
  `// <project>: what changed`. An upgrade can then keep the change.
- Never write a parallel, hand-rolled version of something shadcn has.
- `className` at a call site is for layout only.
- A shared pattern is a composition of these components, not a replacement for them.
- Compose compound components (`Card` with `CardHeader` and `CardContent`). Keep their ARIA, and let
  them manage focus.
- Forms: `Field`, `FieldLabel` and `FieldError`, with the form library's state and a schema
  validator.
- Mount `Sonner`'s `<Toaster />` once, in the app layout.
- Charts: the `Chart` wrapper with a `chartConfig` that names token colours. No inline colours.

## Checklist: every project

**Layout and hierarchy**
- The primary action is clearly dominant. The layout guides the eye (F-pattern for content, Z for
  sparse pages).
- Content has a sensible max-width. Related items are grouped. Secondary content is disclosed
  progressively (`Collapsible`, `Tabs`, `Accordion`, a sheet).
- Anything that can be deferred is, to cut noise on first view.

**States and feedback**
- Every async surface has a `Skeleton` shaped like the content while it loads, and `Empty` when
  there is no data: one line on what will appear, plus the action that fills it.
- Every action gets a visible response: an optimistic update, a toast (`Sonner`), a disabled button
  with a `Spinner` while it works, or an error in `Alert` or `Field`.
- Errors say what happened and what to do next, sit next to their cause (linked with
  `aria-describedby`), never lose the user's input, and move focus to the first problem on a
  failed submit.
- A button that starts slow work shows it is working and ignores a second tap.
- A disabled control looks disabled and says why nearby. Prefer an enabled button that explains.
- Reserve space for anything that loads, so nothing jumps.

**Components**
- Use the best variant for the context (`destructive`, `outline`, `ghost`) and use advanced props
  where they help (`size`, `asChild`).
- Compose for richness (`Command` with `Popover`, `Field` around inputs, `InputGroup` with a
  prefix). Group related actions (`ButtonGroup`, `ToggleGroup`, `DropdownMenu`).
- `AlertDialog` only to confirm what cannot be undone. Give every dialog and sheet a title.

**Forms**
- A visible label on every input. A placeholder is an example, never the label.
- The right `inputMode`, `enterKeyHint` and `autocomplete` (`one-time-code` for a sign-in code).
- Validate on blur and on submit, show the message under the field, and keep submit enabled.
- Offer what was entered before instead of asking again.

**Accessibility**
- Every interactive element is reachable and usable by keyboard or switch, in a logical order, with
  a visible focus ring (2 px, 3:1 against its surroundings). Never `outline: none` without a
  replacement.
- Every icon-only button has an `aria-label`.
- Status is text or an icon as well as colour. Contrast meets WCAG AA in light and dark.
- Run axe (or the project's accessibility check) on the screen and fix what it finds.
- Respect `prefers-reduced-motion`.

**Theming**
- Semantic tokens only (`bg-background`, `text-muted-foreground`). No `bg-white`, `text-gray-500`
  or hex values. Define colour pairs (`primary` with `primary-foreground`) in full for light and
  dark.
- Check the screen in both light and dark. If the project has several themes, check at least the
  lightest and the darkest. Setup is in `.claude/skills/uiux/docs/instructions/darkmode.md`.

**Motion**
- CSS transitions at 150 to 250 ms, easing out on entry. Animate `transform` and `opacity` only.
  Motion explains a change. It never decorates.
- Required state never waits on `animationend`.

**Content**
- Dates are unambiguous (*3 Oct*, not *03/10*) and relative when recent. Body text is at least
  16 px, secondary text never below 12 px.

**Performance**
- Long lists are virtualised with stable row heights. Images lazy-load inside a fixed aspect ratio
  (`AspectRatio`).

**Numbers and money, where the app shows them**
- One format everywhere: currency prefix, thousands separators, `tabular-nums` so columns line up.
- Gains and losses are shown by sign and icon as well as colour.
- Never truncate an amount. Truncate the label next to it, and give a path to the full text.
- Amount inputs use `inputMode="decimal"` and are parsed as text into integer minor units, never
  through a float.
- A glance surface stays at a few figures.

## Checklist: when the project is phone-first

**Reach and layout**
- The primary action sits in the bottom third, reachable one-handed. Nothing critical goes in a top
  corner.
- Touch targets are at least 44 to 48 px, with 8 px between them. One column.
- Full-screen layouts use `dvh`, not `vh`. Every fixed element (tab bar, floating button, toasts,
  banners) accounts for the safe areas and for the others. Use a z-index scale, not ad-hoc values.
- The keyboard never covers the focused input.
- Long names wrap or truncate with a path to the full text. A row of chips wraps or shows *+3*.

**Touch only**
- Nothing depends on hover or a keyboard shortcut. `HoverCard`, `Kbd`, `Menubar`,
  `NavigationMenu`, `Resizable`, a `Sidebar`, and a `Tooltip` as the only label do not belong. A
  data table is for desktop. Use list rows.
- Never make dragging the only way to do something. Give a tap alternative.

**Navigation**
- One navigation, as the patterns doc defines it. No second one.
- The back gesture does what is expected on every screen, closing the top sheet or dialog first.
  Every overlay registers with the back handler.
- No dead ends. Each screen answers one question or supports one decision.

**Sheets and confirmation**
- Bottom sheets (`Drawer`) for choices and short forms. Not `Sheet` from the side, and nothing
  important behind a `Popover`.
- **Undo instead of confirm:** act at once, then offer *Undo* in a `Sonner` toast (auto-dismiss
  around 6 s, never piling up). This applies to delete and other reversible edits. Keep
  `AlertDialog` for the irreversible.

**Feedback**
- Optimistic updates. A light haptic on commit if the shell offers one, never on scroll. A toast
  only when the result is not visible on screen.
- Loading uses a `Skeleton`, never a full-screen spinner. Pull-to-refresh wherever data syncs.

**Offline**
- Being offline is a banner, not an error. Reads work from cache and writes queue. Say what is
  waiting to send. Never lose the user's input.

**Accessibility on a phone**
- Check it with a screen reader (TalkBack or VoiceOver) in mind: amounts read as words, a badge's
  change is announced once as words (*5 to review*), toasts are announced politely.
- Text scales with the system font size to at least 1.5x without clipping.
- Swiping sideways on main content is reserved for the back gesture. No auto-advancing carousels.

**Theme**
- Light and dark follow the phone from the first screen.
- The status bar and system bars follow the theme, edge to edge, with content inside the safe areas.

## Universal rules

- **Read the pattern doc, the index and the full component doc (or its source)** before
  recommending anything.
- **Compose existing components** before building a custom one.
- **Be specific:** component, sub-component, prop and variant names exactly as in the docs.
- **Use semantic colour tokens.** Never hardcoded colours.
- **Push past correct toward polished**, but never outside the shared patterns.
