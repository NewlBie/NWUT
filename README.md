# NWUT - Newlbie Windows Update Troubleshooter

NWUT is a batch script designed to diagnose and fix a wide range of Windows Update-related issues such as:

- Stuck updates
- Driver malfunctions
- Boot failures
- Corrupted BITS queues
- Misconfigured services

Developed by Newlbie, this script automates critical system repairs while ensuring safety through backups and reversion options.

---

## Features

- Stops and restarts critical services: BITS, Windows Update, AppID, Cryptographic
- Clears qmgr*.dat and qmgr*.db files from both legacy and modern BITS queue locations
- Backs up and renames SoftwareDistribution and catroot2 folders with timestamped versions
- Resets BITS and Windows Update service security descriptors to their default state
- Re-registers essential DLLs related to Windows Update functionality
- Resets Winsock and WinHTTP proxy settings
- Optionally runs:
  - System File Checker (sfc /scannow)
  - DISM Health Check (/Online /Cleanup-Image /RestoreHealth)
- Guides users to perform a non-destructive Windows ISO repair if problems persist
- Includes a revert option to restore backups of all modified system components
- Logs all operations to a timestamped file for later review

---

## Requirements

- Operating System: Windows 10 or later
- Permissions: Must be run with administrative privileges
- Internet Connection: Required for DISM operations and ISO download
- Recommendation: Manually back up critical data, although the script also makes backups automatically

---

## Installation

Clone or download the repository:

    git clone https://github.com/YourGitHubUsername/NWUT.git

Change into the directory:

    cd NWUT

---

## Usage

1. Right-click `NWUT.cmd` and select "Run as administrator"
2. Or open an elevated Command Prompt and run:

       NWUT.cmd

3. Follow the on-screen prompts:
   - Confirm script execution (Y/N)
   - Indicate the nature of the problem (e.g., update stuck at 8%, boot loop)
   - Choose whether to attempt a Windows ISO repair installation
   - Optionally revert changes if issues occur after running the script

4. After completion, review:

   - Log file:  
     %TEMP%\windows_update_fix_log_[TIMESTAMP].txt

   - Backup directories:  
     %SystemRoot%\SoftwareDistribution_[TIMESTAMP].bak  
     %SystemRoot%\System32\catroot2_[TIMESTAMP].bak  
     %TEMP%\service_sds_backup_[TIMESTAMP].txt

---

## Troubleshooting

- If the script fails to execute, make sure you are running it as an administrator.
- Review the log file for any errors encountered during execution.
- If the update still fails, use the script's ISO repair option to download the official Windows installation image and run a repair install (select "Keep personal files and apps").
- Use the revert option if your system becomes unstable after changes.

---

## Contributing

Contributions are welcome.

To contribute:

1. Fork the repository
2. Create a new branch:

       git checkout -b feature/YourFeature

3. Make your changes and commit:

       git commit -m "Add YourFeature"

4. Push the branch:

       git push origin feature/YourFeature

5. Open a pull request

All contributions should be compatible with Windows 10/11 and include proper error handling and logging.

---

## Author

Newlbie  
GitHub: https://github.com/NewlBie
