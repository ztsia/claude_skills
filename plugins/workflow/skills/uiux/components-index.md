---
last_checked: 2026-10-24
upstream: shadcn-ui/ui@e55b60b1014c
base: radix
framework: next
---
# shadcn/ui Component Index

Quick-reference for component selection. Read this file first to shortlist candidates, then read only the relevant full docs.

> **All docs live in:** `.claude/skills/uiux/docs/components/<component>.md`

---

## Layout

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Accordion | Vertically stacked collapsible sections for organizing related content where space is limited | type (single/multiple), collapsible, disabled items |
| Card | Container for displaying grouped related content with header, body, and footer | size (default, sm), `--card-spacing` inset variable, edge-to-edge image/content, header, footer |
| Collapsible | Single expandable/collapsible panel for revealing supplementary content | open state, controlled/uncontrolled |
| Resizable | Draggable panel resize handles with keyboard and touch support | orientation (horizontal, vertical), handle visibility |
| ScrollArea | Custom scrollbar styling for scrollable containers | orientation (horizontal, vertical) |
| Tabs | Tabbed interface for switching between related content panels | variant (default, line), orientation (horizontal, vertical) |

---

## Overlay

| Component | When to use | Key variants / features |
|:--|:--|:--|
| AlertDialog | Requires explicit user confirmation for **destructive or irreversible** actions (delete, discard) | size (default, sm), destructive action |
| Dialog | Centered modal for focused content or forms that don't need full-page navigation | custom close, scrollable content, sticky footer |
| Drawer | Slide-out panel from screen edge — use for mobile-friendly flows or supplementary detail | direction (top, right, bottom, left) |
| HoverCard | Popup showing preview/summary content **on hover** — not for actions | open/close delay, positioning |
| Popover | Portal popover for enriched content triggered by a button — use for inline forms or pickers | alignment, form integration |
| Sheet | Dialog that extends from screen edge — use for settings panels or secondary content | side (top, right, bottom, left) |
| Tooltip | Contextual label on hover/focus — use for icon-only buttons or keyboard shortcuts | side/align positioning, disabled button wrapper |

> **Choosing between overlays:** `AlertDialog` = destructive confirm only. `Dialog` = forms/detail, centered. `Sheet` = settings/panels, edge-anchored. `Drawer` = mobile gestures, edge-anchored. `Popover` = inline picker/form, stays near trigger. `HoverCard` = hover preview, no actions. `Tooltip` = label only, no interaction.

---

## Form Input

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Calendar | Date selection with month/year navigation | mode (single, range), captionLayout (dropdown, label), disabled dates |
| Checkbox | Binary toggle for selecting one or multiple items | checked, indeterminate, disabled, aria-invalid |
| Combobox | **Searchable** dropdown — use over Select when options are numerous or filterable | multiple selection, clear button, auto-highlight |
| Command | Keyboard-driven command palette for searching and triggering actions | groups, shortcuts, scrollable, dialog variant |
| DatePicker | Popover-based date selection with optional presets (a `Popover` + `Calendar` composition, no root component) | range picker, date of birth, time, natural language input |
| Input | Single-line text entry | type (text, email, file), disabled, invalid |
| InputGroup | Input with prefix/suffix addons (icons, buttons, text labels) | align (inline-start, inline-end, block-start, block-end) |
| InputOTP | One-time password input with copy/paste support | maxLength, pattern, separator, controlled value |
| Label | Accessible label for form controls | htmlFor, asChild |
| RadioGroup | Single-select mutually exclusive options | description, choice card, disabled items |
| NativeSelect | Styled native `<select>` — use for the browser's own picker (best on phones) or when performance matters | NativeSelectOption, NativeSelectOptGroup, disabled, aria-invalid |
| Select | Dropdown list selection — use when options are fixed and no search is needed | groups, scrollable, disabled items, align item with trigger |
| Slider | Range selection with draggable thumb(s) | range (multiple thumbs), vertical, controlled |
| Switch | Toggle for on/off binary states (settings, preferences) | checked, disabled, invalid |
| Textarea | Multi-line text input | disabled, invalid, button pairing |
| Toggle | Two-state button toggling on/off | variant (default, outline), size |
| ToggleGroup | Group of toggle buttons with single or multiple selection | type (single, multiple), variant (default, outline), size, orientation, spacing (default 2; `0` for connected items) |

> **Choosing between selects:** `Select` = fixed list, no search, custom styling. `NativeSelect` = native browser picker (mobile-optimised, lighter) with no custom animation. `Combobox` = searchable/filterable list. `Command` = keyboard-first action menu. `RadioGroup` = always-visible options (≤6 items).

---

## Form Structure

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Button | Primary interactive element for triggering actions | variant (default, outline, ghost, destructive, secondary, link), size, icon, spinner |
| ButtonGroup | Group related buttons with consistent styling | orientation (horizontal, vertical), separator, split |
| Field | Wrapper combining label, control, description, and error — use with any form library or standalone | FieldGroup, FieldSet/legend, FieldSeparator, orientation (vertical, horizontal, responsive), invalid state |

> **Forms:** there is no `Form` component. Build forms from `Field` and read `docs/instructions/forms-overview.md`, then the one for the library in use: `forms-react-hook-form.md`, `forms-tanstack-form.md`, `forms-formisch.md` or `forms-next.md` (Next.js server actions).

