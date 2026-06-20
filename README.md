# QuoteBuilder — Baker & Grey

A Flutter web application for generating, managing, and sharing professional quotations for AV/IT system integration projects. Built for field workers and sales teams to build accurate Bills of Quantities on the go, backed entirely by Google Sheets.

**Live app:** `https://j34n-v4lj34n.github.io/QuoteBuilder/`

---

## Features

### Project Management
- Create projects with client name, site location, assigned worker, industry, and tier (Value / Premium)
- Edit project details at any time
- Delete projects (removes all data from the backend)
- Search and filter projects from the home screen

### Systems & Line Items
- Add one or more **system types** to a project (e.g. CCTV, Access Control, Fiber)
- Browse the product **catalogue** filtered by system type and project tier
- Add line items with quantity, area assignment, and voice or text notes
- Edit quantity, notes, and area on any line item
- Swipe to delete or use the options menu on any line item
- Running total bar updates in real time as items are added

### Areas
- Define named areas for a project (e.g. Floor 1, Reception, Server Room)
- Assign line items to specific areas
- View all items grouped by area in the **Areas** tab of the project detail screen
- Edit and delete area-specific items directly from the area view

### Quote Summary & Sharing
- Full Bill of Quantities view grouped by system type
- Add an **Installation Charge** (Baker & Grey service item) with a user-defined rate — editable and deletable from the summary screen
- Export and share the quote as:
  - **PDF** — formatted A4 document with letterhead, BOQ table, and GST breakdown
  - **PNG** — shareable image suitable for WhatsApp, email, or Drive

### Voice Notes
- Tap the microphone button on any line item to dictate a note
- Supports **English** and **Malayalam** transcription
- Transcribed text appends to any existing note

### Catalogue
- Products organised by category, each category stored as a separate sheet in the Catalogue workbook
- Lazy loading — only the selected category is fetched when adding an item
- Tier-aware product display: **Recommended** products matching the project tier shown first, others listed below
- ID auto-generation in the Catalogue workbook via Google Apps Script trigger

### Desktop & Responsive Layout
- Optimised for both mobile browsers and desktop
- Two-column project grid on wide screens
- All bottom sheets constrained to a readable max width

---

## How to Use

### First Launch
1. Open the app — you will be prompted to enter your name. This is used as the **Worker** field on all items you create.
2. Your name is saved locally and can be changed from the hamburger menu → edit worker name.

### Creating a Project
1. Tap **+ New Project** on the home screen
2. Fill in Project Name, Client Name, Location, Worker, Industry, and Tier
3. Tap **Create** — the project is created in the backend immediately

### Adding Systems and Items
1. Open a project → tap **Add System** to add system types (e.g. CCTV, Fiber)
2. Tap a system to open its detail screen
3. Tap **Add Item** → select a category → select a product → set quantity → optionally assign an area or add a note → tap **Save Item**

### Managing Areas
1. Open a project → go to the **Areas** tab
2. Tap **Manage Areas** to add, rename, or delete area names
3. Items assigned to each area are listed there and can be edited or deleted inline

### Generating a Quote
1. From a project screen, tap **View Quote** (or the quote icon in the app bar)
2. Review the full BOQ — tap **Add Installation Charge** if applicable, enter the rate
3. Tap **Share Quote** → choose **PDF** or **Image**

### Google Sheets Links
Tap the **≡ hamburger menu** on the home screen to open quick links to all three backend workbooks directly in the browser.

---

## Google Sheets Backend

The backend is a Google Apps Script web app deployed over three Google Sheets workbooks. No server or database is required.

### Workbooks

