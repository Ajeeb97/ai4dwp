# Guide - Creating a Windows App in the Intune App Catalog

## Version Header

| Field | Value |
|-------|-------|
| Title | Guide - Creating a Windows App in the Intune App Catalog |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | initial Day 7 app catalog creation guide |

## 1. Purpose

This guide explains how to add a Windows application to the Intune app catalog before any phased rollout begins.

Worked example used throughout this document:
- Application: `FinBridge Connect v3.1`
- Package type: `.intunewin`
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection method: registry key
- Detection value: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`

## 2. Before You Start

1. Confirm you have Intune permissions to create and assign Windows applications. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: You can open the Intune admin center and access app creation options.

2. Confirm the `.intunewin` package file for `FinBridge Connect v3.1` is available in an approved location.
Expected result: You know the exact path to the package you will upload.

3. Confirm you have the install command, uninstall command, detection method, and minimum supported OS details before opening the wizard.
Expected result: You do not need to stop mid-process to gather missing values.

4. Confirm a small pilot or test group exists for initial assignment.
Expected result: A limited-scope group is ready for safe validation.

## 3. Where to Add an App in Intune

1. Open the Intune admin center. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: The tenant landing page is visible.

2. Navigate to `Apps` > `Windows` > `Windows apps` and select `Add`.
Expected result: The app creation wizard opens.

3. Verify the live labels in your own tenant before selecting anything.
Expected result: You confirm the menu wording matches the current tenant UI.

Note: UI labels commonly vary between tenant versions, portal refreshes, and tenant experiences. If the exact labels above differ, use the nearest equivalent Windows app creation path in your tenant rather than trusting the wording in this document.

4. When prompted for app type, choose the correct option for the package you are adding.
Expected result: You select an app type that matches the actual packaging method.

Use these app-type rules:
- Select the Windows LOB or Windows app option that supports `.intunewin` packages when you are uploading a packaged Windows line-of-business app like `FinBridge Connect v3.1`.
- Select Microsoft Store app when the app is sourced from the Microsoft Store integration, not from your own `.intunewin` package.
- Select Web link when you only need a launcher shortcut to a URL and are not deploying a native Windows installer.

5. Confirm again that the selected app type is the one intended for an `.intunewin` upload.
Expected result: The wizard shows fields for package upload, commands, requirements, detection, and assignments.

Note: Some tenants distinguish between legacy Windows LOB app choices and newer Windows app experiences. Always verify which option in your tenant explicitly supports `.intunewin` upload.

## 4. Create the LOB Windows App

1. Start the new app wizard for the `.intunewin`-capable Windows app type.
Expected result: The package upload step is visible.

2. Upload the `FinBridge Connect v3.1` `.intunewin` package.
Expected result: The wizard accepts the package and advances to app configuration.

3. Complete the `App information` section.
Expected result: Basic catalog information is populated.

Enter these values for the worked example:
- Name: `FinBridge Connect v3.1`
- Description: enter a clear support-facing description such as `Finance connectivity client version 3.1 for managed Windows 11 devices.`
- Publisher: enter the approved software publisher name for this product
- Version: `3.1`

4. Review the app name and version carefully before proceeding.
Expected result: The catalog entry is identifiable and version-specific.

5. Complete the `Program` section.
Expected result: Intune knows how to install and uninstall the app.

Enter these worked-example values:
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Install behavior: choose `System` context unless the application is explicitly designed for per-user installation

6. Choose install context deliberately.
Expected result: The install behavior matches how the application writes files and registry entries.

Use this decision rule:
- Choose `System` when the app installs for the device, writes under `HKLM`, installs for all users, or requires elevated access.
- Choose `User` only when the application is designed and approved for per-user install behavior.

7. Complete the `Requirements` section.
Expected result: Intune knows which devices are eligible.

At minimum, define:
- OS architecture: choose the supported architecture for the package, such as `64-bit` if that is the packaged build
- Minimum OS version: choose the minimum supported Windows 11 version approved for the application

8. Set requirements conservatively.
Expected result: Unsupported devices are filtered out before install attempts begin.

Note: Requirement labels and available OS selectors can vary by tenant version. Verify the live fields in your tenant and select the closest approved Windows 11 baseline for this package.

9. Complete the `Detection rules` section.
Expected result: Intune can determine whether the application installed successfully.

Detection rule options commonly include:
- Registry key or registry value
- MSI product code
- File or folder path

10. Configure registry detection for the worked example.
Expected result: Intune can detect `FinBridge Connect v3.1` using the approved registry value.

Use these values:
- Rule type: `Registry`
- Key path: `HKLM\SOFTWARE\FinBridge\Connect`
- Value name: `Version`
- Detection operator: use the operator in your tenant that checks the value equals the expected version string
- Expected value: `3.1`

11. Understand the other detection options before saving.
Expected result: You can explain why the selected method is correct.

Use these rules:
- Use registry detection when the installer writes a stable version value such as `HKLM\SOFTWARE\FinBridge\Connect\Version`.
- Use MSI product code when the installer is MSI-based and the product code uniquely identifies the installed version.
- Use file path detection when installation is best verified by the presence or version of a known executable or file.

12. Complete the `Return codes` section.
Expected result: Intune interprets installer exit results correctly.

Define which exit codes mean:
- Success
- Soft reboot required, if applicable
- Hard reboot required, if applicable
- Retry, if applicable
- Failure

13. Verify the package documentation or vendor guidance for return codes before accepting defaults.
Expected result: Success and failure states match the actual installer behavior.

Note: Return code labels may differ between tenants. Verify the live meanings shown in your tenant and do not assume the default mapping is correct for every package.

14. Review the summary page and create the app.
Expected result: The app is added to the Intune app catalog.

## 5. Assignment Basics

1. Open the new app entry after creation.
Expected result: The app overview page is visible.

2. Go to the `Assignments` section.
Expected result: You can define who receives the app.

3. Understand the three common assignment types before targeting users or devices.
Expected result: You can choose the correct rollout behavior.

Use these definitions:
- `Required`: Intune installs the app automatically for the targeted group.
- `Available`: The app is offered for self-service install, typically through Company Portal.
- `Uninstall`: Intune removes the app from the targeted group.

4. Assign the app to a small pilot or test group first.
Expected result: Only a limited number of devices receive the initial deployment.

5. Do not assign a brand-new app directly to the full `10,000`-device fleet.
Expected result: Risk is contained while install behavior, detection, and support impact are validated.

6. Use this pilot-first reasoning:
- A small test group confirms the package uploads correctly.
- A pilot verifies the install and uninstall commands actually work on real endpoints.
- A pilot confirms the detection rule reports `Installed` only when the correct version is present.
- A pilot limits blast radius if the package, requirements, or return codes are wrong.

7. For `FinBridge Connect v3.1`, begin with a limited validation group before any Finance or enterprise rollout.
Expected result: The app is proven in production-like conditions before broader assignment.

## 6. Verification Steps

1. Return to the app list in `Apps` > `Windows` > `Windows apps`.
Expected result: `FinBridge Connect v3.1` appears in the catalog.

2. Open the app entry and review the Overview, Properties, and Assignments information.
Expected result: Name, version, commands, detection rule, and pilot assignment appear correctly.

3. Verify the app is visible with the expected version in the catalog.
Expected result: The catalog entry is easy to distinguish from any older version such as `v3.0`.

4. On a test device that is a member of the pilot assignment, sync Intune policy if needed.
Expected result: The device checks in and begins evaluating the assignment.

5. In Intune, open the app's device install status or user install status view.
Expected result: Per-device or per-user deployment states are visible.

Note: Status page labels commonly vary between tenants. Verify the live reporting blade names in your own tenant before relying on the wording in this guide.

6. Check the assigned test device status.
Expected result: The device eventually reports one of the standard deployment states.

Interpret the common states as follows:
- `Installed`: Intune believes the app installed successfully and the detection rule matched.
- `Failed`: The install did not complete successfully, or the detection rule did not confirm the app after install.
- `Not applicable`: The device did not meet the app requirements or was otherwise not eligible for the assignment.

7. If the device shows `Installed`, verify locally that `FinBridge Connect v3.1` launches and that the registry value exists.
Expected result: Catalog reporting matches the real device state.

8. If the device shows `Failed`, review command syntax, detection rule accuracy, requirement filters, and return code mapping.
Expected result: You can identify the likely cause before widening the deployment.

9. If the device shows `Not applicable`, review OS architecture, OS version requirement, and assignment targeting.
Expected result: You can explain why the device was filtered out.

10. Do not begin phased rollout until app creation and pilot verification are both complete.
Expected result: The app catalog entry is ready for controlled deployment.

## 7. Final Checks Before Phased Rollout

1. Confirm the app exists in the catalog with correct metadata.
2. Confirm the install and uninstall commands were tested.
3. Confirm the detection rule accurately identifies `Version = 3.1` under `HKLM\SOFTWARE\FinBridge\Connect`.
4. Confirm return codes reflect actual installer behavior.
5. Confirm the pilot group assignment is healthy before any broad deployment.

## 8. Notes

- Always verify live Intune UI labels against your tenant because Microsoft admin portals change over time.
- Prefer device-context installation for applications detected in `HKLM` unless the package owner specifies otherwise.
- Treat catalog creation as a technical control point: a poor detection rule or wrong return code can undermine every later rollout phase.