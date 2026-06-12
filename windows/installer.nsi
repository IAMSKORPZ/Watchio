; NSIS Installer Script for BingieTV
; This script creates a Windows installer that installs the application
; to Program Files and creates shortcuts.

;--------------------------------
; Includes

!define APP_EXE "BingieTV.exe"

!include "MUI2.nsh"
!include "FileFunc.nsh"

;--------------------------------
; General

; Name and file
Name "BingieTV"
OutFile "BingieTV-windows-setup.exe"
Unicode True

; Default installation folder
InstallDir "$PROGRAMFILES64\BingieTV"

; Get installation folder from registry if available
InstallDirRegKey HKCU "Software\BingieTV" ""

; Request application privileges for Windows Vista/7/8/10/11
RequestExecutionLevel admin

; Version information
VIProductVersion "0.0.1.0"
VIAddVersionKey "ProductName" "Watchio IPTV"
VIAddVersionKey "Comments" "A modern IPTV player application"
VIAddVersionKey "CompanyName" "Watchio IPTV"
VIAddVersionKey "LegalCopyright" "Copyright © 2026"
VIAddVersionKey "FileDescription" "Watchio IPTV Installer"
VIAddVersionKey "FileVersion" "0.0.1.0"
VIAddVersionKey "ProductVersion" "0.0.1.0"

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "BingieTV" SecMain

  SectionIn RO
  
  ; Set output path to the installation directory

  SetOutPath "$INSTDIR"
  
  ; Copy all files from the build directory
  ; Note: In GitHub Actions, we're in windows/ directory, so we go up one level
  File /r /x "*.pdb" /x "BingieTV-windows-*" "..\build\windows\x64\runner\Release\*"
  
  ; Store installation folder
  WriteRegStr HKCU "Software\BingieTV" "" $INSTDIR
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                   "DisplayName" "BingieTV"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
  "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                   "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                 "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                   "Publisher" "BingieTV"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                   "DisplayVersion" "1.3.0"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                     "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV" \
                     "NoRepair" 1

SectionEnd

Section "Start Menu Shortcuts" SecStartMenu

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\BingieTV"
  CreateShortcut "$SMPROGRAMS\BingieTV\BingieTV.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut "$SMPROGRAMS\BingieTV\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Desktop Shortcut" SecDesktop

  CreateShortcut "$DESKTOP\BingieTV.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0


SectionEnd

;--------------------------------
; Descriptions

; Language strings
LangString DESC_SecMain ${LANG_ENGLISH} "Install BingieTV application files."
LangString DESC_SecStartMenu ${LANG_ENGLISH} "Create Start Menu shortcuts."
LangString DESC_SecDesktop ${LANG_ENGLISH} "Create a desktop shortcut."

; Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_SecStartMenu)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Section

Section "Uninstall"

  ; Remove files and uninstaller
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\BingieTV\BingieTV.lnk"
  Delete "$SMPROGRAMS\BingieTV\Uninstall.lnk"
  RMDir "$SMPROGRAMS\BingieTV"
  Delete "$DESKTOP\BingieTV.lnk"
  
  ; Remove registry keys
  DeleteRegKey /ifempty HKCU "Software\BingieTV"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BingieTV"

SectionEnd

