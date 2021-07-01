 Param([Parameter(Mandatory=$false)] [Switch]$RebootSkip)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

function Write-HostCenter { param($Message) Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) }

Start-Transcript -Path "$PSScriptRoot\Log.txt"

clear

$WorkDir = "$PSScriptRoot\Bin"
$SunshineDir = "$ENV:ProgramData\sunshine"

Write-HostCenter "Sunshine GameStream Preparation Script"
Write-HostCenter "based on work by acceleration3, forked by Tom Grice"
Write-Host ""

try {

    if([bool]((quser) -imatch "rdp")) {
        throw "You are running a Microsoft RDP session which will not work to enable GameStream! You need to install a different Remote Desktop software like AnyDesk or TeamViewer!"
    }

    if(!$RebootSkip) {
        Write-Host "Your machine will restart at least once during this setup."
        Write-Host ""
        Write-Host "Step 1 - Installing requirements" -ForegroundColor Yellow
        & $PSScriptRoot\Steps\1_Install_Requirements.ps1 -Main
    } else {

        if(Get-ScheduledTask | Where-Object {$_.TaskName -like "GSSetup" }) {
            Unregister-ScheduledTask -TaskName "GSSetup" -Confirm:$false
        }
        Write-Host "The script will now continue from where it left off."
        Pause
    }

    Write-Host ""
    Write-Host "Step 2- Disabling Hyper-V Monitor and other GPUs" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\2_Disable_Other_GPUs.ps1

    Write-Host ""
    Write-Host "Step 3 - Setting up Sunshine" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\3_Setup_Sunshine.ps1

    Write-Host ""
    Write-Host "Step 4 - Applying fixes" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\4_Apply_Fixes.ps1

    Write-Host ""
    Write-Host "Done. You should now be able to use Moonlight after you restart your machine." -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "Do not forget to make a note of your configuration panel login details." -ForegroundColor Yellow
    Write-Host ""

    $restart = (Read-Host "Would you like to clean up unneccesary files?").ToLower();
    if($restart -eq "y") {
        & $PSScriptRoot\Steps\5_Cleanup.ps1
    }

    $restart = (Read-Host "Would you like to restart now? (y/n)").ToLower();
    if($restart -eq "y") {
        Restart-Computer -Force
    }
} catch {
    Write-Host $_.Exception -ForegroundColor Red
    Stop-Transcript
    Pause
}
