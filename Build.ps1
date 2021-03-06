﻿#Requires -Version 5
[CmdletBinding(DefaultParameterSetName='Build')]
param (
    [parameter(Position=0, ParameterSetName='Build')]
    [switch]$BuildModule,
    [parameter(Position=1, ParameterSetName='Build')]
    [switch]$UpdateRelease,
    [parameter(Position=2, ParameterSetName='Build')]
    [switch]$UploadPSGallery,
    [parameter(Position=3, ParameterSetName='Build')]
    [switch]$GitCheckin,
    [parameter(Position=4, ParameterSetName='Build')]
    [switch]$GitPush,
    [parameter(Position=5, ParameterSetName='Build')]
    [switch]$InstallAndTestModule,
    [parameter(Position=6, ParameterSetName='Build')]
    [version]$NewVersion,
    [parameter(Position=7, ParameterSetName='CBH')]
    [switch]$InsertCBH,
    [parameter(Position=8, ParameterSetName='Help')]
    [switch]$Help
)

$HelpContents = @'
This is a wrapper script for invoke-build and a set of build tasks in the included .\OhMyPsh.build.ps1 file.
As this is a wrapper script almost all parameters are simple switches. This help output will
cover what each of these switches will accomplish.

    Help - This help output.

    InsertCBH - So far there is the only helper task that doesn't really do anything as part of a build
    process. When you run with this switch all the function scripts in .\src\public will be inspected
    for comment based help (CBH) within its function scriptblock. If one is not readily found then
    a template CBH will be added in a copy of the script which will be saved in the scratch directory
    (usually located in .\temp\src\public). This switch is stand-alone and will not work with other
    switches in this script.

Use one or more of the following switches with this script to kick off some of the most common
build tasks for your module project. All of the following switches can be stringed together. They
are listed in the order they would be processed in were they all to be used at once.

    UpdateRelease - If you have manually updated the version.txt file then this will trigger the build
    scripts to begin building and releasing the new version. You will be prompted for release ReleaseNotes
    for the module manifest file. You can use this in conjunction with the -NewVersion parameter
    to update the version.txt file as well.

    NewVersion - Can be used with the -UpdateRelease parameter to start a new version of the
    module for release.

    BuildModule - This is the default action if no parameters are passed to this script. This kicks off
    the build process as defined by the .\build\.buildenvironment.ps1 configuration script. If all
    goes well a completed and fully packaged build of your project will be created in the following
    locations:
        .\release\<version> - Every new version you release will be kept in its own directory
        .\release\<modulename>-<version>.zip - Every version will have an assoicated zip created
        .\release\<modulename> - The current release will always be in a folder with the module name
        .\release\<modulename>.zip - The current release in zip format for easy automated installation

    InstallAndTestModule - Attempt to install a finished build of the module from
    .\release\<modulename>. After installing the module we then attempt to load it to ensure it works.

    UploadPSGallery - Upload a release to the PSGallery for others to install with install-module
    (PowerShell 5+ only). NOTE: This will fail outright if you don't have appropriate
    LicenseURI, IconURI, and ReleaseNotes entries uncommented and set in your module manifest
    file.

    GitCheckin - Not finished with this yet, sorry.

    GitPush - Not finished with this yet, sorry.
'@
function PrerequisitesLoaded {
    # Install InvokeBuild module if it doesn't already exist
    try {
        if ((get-module InvokeBuild -ListAvailable) -eq $null) {
            Write-Host "Attempting to install the InvokeBuild module..."
            $null = Install-Module InvokeBuild
        }
        if (get-module InvokeBuild -ListAvailable) {
            Write-Host -NoNewLine "Importing InvokeBuild module"
            Import-Module InvokeBuild -Force
            Write-Host -ForegroundColor Green '...Loaded!'
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function CleanUp {
    try {
        Write-Output ''
        Write-Output 'Attempting to clean up the session (loaded modules and such)...'
        Invoke-Build -File '.\OhMyPsh.build.ps1' -Task BuildSessionCleanup
        Remove-Module InvokeBuild
    }
    catch {}
}

switch ($psCmdlet.ParameterSetName) {
    'Help' {
        Write-Output $HelpContents
    }
    'CBH' {
        if (-not (PrerequisitesLoaded)) {
            throw 'Unable to load InvokeBuild!'
        }

        if ($InsertCBH) {
            try {
                Invoke-Build -File '.\OhMyPsh.build.ps1' -Task InsertMissingCBH
            }
            catch {
                throw
            }
        }

        CleanUp
    }
    'Build' {
        if (-not (PrerequisitesLoaded)) {
            throw 'Unable to load InvokeBuild!'
        }

        # Update your release version?
        if ($UpdateRelease) {
            if ($NewVersion -ne $null) {
                $NewVersion.ToString() | Out-File -FilePath .\version.txt -Force
            }

            try {
                Invoke-Build -File '.\OhMyPsh.build.ps1' -Task UpdateVersion
            }
            catch {
                throw
            }
        }

        # If no parameters were specified or the build action was manually specified then kick off a standard build
        if (($psboundparameters.count -eq 0) -or ($BuildModule))  {
            try {
                Invoke-Build
            }
            catch {
                Write-Output 'Build Failed with the following error:'
                Write-Output $_
            }
        }

        # Install and test the module?
        if ($InstallAndTestModule) {
            try {
                Invoke-Build -File '.\OhMyPsh.build.ps1' -Task InstallAndTestModule
            }
            catch {
                Write-Output 'Install and test of module failed:'
                Write-Output $_
            }
        }

        # Upload to gallery?
        if ($UploadPSGallery) {
            try {
                Invoke-Build -File '.\OhMyPsh.build.ps1' -Task PublishPSGallery
            }
            catch {
                throw 'Unable to upload project to the PowerShell Gallery!'
            }
        }

        # Not implemented yet
        if ($GitCheckin) {
            # Finish me
        }

        # Not implemented yet
        if ($GitPush) {
            # Finish me
        }

        CleanUp
    }
}
