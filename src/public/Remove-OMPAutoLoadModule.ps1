Function Remove-OMPAutoLoadModule {
    <#
    .SYNOPSIS
        Removes a module to be autoloaded when OMP starts up.
    .DESCRIPTION
        Removes a module to be autoloaded when OMP starts up.
    .PARAMETER Name
        Name of the module
    .PARAMETER NoProfileUpdate
        Skip updating the profile
    .EXAMPLE
        PS> Remove-OMPAutoLoadModule -Name 'posh-git'

        Removes posh-git from the list of modules that will be loaded when OhMyPsh starts.

    .NOTES
        Author: Zachary Loeber



        Version History
        1.0.0 - Initial release
    #>
    [CmdletBinding()]
	param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 1)]
        [switch]$NoProfileUpdate
    )
    try {
        Remove-OMPModule -Name $Name
        $Script:OMPProfile['AutoLoadModules'] = @($Script:OMPProfile['AutoLoadModules'] | Where-Object {$_ -ne $Name} | Sort-Object -Unique)
        if (-not $NoProfileUpdate) {
            Export-OMPProfile
        }
    }
    catch {
        throw "Unable to add module $($Name)"
    }
}