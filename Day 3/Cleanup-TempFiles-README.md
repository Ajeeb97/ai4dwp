# Cleanup-TempFiles.ps1 — DWP Endpoint Temp Cleanup Utility

## Overview

A **production-ready**, read-safe PowerShell 5.1 script that removes temporary files
from standard Windows temp locations. Every deletion is preceded by a backup so the
operation is fully reversible. A full audit log is written on every run.

---

## Target Locations

| Location | Variable |
|---|---|
| Current user temp | `%TEMP%` / `%TMP%` |
| System-wide temp | `%SystemRoot%\Temp` |

---

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-DryRun` | Switch | off | Preview mode — lists files that *would* be deleted; makes **no changes**. |
| `-OlderThanDays` | Int | `0` | Only target files whose **LastWriteTime** is older than this many days. `0` = all files. |
| `-Rollback` | Switch | off | Restores files from the most recent rollback archive. Cannot be combined with cleanup parameters. |
| `-RollbackArchivePath` | String | *(auto)* | Path to a specific rollback archive folder. Used with `-Rollback` to override auto-detection. |

---

## Usage Examples

### 1 — Preview what would be deleted (no changes)
```powershell
.\Cleanup-TempFiles.ps1 -DryRun
```

### 2 — Delete all temp files (all ages)
```powershell
.\Cleanup-TempFiles.ps1
```

### 3 — Delete only files older than 30 days
```powershell
.\Cleanup-TempFiles.ps1 -OlderThanDays 30
```

### 4 — Preview files older than 7 days without deleting
```powershell
.\Cleanup-TempFiles.ps1 -OlderThanDays 7 -DryRun
```

### 5 — Roll back the most recent cleanup run
```powershell
.\Cleanup-TempFiles.ps1 -Rollback
```

### 6 — Roll back a specific earlier run
```powershell
.\Cleanup-TempFiles.ps1 -Rollback -RollbackArchivePath ".\CleanupRollback\20260810_143000"
```

---

## Output Files

All output is written next to the script in automatically created sub-folders:

```
Day 3\
├── Cleanup-TempFiles.ps1
├── CleanupLogs\
│   └── cleanup_20260810_143000.log     ← one log per run
└── CleanupRollback\
    └── 20260810_143000\                ← one archive per run
        ├── manifest.csv                ← maps backup paths → original paths
        └── <mirrored directory tree>   ← backed-up files
```

### Log file format

Each line follows the pattern:
```
[yyyy-MM-dd HH:mm:ss] [LEVEL] Message
```
Levels: `INFO` | `WARN` | `ERROR` | `SUCCESS`

### manifest.csv columns

| Column | Description |
|---|---|
| `OriginalPath` | Full path where the file lived before deletion |
| `BackupPath` | Full path to the copy stored in the archive |
| `SizeBytes` | File size in bytes at the time of backup |
| `LastWriteTime` | File's last-modified timestamp |

---

## Rollback

Before any file is deleted the script:

1. Creates a timestamped folder under `CleanupRollback\`.
2. Copies every candidate file into that folder, preserving the relative directory structure.
3. Writes `manifest.csv` mapping each backup copy back to its original path.

Running with `-Rollback` reads the manifest of the most recent archive and copies each file
back to its original location. If the original file is already present the entry is skipped
(**idempotent**). A specific archive can be targeted with `-RollbackArchivePath`.

> **Note:** The rollback archive is **not** automatically cleaned up. Remove old archives
> from `CleanupRollback\` manually once you are satisfied with a cleanup run.

---

## Safety Features

| Feature | Detail |
|---|---|
| **Dry-run** | `-DryRun` exits before touching anything |
| **Age filter** | `-OlderThanDays` prevents accidental deletion of recent files |
| **Pre-delete backup** | Full rollback archive created before first deletion |
| **Per-file try/catch** | A locked or inaccessible file is logged and skipped; the run continues |
| **Locked-file handling** | `IOException` is caught separately and flagged as `LOCKED` in the log |
| **Idempotency** | Files already absent are silently skipped; re-running produces the same end state |
| **Audit log** | Timestamped log written for every run regardless of mode |

---

## Permissions

- Run as the **logged-on user** to clean `%TEMP%` / `%TMP%`.
- Run as **Administrator** to also clean `%SystemRoot%\Temp`.
- The script will log a warning and skip any path it cannot access rather than stopping.

---

## Verify Before Running (DWP Checklist)

- [ ] Confirm the three target paths are approved for automated cleanup under your endpoint policy.
- [ ] Confirm the service account / user has write access to the script folder (needed for logs and archive).
- [ ] Run with `-DryRun` first and review the output before executing a live deletion.
- [ ] Agree a rollback archive retention period with your team and schedule manual purges of `CleanupRollback\`.
- [ ] Test on a non-production endpoint before wide deployment.
