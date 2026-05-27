# quotebuilder

## Commands to get it running on mobile

```
flutter run -d web-server --web-port 8080
adb reverse tcp:8080 tcp:8080
```

---

## Google Apps Script Backend

The backend is a single Google Apps Script file deployed as a **Web App**. It acts as a REST API over two Google Sheets workbooks: a **Project Workbook** (live data) and a **Reference Workbook** (lookup data).

### Deployment steps

1. Paste the script into [script.google.com](https://script.google.com)
2. Click **Deploy > New Deployment**
3. Type: **Web App**
4. Execute as: **Me**
5. Who has access: **Anyone**
6. Click **Deploy** and copy the Web App URL
7. Paste the URL into `lib/services/sheets_service.dart` as `_baseUrl`

### Workbooks

| Constant | Purpose |
|---|---|
| `PROJECT_WORKBOOK_ID` | Stores projects and per-project line-item sheets |
| `REFERENCE_WORKBOOK_ID` | Stores lookup data: SystemTypes, Catalogue, Employees |

### Authentication

Every request must include the API key `BG_QUOTE_2026`.

- **GET requests** — pass as query param: `?key=BG_QUOTE_2026`
- **POST requests** — include `"key": "BG_QUOTE_2026"` in the JSON body

Requests with a missing or wrong key receive `{ "success": false, "error": "Unauthorized" }`.

---

### GET endpoints

All GET requests go to the Web App URL with `?key=...&action=...`.

#### `getProjects`
Returns all rows from the `Projects` sheet.

```
GET ?action=getProjects&key=BG_QUOTE_2026
```

Response:
```json
{ "success": true, "data": [{ "refNumber": "BG-QT-1000", "projectName": "...", "clientName": "...", "location": "...", "createdAt": "...", "worker": "..." }] }
```

#### `getSystemTypes`
Returns all rows from the `SystemTypes` sheet in the Reference Workbook.

```
GET ?action=getSystemTypes&key=BG_QUOTE_2026
```

#### `getCatalogue`
Returns all rows from the `Catalogue` sheet. The `rate` field is coerced to a float.

```
GET ?action=getCatalogue&key=BG_QUOTE_2026
```

#### `getLineItems`
Returns all line items for a project. Each row is parsed into typed fields.

```
GET ?action=getLineItems&key=BG_QUOTE_2026&refNumber=BG-QT-1000
```

Response fields per item: `id`, `systemType`, `category`, `productName`, `brand`, `unit`, `quantity`, `rate`, `amount`, `noteText`, `createdAt`.

#### `getSystems`
Returns the distinct system types present in a project sheet (derived from line items).

```
GET ?action=getSystems&key=BG_QUOTE_2026&refNumber=BG-QT-1000
```

#### `getEmployees`
Returns all employee names from the `Employees` sheet in the Reference Workbook.

```
GET ?action=getEmployees&key=BG_QUOTE_2026
```

Response: `{ "success": true, "data": [{ "Names": "John Doe" }, ...] }`

---

### POST endpoints

All POST requests send JSON with `"key"` and `"action"` at the top level.

#### `createProject`
Creates a new row in the `Projects` sheet and a new tab named after the generated ref number. Auto-generates the next `BG-QT-XXXX` ref number.

```json
{ "key": "BG_QUOTE_2026", "action": "createProject", "projectName": "Site A", "clientName": "ACME", "location": "Nairobi", "worker": "Jane" }
```

Response: `{ "success": true, "refNumber": "BG-QT-1001" }`

#### `addLineItem`
Appends a line item row to the project's tab. `amount` is computed as `quantity × rate`.

```json
{ "key": "BG_QUOTE_2026", "action": "addLineItem", "refNumber": "BG-QT-1000", "systemType": "Solar", "category": "Panels", "productName": "450W Mono", "brand": "Jinko", "unit": "pcs", "quantity": 10, "rate": 150, "noteText": "" }
```

Response: `{ "success": true, "id": "<uuid>" }`

#### `deleteLineItem`
Deletes a single line item row by its UUID.

```json
{ "key": "BG_QUOTE_2026", "action": "deleteLineItem", "refNumber": "BG-QT-1000", "itemId": "<uuid>" }
```

#### `addSystem`
Adds a placeholder row for a new system type (used to track which systems exist in a project before any items are added).

```json
{ "key": "BG_QUOTE_2026", "action": "addSystem", "refNumber": "BG-QT-1000", "systemType": "Solar" }
```

The placeholder row has an ID prefixed with `SYSTEM_PLACEHOLDER_` and empty product fields.

#### `removeSystem`
Deletes **all rows** (including line items and the placeholder) for a given system type within a project.

```json
{ "key": "BG_QUOTE_2026", "action": "removeSystem", "refNumber": "BG-QT-1000", "systemType": "Solar" }
```

Response: `{ "success": true, "deletedCount": 5 }`

#### `deleteProject`
Deletes the project's tab and removes its entry from the `Projects` index sheet.

```json
{ "key": "BG_QUOTE_2026", "action": "deleteProject", "refNumber": "BG-QT-1000" }
```

---

### Data layout

**Project Workbook**

| Sheet | Description |
|---|---|
| `Projects` | Index: one row per project (`refNumber`, `projectName`, `clientName`, `location`, `createdAt`, `worker`) |
| `BG-QT-XXXX` | One sheet per project; columns: `ID`, `System Type`, `Category`, `Product Name`, `Brand`, `Unit`, `Quantity`, `Rate`, `Amount`, `Note`, `Created At` |

**Reference Workbook**

| Sheet | Description |
|---|---|
| `SystemTypes` | Lookup list of system types |
| `Catalogue` | Product catalogue with `rate` column |
| `Employees` | Staff names (column header: `Names`) |

### Ref number format

`BG-QT-XXXX` — starting at `BG-QT-1000`, incremented by finding the highest existing number across the `Projects` sheet.

### Helper utilities

- `sheetToJSON(sheet)` — converts any sheet's data range to an array of objects keyed by the header row; skips fully empty rows.
- `generateRefNumber(projectsSheet)` — scans existing ref numbers and returns the next in sequence.
- `generateId()` — returns a UUID via `Utilities.getUuid()`.
