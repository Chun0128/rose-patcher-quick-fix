param(
 [ValidateSet('Menu','Check','Apply','Restore')][string]$Action='Menu',
 [string]$RosePath='', [string]$GamePath='', [string]$DataRoot='',
 [ValidateSet('en','zh-TW')][string]$Language='zh-TW',
 [switch]$Child, [string]$ResultFile=''
)
$ErrorActionPreference='Stop'
function L([string]$English,[string]$TraditionalChinese) {
 if($script:Language -eq 'zh-TW'){return $TraditionalChinese}
 return $English
}
$script:Names=@('ltk_patcher_dll.dll','ltk_patcher_host.exe')
$script:Wanted=@{
 'ltk_patcher_dll.dll'='3dce3ac99e55839559129e32ae9de75ddaec40f310118475248f99c61656ecf5'
 'ltk_patcher_host.exe'='23fa1aaeda1a0c743da44227f179084e1fb81c7cd262144a3c8604ffc49d3bc1'
}
$script:InstallerHash='8c8119b0eb8df61fe0697de047f21d55bfe2c4ccf97684945b11b8c9ebd0bd30'
$script:Download='https://github.com/LeagueToolkit/ltk-manager/releases/download/v1.29.1/LTK.Manager_1.29.1_x64-setup.exe'
$script:Eol=[uint32]1793516400
$script:TargetHashes=$script:Wanted.Clone()
. (Join-Path $PSScriptRoot 'Patcher-Detection.ps1')
function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Hash([string]$Path,[string]$Expected) {
 if((Hash-File $Path) -ne $Expected){throw (L "File checksum mismatch; stopped: $Path" "檔案雜湊不符，已停止：$Path")}
}
function Assert-Signed([string]$Path) {
 $signature=Get-AuthenticodeSignature -LiteralPath $Path
 if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(?:^|,\s*)O=Natoken LLC(?:,|$)'){throw (L "Digital signature could not be verified; stopped: $Path" "數位簽章無法驗證，已停止：$Path")}
}
function Read-GameBuild([string]$Path) {
 $r=[IO.BinaryReader]::new([IO.File]::OpenRead($Path))
 try {
  if($r.ReadUInt16() -ne 0x5a4d){throw (L 'The game file is not a valid PE executable.' '遊戲檔不是有效 PE 檔案。')}
  $r.BaseStream.Position=0x3c; $pe=$r.ReadUInt32()
  if($pe -gt $r.BaseStream.Length-24){throw (L 'The game PE header is incomplete.' '遊戲 PE 標頭不完整。')}
  $r.BaseStream.Position=$pe
  if($r.ReadUInt32() -ne 0x4550 -or $r.ReadUInt16() -ne 0x8664){throw (L 'A Windows x64 game executable is required.' '需要 Windows x64 遊戲執行檔。')}
  $r.BaseStream.Position=$pe+8; return $r.ReadUInt32()
 } finally {$r.Dispose()}
}
function Assert-Compatible([string]$GameFile) {
 $build=Read-GameBuild $GameFile
 if($build -gt $script:Eol){throw (L 'This game build is newer than the limit supported by the 1.29.1 patcher. Apply is unavailable.' '目前遊戲建置已超過這組 1.29.1 補丁的支援上限，不能套用。')}
 return $build
}
function Assert-Closed {
 if(Get-Process -Name 'League of Legends','Rose','ltk_patcher_host' -ErrorAction SilentlyContinue){
  throw (L 'Finish the game and fully exit Rose from the system tray, then try again. This tool does not force programs to close.' '請先結束對局，並從系統匣完全退出 Rose，再重新執行。工具不會強制關閉程式。')
 }
}
function Resolve-Rose([string]$Path) {
 if(-not $Path){$Path=Join-Path $env:ProgramFiles 'Rose'}
 if(-not (Test-Path -LiteralPath (Join-Path $Path 'Rose.exe'))){
  if($Child){throw (L 'The specified Rose.exe was not found.' '找不到指定的 Rose.exe。')}
  $Path=(Read-Host (L 'Enter the Rose installation folder (containing Rose.exe)' '輸入 Rose 安裝資料夾（裡面應有 Rose.exe）')).Trim('"')
 }
 $Path=(Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')
 if(-not (Test-Path -LiteralPath (Join-Path $Path 'Rose.exe'))){throw (L 'The selected folder is not a Rose installation.' '所選位置不是 Rose 安裝資料夾。')}
 $tools=Join-Path $Path '_internal\injection\tools'
 foreach($name in $script:Names){
  if(-not (Test-Path -LiteralPath (Join-Path $tools $name))){throw (L "Rose patcher file is missing: $name. This tool replaces an existing installed patcher pair." "Rose 補丁檔不存在：$name。此工具用於更換已安裝的補丁。")}
 }
 return $Path
}
function Resolve-Game([string]$Path) {
 if(-not $Path) {
  $config=Join-Path $env:LOCALAPPDATA 'Rose\config.ini'
  if(Test-Path -LiteralPath $config){
   foreach($line in Get-Content -LiteralPath $config){
    if($line -match '^\s*leaguepath\s*=\s*(.+?)\s*$'){$Path=$Matches[1];break}
   }
  }
 }
 if($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)){
  if([IO.Path]::GetFileName($Path) -ine 'League of Legends.exe'){throw (L 'Select League of Legends.exe.' '請選擇 League of Legends.exe。')}
  return (Resolve-Path -LiteralPath $Path).Path
 }
 if($Path -and (Test-Path -LiteralPath (Join-Path $Path 'Game\League of Legends.exe'))){$Path=Join-Path $Path 'Game'}
 if(-not $Path -or -not (Test-Path -LiteralPath (Join-Path $Path 'League of Legends.exe'))){
  if($Child){throw (L 'The game executable was not found.' '找不到遊戲執行檔。')}
  $Path=(Read-Host (L 'Enter the League of Legends Game folder' '輸入遊戲 Game 資料夾')).Trim('"')
 }
 return (Resolve-Path -LiteralPath (Join-Path $Path 'League of Legends.exe')).Path
}
function Find-7Zip {
 $options=@((Join-Path $env:ProgramFiles '7-Zip\7z.exe'))
 $pf86=[Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
 if($pf86){$options+=Join-Path $pf86 '7-Zip\7z.exe'}
 $cmd=Get-Command 7z.exe -ErrorAction SilentlyContinue
 if($cmd){$options+=$cmd.Source}
 foreach($p in $options){if(Test-Path -LiteralPath $p){return $p}}
 throw (L '7-Zip is required to extract the official installer. Install it from https://www.7-zip.org/ and run this tool again.' '需要 7-Zip 提取官方安裝包。請先從 https://www.7-zip.org/ 安裝 7-Zip，再執行本工具。')
}
function Prepare-Files([string]$Root) {
 $cache=Join-Path $Root 'cache';$source=Join-Path $cache '1.29.1';$complete=$true
 foreach($n in $script:Names){
  $p=Join-Path $source $n
  if(-not (Test-Path -LiteralPath $p)){$complete=$false;break}
  if((Hash-File $p) -ne $script:Wanted[$n]){$complete=$false;break}
 }
 if(-not $complete){
  $seven=Find-7Zip
  New-Item -ItemType Directory -Path $cache -Force | Out-Null
  $installer=Join-Path $cache 'LTK.Manager_1.29.1_x64-setup.exe'
  if(-not (Test-Path -LiteralPath $installer)){
   Write-Host (L 'Downloading the official LTK 1.29.1 installer (about 22 MB)...' '正在下載官方 LTK 1.29.1 安裝包（約 22 MB）...')
   [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
   $oldProgress=$ProgressPreference;$ProgressPreference='SilentlyContinue'
   try{Invoke-WebRequest -Uri $script:Download -OutFile ($installer+'.download') -UseBasicParsing -TimeoutSec 120}
   finally{$ProgressPreference=$oldProgress}
   Assert-Hash ($installer+'.download') $script:InstallerHash
   Move-Item -LiteralPath ($installer+'.download') -Destination $installer -Force
  }
  Assert-Hash $installer $script:InstallerHash;Assert-Signed $installer
  & $seven e $installer ("-o"+$source) 'ltk_patcher_dll.dll' 'ltk_patcher_host.exe' -y -bso0 -bsp0
  if($LASTEXITCODE -ne 0){throw (L '7-Zip extraction failed. The installed files have not been changed.' '7-Zip 提取失敗，原安裝未變更。')}
 }
 foreach($n in $script:Names){$p=Join-Path $source $n;Assert-Hash $p $script:Wanted[$n];Assert-Signed $p}
 if((Read-DllEol (Join-Path $source 'ltk_patcher_dll.dll')) -ne $script:Eol){throw 'Patcher support limit differs from verified release.'}
 return $source
}
function Test-Installed([string]$Tools) {
 foreach($n in $script:Names){if((Hash-File (Join-Path $Tools $n)) -ne $script:Wanted[$n]){return $false}}
 return $true
}
function Save-Json($Object,[string]$Path) {
 $Object | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function New-Backup([string]$Tools,[string]$Root,[string]$Rose) {
 $folder=Join-Path (Join-Path $Root 'backups') ((Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8))
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 $records=@()
 foreach($n in $script:Names){
  $target=Join-Path $Tools $n;$hash=Hash-File $target;$backup=Join-Path $folder $n
  Copy-Item -LiteralPath $target -Destination $backup;Assert-Hash $backup $hash
  $records+=@{name=$n;original_sha256=$hash;applied_sha256=$script:Wanted[$n]}
 }
 Save-Json @{schema=1;rose=$Rose;created=(Get-Date -Format o);state='prepared';files=$records} (Join-Path $folder 'manifest.json')
 return $folder
}
function Find-Backup([string]$Root,[string]$Rose) {
 $parent=Join-Path $Root 'backups'
 if(Test-Path -LiteralPath $parent){
  foreach($d in Get-ChildItem -LiteralPath $parent -Directory | Sort-Object Name -Descending){
   $mf=Join-Path $d.FullName 'manifest.json'
   if(Test-Path -LiteralPath $mf){
    $m=Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
    if($m.rose -ieq $Rose -and $m.state -eq 'applied'){return $d.FullName}
   }
  }
 }
 throw (L 'No restorable backup created by this tool was found for this Rose installation.' '找不到此工具為這個 Rose 安裝建立的可還原備份。')
}
function Set-Pair([string]$Tools,[string]$Source,$Before,$After) {
 $items=@();$changed=@();$rollbackFailed=$false
 try {
  foreach($n in $script:Names){
   $target=Join-Path $Tools $n;$src=Join-Path $Source $n
   Assert-Hash $target $Before[$n];Assert-Hash $src $After[$n]
   $stage=Join-Path $Tools ('rosefix_'+[guid]::NewGuid().ToString('N')+'.tmp')
   $item=@{name=$n;target=$target;stage=$stage;previous=$stage+'.previous'};$items+=,$item
   Copy-Item -LiteralPath $src -Destination $stage;Assert-Hash $stage $After[$n]
  }
  foreach($item in $items){
   Assert-Hash $item.target $Before[$item.name]
   [IO.File]::Replace($item.stage,$item.target,$item.previous);$changed+=,$item
  }
  foreach($item in $items){Assert-Hash $item.target $After[$item.name]}
 } catch {
  $failure=$_.Exception.Message
  foreach($item in $changed){
   try{Copy-Item -LiteralPath $item.previous -Destination $item.target -Force;Assert-Hash $item.target $Before[$item.name]}
   catch{$rollbackFailed=$true;$failure+=(L '; Automatic rollback failed. Keep the .previous files and backups: ' '；自動還原失敗，請保留 .previous 檔與備份：')+$_.Exception.Message}
  }
  throw $failure
 } finally {
  foreach($item in $items){
   if(Test-Path -LiteralPath $item.stage){Remove-Item -LiteralPath $item.stage -Force}
   if(-not $rollbackFailed -and (Test-Path -LiteralPath $item.previous)){Remove-Item -LiteralPath $item.previous -Force}
  }
 }
}
function Is-Admin {
 $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Invoke-Elevated([string]$Operation,[string]$Rose,[string]$Game,[string]$Root) {
 New-Item -ItemType Directory -Path $Root -Force | Out-Null
 $result=Join-Path $Root ('result_'+[guid]::NewGuid().ToString('N')+'.json')
 $launchArgs=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$PSCommandPath+'"'),'-Action',$Operation,'-Language',$script:Language,'-RosePath',('"'+$Rose+'"'),'-DataRoot',('"'+$Root+'"'),'-Child','-ResultFile',('"'+$result+'"'))
 if($Game){$launchArgs+=@('-GamePath',('"'+$Game+'"'))}
 Write-Host (L 'Ready. Windows will request administrator permission to update the Rose installation folder.' '已備妥；Windows 即將確認管理員權限，以更新 Rose 安裝資料夾。')
 $p=Start-Process -FilePath powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList $launchArgs -PassThru -Wait
 if(-not (Test-Path -LiteralPath $result)){throw (L 'The administrator operation did not complete. Check the Windows permission prompt.' '管理員操作未完成，請檢查 Windows 權限確認。')}
 $r=Get-Content -LiteralPath $result -Raw | ConvertFrom-Json
 if($r.status -ne 'success'){throw $r.message}
 Write-Host $r.message -ForegroundColor Green
}
function Invoke-Operation([string]$Operation,[string]$Rose,[string]$Game,[string]$Root) {
 $Rose=Resolve-Rose $Rose;$tools=Join-Path $Rose '_internal\injection\tools'
 if($Operation -ne 'Restore'){
  $script:Wanted=$script:TargetHashes.Clone()
  $Game=Resolve-Game $Game;$build=Assert-Compatible $Game
  Write-Host ((L 'Game build UTC: ' '遊戲建置 UTC：')+[DateTimeOffset]::FromUnixTimeSeconds($build).ToString('u'))
  Write-Host ('Rose：'+$Rose)
 }
 if($Operation -eq 'Check'){
  foreach($n in $script:Names){
   $path=Join-Path $tools $n
   Write-Host ($n+'  '+(Hash-File $path)+(L '  Signature: ' '  簽章：')+(Get-AuthenticodeSignature -LiteralPath $path).Status)
  }
  if(Test-Installed $tools){Write-Host (L 'The matching 1.29.1 patcher pair is already installed.' '目前已是這組 1.29.1 補丁。') -ForegroundColor Green}
  else{Write-Host (L 'Game build check passed. Choose Apply from the main menu.' '建置日期檢查通過，可從主選單選擇套用。')}
  return (L 'Check complete.' '檢查完成。')
 }
 if($Operation -eq 'Apply' -and (Test-Installed $tools)){return (L 'Already using 1.29.1. No files were changed.' '已是 1.29.1，沒有重複變更。')}
 Assert-Closed
 if($Operation -eq 'Apply'){
  $source=Prepare-Files $Root
  Write-Host (L 'The originals will be backed up before replacing both ltk_patcher_dll.dll and ltk_patcher_host.exe.' '將成套更換 ltk_patcher_dll.dll 與 ltk_patcher_host.exe，並先備份原檔。')
 } else{$backup=Find-Backup $Root $Rose}
 if(-not (Is-Admin)){
  if($Child){throw (L 'Administrator permission was not granted.' '未取得管理員權限。')}
  Invoke-Elevated $Operation $Rose $Game $Root
  return (L 'Operation complete. Open Rose from its usual shortcut and test in Practice Tool.' '操作完成。請從原本捷徑開啟 Rose，進訓練模式驗證。')
 }
 Assert-Closed
 if($Operation -eq 'Apply'){
  $null=Assert-Compatible $Game;$backup=New-Backup $tools $Root $Rose
  $manifest=Get-Content -LiteralPath (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
  $before=@{};foreach($f in $manifest.files){$before[$f.name]=$f.original_sha256}
  Assert-Closed;Set-Pair $tools $source $before $script:Wanted
  $manifest.state='applied';Save-Json $manifest (Join-Path $backup 'manifest.json')
  return ((L 'Files applied; in-game result is not yet verified. Original backup: ' '檔案已套用；遊戲內結果尚未驗證。原檔備份：')+$backup+(L '. Open Rose from its usual shortcut and test in Practice Tool.' '。請從原本捷徑開啟 Rose，再進訓練模式測試。'))
 } else{
  $manifest=Get-Content -LiteralPath (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
  if(@($manifest.files).Count -ne 2){throw (L 'The backup manifest has an invalid format.' '備份清單格式不符。')}
  $after=@{};$script:Wanted=@{}
  foreach($n in $script:Names){
   $row=@($manifest.files | Where-Object {$_.name -eq $n})
   if($row.Count -ne 1){throw (L 'The backup manifest is incomplete.' '備份清單不完整。')}
   $script:Wanted[$n]=$row[0].applied_sha256
   if($script:Wanted[$n] -notmatch '^[a-fA-F0-9]{64}$'){throw 'Invalid applied hash in backup manifest.'}
   $after[$n]=$row[0].original_sha256;Assert-Hash (Join-Path $backup $n) $after[$n]
  }
  Assert-Closed;Set-Pair $tools $backup $script:Wanted $after
  $manifest.state='restored';Save-Json $manifest (Join-Path $backup 'manifest.json')
  return (L 'Restore complete. Both original files have been verified.' '還原成功，已核對兩個原檔。')
 }
}
if($MyInvocation.InvocationName -eq '.'){return}
if(-not $DataRoot){$DataRoot=Join-Path $env:LOCALAPPDATA 'RosePatcherFix'}
try{
 if($Action -eq 'Menu'){
  Write-Host (L 'Rose Patcher Quick Fix 1.3 (LTK 1.29.1)' 'Rose 補丁相容性工具 1.3（LTK 1.29.1）') -ForegroundColor Cyan
  Write-Host (L 'Uses the verified official LTK 1.29.1 pair. Game date and signatures are checked; skins still require an in-game test.' '使用已核對的官方 LTK 1.29.1 配套檔案。會檢查遊戲建置與簽章；造型效果仍需進遊戲實測。')
  while($true){
   Write-Host '';Write-Host (L '1 Check    2 Download and apply    3 Restore originals    L Language    0 Exit' '1 檢查版本    2 下載並套用    3 還原原檔    L 語言    0 離開')
   $choice=Read-Host (L 'Choose' '選擇');if($choice -eq '0'){break}
   if($choice -eq 'L'){
    if($script:Language -eq 'en'){$script:Language='zh-TW'}else{$script:Language='en'}
    Write-Host (L 'Language: English' '語言：繁體中文') -ForegroundColor Cyan
    continue
   }
   $op=switch($choice){'1'{'Check'}'2'{'Apply'}'3'{'Restore'}default{''}}
   if(-not $op){continue}
   try{Write-Host (Invoke-Operation $op $RosePath $GamePath $DataRoot) -ForegroundColor Green}
   catch{Write-Host $_.Exception.Message -ForegroundColor Yellow}
  }
 } else{
  $message=Invoke-Operation $Action $RosePath $GamePath $DataRoot
  if($Child){Save-Json @{status='success';message=$message} $ResultFile}else{Write-Host $message -ForegroundColor Green}
 }
} catch{
 if($Child -and $ResultFile){Save-Json @{status='failed';message=$_.Exception.Message} $ResultFile}
 else{Write-Error $_.Exception.Message}
 exit 1
}