---

## Data Display

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Chart | Visualize quantitative data (bar, line, area charts) | ChartContainer, ChartTooltip, ChartLegend, themed colors |
| DataTable | Sortable, filterable, paginated table with row selection, built on TanStack Table v9 | feature-based `tableFeatures()` setup, sorting, filtering, pagination, visibility toggle, row selection |
| Item | Flexible list entry with media, title, description, and actions | variant (default, outline, muted), size (default, sm, xs), link |
| Table | Semantic HTML table for structured data without interactivity | caption, header, footer, actions, responsive |

> **Choosing between tables:** `Table` = static display. `DataTable` = interactive (sort/filter/select).

---

## Navigation

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Breadcrumb | Show hierarchical path and current location | link, separator, dropdown, ellipsis |
| ContextMenu | Right-click contextual actions for elements | submenus, checkboxes, radio items, shortcuts |
| DropdownMenu | Button-triggered action/selection menu | submenu, checkbox/radio items, icons, shortcuts |
| Menubar | Persistent horizontal menu bar (macOS-style app menus) | checkbox/radio items, submenus, separators |
| NavigationMenu | Horizontal site navigation with submenus | triggers, content, link styling |
| Pagination | Navigate between pages | simple variant, icons-only, ellipsis |
| Sidebar | Collapsible sidebar with header, content, footer, menu | collapsible (offcanvas, icon, none), variant (sidebar, floating, inset) |

---

## Feedback

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Alert | Static callout message requiring user attention (info, warning, error) | variant (default, destructive) |
| Badge | Label or tag for status, category, or count | variant (default, secondary, destructive, outline) |
| Empty | Placeholder when no data exists — always handle empty states | icon, avatar, background, button action, outline variant |
| Progress | Visual indicator of task completion | label, controlled value, animated |
| Skeleton | Loading placeholder for async content — prevents layout shift | avatar, card, text, table shapes |
| Sonner | Toast notification for transient feedback (success, error, info) | position, types (default, success, error, loading), description |
| Spinner | Animated loading indicator for in-progress operations | size variants, button/badge context |

> **Toasts:** use `Sonner`. `toast.md` only points to it.

> **Choosing between loading states:** `Skeleton` = content placeholder during load. `Spinner` = action in progress (button, inline). `Progress` = known completion percentage.

---

## Typography

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Kbd | Display keyboard key names for shortcuts | group, tooltip/button context |
| Direction | Provider that sets `ltr`/`rtl` text direction for the app; needed for right-to-left languages | DirectionProvider, `useDirection` hook |
| Typography | Text styling for headings, paragraphs, lists, quotes, code | h1–h4, paragraph, blockquote, list, code, lead, muted |

---

## Media

| Component | When to use | Key variants / features |
|:--|:--|:--|
| AspectRatio | Maintain consistent aspect ratio for images/videos | ratio prop (16/9, 4/3, 1/1, etc.) |
| Avatar | User profile image with automatic fallback | size (default, sm, lg), badge, group |
| Carousel | Horizontal/vertical scrolling collection of items | orientation, spacing, autoplay, plugins |

---

## Conversation & AI

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Attachment | File or image chip with name, metadata, upload state and actions — in composers, threads, upload lists | state (idle, uploading, processing, error, done), size (default, sm, xs), orientation, AttachmentMedia variant (icon, image), AttachmentTrigger, AttachmentGroup (scrolling row) |
| Bubble | The framed surface of one chat message (text, quoted reply, suggestion, reaction) | variant (default, secondary, muted, tinted, outline, ghost, destructive), align (start, end), BubbleGroup, BubbleReactions (side, align), asChild |
| CodeBlock | Code, terminal output, logs or diffs with copy button | header/title/actions, lineNumbers, startLine, wrap, line variant (default, added, removed, highlighted), size (default, sm), variant (default, destructive), optional Shiki highlighting |
| Marker | Inline status, system note or labeled divider between messages (dates, "Thinking...") | variant (default, border, separator), MarkerIcon, role="status", asChild |
| Message | One row in a conversation: avatar, header, footer actions around a Bubble | align (start, end), MessageGroup, MessageAvatar, MessageHeader, MessageFooter |
| MessageScroller | Scroll container for a chat transcript that anchors new turns, follows streaming and keeps place when history loads | scrollAnchor, autoScroll, defaultScrollPosition (start, end, last-anchor), scrollToMessage, MessageScrollerButton |
| Questionnaire | Multi-step set of questions answered one at a time, with progress and back/next | single/multiple choice, QuestionnaireInput (freeform), QuestionnaireSkip, shortcuts, controlled/resume, custom validation, Card/Dialog composition |
| Trace | List of steps an agent took (reasoning, tool calls, sources, plans), each expandable, linking or opening a dialog | TraceLine status (running, error, pending), TraceCollapsible, nested rows |

> **Choosing in a conversation:** `Message` = the row (avatar, name, actions); `Bubble` = the surface inside it; `Marker` = notes and dividers between turns; `Trace` = the agent's steps; `MessageScroller` = the scrolling frame around all of them. For a fixed multi-step form with a progress bar, `Questionnaire` fits where a long `Field` form would not.

---

## Utility

| Component | When to use | Key variants / features |
|:--|:--|:--|
| Separator | Visual divider between sections | orientation (horizontal, vertical), inline text |
