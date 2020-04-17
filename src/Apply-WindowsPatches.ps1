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
        $ServerNames,

        [switch]
        $Install,

        [switch]
        $RebootNow,

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
                $updates = Get-WindowsUpdate -ComputerName $server
                if ($updates.Count -eq 0) {
                    Write-Host "There are no pending updates for $server"
                    continue
                }
                else {
                    Write-host "There are pending updates for $server"
                    $updates | Format-Table -AutoSize
                }
            }
            catch {
                Write-Error "An error occured while trying to get the list of updates on server $server"
                $_
            }

            if ($Install) {
                #if installing, behavior varies based on parameters
                if ($RebootNow) {
                    try {
                        #install and reboot when done
                        Write-Host "Installing updates for $server and rebooting when complete"
                        Get-WindowsUpdate -Install -AcceptAll -AutoReboot -ComputerName $server
                    }
                    catch {
                        Write-Error "An error occurred while trying to install patches and auto-reboot"
                        $_
                    }
                }
                elseif ($RebootAt -gt (get-date)) {
                    try {
                        #if you supplied a reboot date in the future, schedule reboot for that time
                        Write-host "Installing updates for $server and rebooting at $RebootAt"
                        Get-WindowsUpdate -Install -AcceptAll -ScheduleReboot $RebootAt -ComputerName $server
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
                        Get-WindowsUpdate -Install -AcceptAll -ComputerName $server
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
