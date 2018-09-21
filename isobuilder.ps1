Param(
  [String]$workingDirectory,
  [String]$latestUpdateUrl
)

$originalIso = "Win2016EN.iso"
$originalIsoUrl = "https://YOURURL/Win2016EN.iso"

$servicingUpdate = "windows10.0-kb4132216-x64_9cbeb1024166bdeceff90cd564714e1dcd01296e.msu"
$servicingUpdateUrl = "http://download.windowsupdate.com/c/msdownload/update/software/crup/2018/05/windows10.0-kb4132216-x64_9cbeb1024166bdeceff90cd564714e1dcd01296e.msu"

function Get-OriginalIso {
  Write-Host "Downloading from $originalIsoUrl..."
  Start-BitsTransfer -source $originalIsoUrl
}

function Get-ServicingUpdate {
  Write-Host "Downloading from $servicingUpdateUrl..."
  Start-BitsTransfer -source $servicingUpdateUrl -Destination ${pwd}\updates
}

function Get-LatestUpdateLocal {
  Write-Host "Downloading from $latestUpdateUrl..."
  Start-BitsTransfer -source $latestUpdateUrl -Destination ${pwd}\updates
}

function Update-MountedSource($wimIndex) {
  Write-Host "Setting install.wim as read-write..."
  Set-ItemProperty $pwd\original\sources\install.wim -Name IsReadOnly -Value $false

  Write-Host "Mounting install.wim index:$wimIndex..."
  dism.exe /mount-wim /wimfile:"original\sources\install.wim" /mountdir:".\mount" /index:$wimIndex

  Write-Host "Applying servicing update..."
  dism.exe /image:mount /add-package:$servicingUpdatePath

  Write-Host "Applying latest cummulative update $kb..."
  dism.exe /image:mount /add-package:$latestUpdatePath

  Write-Host "Cleaning up image..."
  dism.exe /image:mount /cleanup-image /StartComponentCleanup /ResetBase

  Write-Host "Dismounting install.wim..."
  dism.exe /unmount-image /mountdir:mount /commit
}

if ($workingDirectory) {
  New-Item -ItemType Directory -Force -Path $workingDirectory
  cd $workingDirectory
}

$pwd = (Get-Location).Path
Write-Host "Setting pwd: $pwd"

Write-Host "Installing Get-LatestUpdate module..."
Install-Module -name LatestUpdate -Confirm:$false -Force

$latestUpdate = (Get-LatestUpdate -WindowsVersion windows10 -build 14393 | where {$_.Note -like "*Server 2016*"})

if ($latestUpdateUrl) {
  Write-Host "Using latestUpdateUrl from commandline: $latestUpdateUrl"
  $latestUpdateUrl -match ".*\/(.*)$"
  $latestUpdateFile = $matches[1]
  $latestUpdatePath = $pwd + "\updates\" + $latestUpdateFile
  $latestUpdateFile -match "kb[\d]{7}"
  $kb = ($matches[0]).ToUpper()
  $latestUpdateUrl -match "\d{4}"
  $year = $matches[0]
  $latestUpdateUrl -match "\b\d{2}?\b"
  $month = $matches[0]
  $latestUpdateDate = $year + "-" + $month
} else {
  $note = ($latestUpdate).note
  $kb = ($latestUpdate).kb
  ($latestUpdate).note -match "^[0-9]*-[0-9]*"
  $latestUpdateDate = $matches[0]
  $latestUpdateUrl = $latestUpdate.url
  $latestUpdateUrl -match ".*\/(.*)$"
  $latestUpdateFile = $matches[1]
  $latestUpdatePath = $pwd + "\updates\" + $latestUpdateFile
}
$latestUpdateIso = $pwd + "\iso\" + "Win2016EN-(" + $kb + ")-" + $latestUpdateDate + ".iso"

Write-Host "Latest update: $latestUpdate"
Write-Host "Latest update URL: $latestUpdateUrl"
Write-Host "Latest update note: $note"
Write-Host "Latest update note: $kb"
Write-Host "Latest update date: $latestUpdateDate"
Write-Host "Latest update file: $latestUpdateFile"
Write-Host "Latest update path: $latestUpdatePath"
Write-Host "Latest update ISO: $latestUpdateIso"

Write-Host "Cleaning up..."
Remove-Item -Recurse -Force .\original

Write-Host "Creating folders..."
New-Item -ItemType Directory -Force -Path .\original
New-Item -ItemType Directory -Force -Path .\mount
New-Item -ItemType Directory -Force -Path .\updates
New-Item -ItemType Directory -Force -Path .\iso

$originalIsoPath = $pwd + "\iso\" + $originalIso
Write-Host "Checking if original iso exists..."

if (Test-Path $originalIsoPath -PathType Leaf){
  Write-Host "...iso exists."
} else {
  Write-Host "...iso does not exist."
  Get-OriginalIso
}

$servicingUpdatePath = $pwd + "\updates\" + $servicingUpdate
Write-Host "Checking $servicingUpdatePath..."
if (Test-Path $servicingUpdatePath -PathType Leaf){
  Write-Host "...servicing update exists."
} else {
  Write-Host "...servicing update does not exist."
  Get-ServicingUpdate
}

Write-Host "Checking $latestUpdatePath..."
if (Test-Path $latestUpdatePath -PathType Leaf){
  Write-Host "...latest update exists."
} else {
  Write-Host "...latest update does not exist."
  Get-LatestUpdateLocal
}

if (Test-Path $latestUpdateIso -PathType Leaf) {
  Write-Host "Latest ISO already found: $latestUpdateIso. Nothing to do, exiting..."
  exit 0
}

Write-Host "Building updated ISO: $latestUpdateIso..."

Write-Host "Mounting iso image: $originalIsoPath"
Mount-DiskImage $originalIsoPath

Write-Host "Copying files from mounted OriginalIso..."
$isoDrive = (get-volume | ? FileSystem -eq UDF).DriveLetter
robocopy /s /e ${isoDrive}:\ $pwd\original

Write-Host "Dismounting original iso image:  $originalIsoPath"
Dismount-DiskImage $originalIsoPath

#Update-MountedSource(1) # Windows Server 2016 Standard Core
Update-MountedSource(2) # Windows Server 2016 Standard GUI
#Update-MountedSource(3) # Windows Server 2016 Datacenter Core
#Update-MountedSource(4) # Windows Server 2016 Datacenter GUI

Write-Host "Bulding ISO..."
cd original
& "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -bootdata:"2#p0,e,bboot\Etfsboot.com#pEF,e,befi\Microsoft\boot\Efisys.bin" -u1 -udfver102 ${pwd}\original ${latestUpdateIso}
cd $pwd

Write-Host "Done."