| Workbook | Link | Purpose |
|---|---|---|
| **Project Workbook** | [Open](https://docs.google.com/spreadsheets/d/1zZQOmWe02oF7awuRkqgsMsJU1GwgcINyaXBNfUADkS4/edit) | All project data and line items |
| **Reference Workbook** | [Open](https://docs.google.com/spreadsheets/d/1tdLzOTnnXIVVKrgEgQtS5YVnsZT3Sepo1E4LcKuRR6Y/edit) | System types, employees lookup |
| **Catalogue Workbook** | [Open](https://docs.google.com/spreadsheets/d/1CnwJR9CvDv2TV47dAPGLx-hwZUcEsnXgYYGHVaRB7ts/edit) | Product catalogue, one sheet per category |

### Project Workbook — Sheet Structure

| Sheet | Columns | Description |
|---|---|---|
| `Projects` | `Ref. Number`, `Project Name`, `Client Name`, `Location`, `Created At`, `Worker`, `Industry`, `Tier`, `Areas` | Index of all projects. `Areas` is a comma-separated list of area names. |
| `BG-QT-XXXX` | `ID`, `System Type`, `Category`, `Product Name`, `Brand`, `Unit`, `Quantity`, `Rate`, `Amount`, `Note`, `Created At`, `Worker`, `Area` | One sheet per project named after its ref number. Rows prefixed `SYSTEM_PLACEHOLDER_` mark systems with no items yet. |

### Reference Workbook — Sheet Structure

| Sheet | Columns | Description |
|---|---|---|
| `SystemTypes` | `System Type`, `Tags`, `Industry` | Lookup list of system types. `Tags` is comma-separated category names from the Catalogue used to pre-filter products. `Industry` is comma-separated industries this system type applies to. |
| `Employees` | `Names` | Staff list used to populate the worker picker. |

### Catalogue Workbook — Sheet Structure

One sheet tab per product category (e.g. `Camera`, `Fiber`, `Access Control`).

| Column | Description |
|---|---|
| `ID` | Auto-generated category prefix code, e.g. `CAM-001` |
| `Product Name` | Display name |
| `Brand` | Manufacturer |
| `Unit` | Unit of measure (e.g. `nos`, `mtr`, `job`) |
| `Rate` | Unit price in INR |
| `Tier` | Leave blank for all tiers; set to `Premium` or `Value` to restrict visibility |

**ID auto-generation:** An installable Apps Script trigger (`onCatalogueEdit`) fires whenever a row gets a Product Name — it stamps a unique ID derived from the category prefix (e.g. `AC-001` for Access Control). A `QuoteBuilder` menu in the Catalogue workbook provides **Fill Missing IDs** and **Validate Catalogue** utilities.

### Apps Script Deployment

Source: `appscript_deployment.txt` in the repo root. This single file contains both the web app (Part 1) and the Catalogue workbook tools (Part 2).

**Deploying the web app:**
1. Open [script.google.com](https://script.google.com) → paste the full contents of `appscript_deployment.txt`
2. **Deploy → New Deployment → Web App**
   - Execute as: **Me**
   - Who has access: **Anyone**
3. Copy the Web App URL → paste into `lib/services/sheets_service.dart` as `_baseUrl`
4. On subsequent changes: **Deploy → Manage Deployments → Edit → New version → Deploy** (URL stays the same)

**Installing Catalogue triggers (run once):**
1. In the Apps Script editor, select `installCatalogueTriggers` in the function dropdown
2. Click **▶ Run** and accept the permissions popup
3. Triggers for `onCatalogueEdit`, `onCatalogueChange`, and `onCatalogueOpen` are installed automatically

### Authentication

Every request must pass `key=BG_QUOTE_2026`. GET requests send it as a query param; POST requests include it in the JSON body.

---

## Deployment (GitHub Pages)

The app is automatically deployed to GitHub Pages on every push to `main` via `.github/workflows/deploy.yml`.

**First-time setup:**
1. Go to **GitHub repo → Settings → Pages**
2. Set Source to **Deploy from a branch**, branch = `gh-pages`, folder = `/ (root)`
3. Save — the app will be live after the next push

The `--base-href /QuoteBuilder/` flag in the workflow matches the repository name and must stay in sync if the repo is renamed.

**Local development:**
```bash
flutter pub get
flutter run -d chrome
```

**Run on a physical device via USB:**
```bash
flutter run -d web-server --web-port 8080
adb reverse tcp:8080 tcp:8080
# then open http://localhost:8080 on the device
```

---

## For Developers

### Tech Stack
- **Flutter Web** — UI framework
- **Riverpod** — state management (`flutter_riverpod`)
- **go_router** — declarative navigation
- **Google Apps Script** — backend / REST API over Google Sheets
- **pdf** package — PDF generation
- **speech_to_text** — voice note transcription

### Codebase Structure

```
lib/
├── main.dart                        # App entry point, ProviderScope
├── router.dart                      # go_router route definitions
├── theme.dart                       # AppColors, shared text styles
├── responsive.dart                  # kDesktopBreakpoint, kMaxContentWidth, kSheetConstraints
├── utils.dart                       # formatINR, SheetCard widget
│
├── models/
│   ├── project.dart                 # Project data class (id, name, client, areas, tier, etc.)
│   ├── line_item.dart               # LineItem data class with amount getter and copyWith
│   ├── product.dart                 # Product data class (catalogue entry)
│   └── project_system.dart          # ProjectSystem data class (systemType per project)
│
├── services/
│   └── sheets_service.dart          # All HTTP calls to the Apps Script web app (GET + POST)
│
├── providers/
│   ├── sheets_service_provider.dart # Singleton SheetsService provider
│   ├── projects_provider.dart       # AsyncNotifier for project list CRUD
│   ├── line_items_provider.dart     # AsyncNotifier for line items — load, add, update, delete
│   ├── systems_provider.dart        # AsyncNotifier for systems per project
│   ├── catalogue_provider.dart      # catalogueProvider (full, fallback), catalogueByCategoryProvider (lazy per-category), tieredProductsByCategoryProvider
│   ├── system_types_provider.dart   # systemTypeTagsProvider, systemIndustriesProvider
│   ├── employees_provider.dart      # FutureProvider for employee name list
│   └── worker_provider.dart         # StateProvider for current worker name (persisted locally)
│
├── screens/
│   ├── projects_list_screen.dart    # Home screen — project grid, search, new project sheet, hamburger menu
│   ├── project_detail_screen.dart   # Project detail — Systems tab, Areas tab, project info card
│   ├── system_detail_screen.dart    # Line items for one system type — add, edit, delete
│   ├── add_line_item_screen.dart    # Add item flow — category → product → quantity → area → note
│   └── quote_summary_screen.dart    # BOQ view, installation charge, share as PDF/PNG
│
├── widgets/
│   ├── line_item_card.dart          # Swipeable card used in system detail screen
│   ├── edit_line_item_sheet.dart    # Bottom sheet for editing quantity/note/area; exports SheetCard
│   ├── add_system_sheet.dart        # Bottom sheet for adding systems to a project
│   ├── running_total_bar.dart       # Sticky bottom bar showing subtotal
│   ├── section_header.dart          # Grey section label used inside bottom sheets
│   ├── voice_note_button.dart       # Mic button + language toggle for STT
│   └── loading_widgets.dart         # Shared loading/skeleton widgets
│
└── utils/
    ├── quote_generator.dart         # PDF (generateQuotePdf) and PNG (captureQuoteAsPng) generation
    ├── speech_recognition.dart      # Wrapper around speech_to_text package
    ├── system_icons.dart            # Maps system type names to Material icons
    └── web_share.dart               # JS interop: openUrl (window.open) and shareQuoteFile (_qbShare)
```

### Key Patterns

**State management** — all server data is held in Riverpod `AsyncNotifier` providers. Optimistic local state updates happen immediately after a successful API call; the server is not re-fetched unless explicitly triggered.

**Navigation** — `go_router` with named routes. Deep links follow the pattern `/project/:id/system/:type/add-item`.

**Catalogue lazy loading** — `catalogueByCategoryProvider` is a `FutureProvider.family` that fetches one sheet at a time. It is only triggered when the user selects a category in the Add Item screen, keeping startup fast.

**Responsive layout** — all screen bodies are wrapped in `Align(topCenter) + ConstrainedBox(maxWidth: kMaxContentWidth)`. Bottom sheets use `constraints: kSheetConstraints`. Desktop breakpoint is 600 px; above that the project list renders as a two-column grid.

**Quote generation** — `quote_generator.dart` contains both a `pw` (pdf package) document builder and a Flutter `QuoteDocumentWidget` rendered off-screen for PNG capture. Both share the same data model and layout logic.

**Installation charges** — service items (`systemType: 'Service'`, `category: 'Installation'`) are regular `LineItem`s stored in the project sheet. They are excluded from the system-type loop and rendered in a dedicated **SERVICE** section in both the on-screen BOQ and the exported documents.

**Web sharing** — `web_share.dart` uses `dart:js_interop` to call `window._qbShare`, a small JavaScript helper injected into `web/index.html` that invokes the Web Share API on mobile or triggers a download on desktop.

### Adding a New System Type

1. Add a row to the `SystemTypes` sheet in the Reference Workbook with the system name, relevant `Tags` (comma-separated Catalogue category names), and optional `Industry` values
2. An icon for the new type can be mapped in `lib/utils/system_icons.dart`

### Adding Products to the Catalogue

1. Open the Catalogue Workbook and navigate to the relevant category sheet (or create a new sheet for a new category)
2. Add a row — fill in Product Name, Brand, Unit, Rate, and optionally Tier
3. The ID is auto-stamped by the `onCatalogueEdit` Apps Script trigger as soon as the Product Name is entered
4. Run **QuoteBuilder → Validate Catalogue** to check for missing fields or broken SystemTypes tag references
