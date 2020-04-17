function Install-WindowsPatches {
    <#
.Synopsis
    Install-WindowsPatches is a wrapper/helper for Get-WindowsUpdate from the PSWindowsUpdate module in Powershell Gallery

.PARAMETER ServerNames
    An array of servers on which to install updates.  Specify using named parameter, or from the pipeline

.PARAMETER Install
    A switch to indicate you actually want to install updates.  If omitted, available patches are only displayed

.PARAMETER RebootNow
    Valid only with the -Install switch.  Indicates that the server should reboot as soon as updates are installed

.PARAMETER RebootAt
    Valid only with the -Install switch.  Indicates that the server should reboot at the specified time

.Link
    PSWindowsUpdate in Powershell Gallery:
    https://www.powershellgallery.com/packages/PSWindowsUpdate/2.1.1.2
#>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ServerNames = $env:COMPUTERNAME,

        [switch]
        $MicrosoftUpdate,

        [switch]
        $Install,

        [switch]
        $RebootNow,

        [switch]
        $CheckLastUpdate,

        [datetime]
        $RebootAt = (get-date)
    )

    begin {
        #install the required module
        Install-Module -Scope CurrentUser PSWindowsUpdate
    }

    process {
        #for each server
        foreach ($server in $ServerNames) {
            try {
                #get a list of patches
                $updates = Get-WindowsUpdate -ComputerName $server -MicrosoftUpdate:$MicrosoftUpdates

                if ($CheckLastUpdate) { 
                    #get last update data
                    try {
                        $lastUpdate = Get-WULastResults -ComputerName $server
                        Write-Host "$server was last updated on $($lastUpdate.LastInstallationSuccessDate)"
                    }
                    catch {
                        Write-Warning "Could not last update status for $server.  You might not have permissions to do that."
                    }
                }

                #What is the update status of this server?
                if ($updates.Count -eq 0) {
                    Write-Host "There are no pending updates for $server"
                    continue
                }
                else {
                    Write-host "There are $($updates.Count) pending updates for $server"

                    $rebootRequired = $updates.Where( { $_.RebootRequired }).Count -gt 0
                    if ($rebootRequired) {
                        Write-Warning "***A reboot of $server IS required***"
                    }

                    $updates | Format-Table -AutoSize
                }
            }
            catch {
                Write-Error "An error occured while trying to get the list of updates on server $server"
                $_
            }

            if ($Install) {
                #if installing, behavior varies based on parameters
                if ($RebootNow -and (-not $rebootRequired)) {
                    try {
                        #install and reboot when done
                        Write-Host "Installing updates for $server and rebooting when complete"
                        Get-WindowsUpdate -Install -AcceptAll -AutoReboot -ComputerName $server -MicrosoftUpdate:$MicrosoftUpdates
                    }
                    catch {
                        Write-Error "An error occurred while trying to install patches and auto-reboot"
                        $_
                    }
                }
                elseif ($RebootAt -gt (get-date) -and (-not $rebootRequired)) {
                    try {
                        #if you supplied a reboot date in the future, schedule reboot for that time
                        Write-host "Installing updates for $server and rebooting at $RebootAt"
                        Get-WindowsUpdate -Install -AcceptAll -ScheduleReboot $RebootAt -ComputerName $server -MicrosoftUpdate:$MicrosoftUpdates
                    }
                    catch {
                        Write-Error "An error occurred while trying to install patches and schedule reboot for $RebootAt"
                        $_
                    }
                }
                else {
                    try {
                        #install updates and you have to reboot manually
                        Write-Host "Installing updates for $server.  You will have to reboot it manually, if required"
                        Get-WindowsUpdate -Install -AcceptAll -ComputerName $server -MicrosoftUpdate:$MicrosoftUpdates
                    }
                    catch {
                        Write-Error "An error occurred while trying to install patches"
                        $_
                    }
                }
            }
        }
    }
}