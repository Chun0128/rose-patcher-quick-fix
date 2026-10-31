param(
 [ValidateSet('Apply','Restore','Check')][string]$RequestedAction='Apply',
 [string]$InstallDirectory='', [string]$LeagueFile='', [string]$FixDataRoot='',
 [ValidateSet('en','zh-TW')][string]$UiLanguage='zh-TW',
 [switch]$ElevatedChild, [string]$OutcomeFile=''
)
$ErrorActionPreference='Stop'
$thisScript=$PSCommandPath
. (Join-Path $PSScriptRoot 'Rose-Patcher-Fix.ps1') -Language $UiLanguage
function Assert-NoMatch {
 if(Get-Process -Name 'League of Legends' -ErrorAction SilentlyContinue){throw (L 'A match is running. No files changed. Finish the match and try again.' '目前正在對局中，未更動檔案。請結束對局後再執行。')}
}
try {
 $selectedRose=Resolve-Rose $InstallDirectory
 if(-not $FixDataRoot){$FixDataRoot=Join-Path $env:LOCALAPPDATA 'RosePatcherFix'}
 if($RequestedAction -ne 'Restore'){
  $selectedGame=Resolve-Game $LeagueFile
  $null=Assert-Compatible $selectedGame
 } else {$selectedGame=''}
 if($RequestedAction -eq 'Check'){
  Write-Host (Invoke-Operation Check $selectedRose $selectedGame $FixDataRoot)
  exit 0
 }
 Assert-NoMatch
 $selectedTools=Join-Path $selectedRose '_internal\injection\tools'
 if($RequestedAction -eq 'Apply'){
  if((Test-Installed $selectedTools) -and (Get-Process -Name Rose -ErrorAction SilentlyContinue)){
   foreach($n in $script:Names){Assert-Signed (Join-Path $selectedTools $n)}
   $message=L 'The tested official LTK 1.29.1 pair is already installed and Rose is running. No files changed.' '目前已是這次通過實測的官方 LTK 1.29.1 組合，Rose 正在執行，不需要重複替換。'
   Write-Host $message -ForegroundColor Green
   if($ElevatedChild){Save-Json @{status='success';message=$message} $OutcomeFile}
   exit 0
  }
  $null=Prepare-Files $FixDataRoot
 } else {$null=Find-Backup $FixDataRoot $selectedRose}
 if(-not (Is-Admin)){
  if($ElevatedChild){throw (L 'Administrator permission was not granted.' '未取得管理員權限。')}
  New-Item -ItemType Directory -Path $FixDataRoot -Force | Out-Null
  $outcome=Join-Path $FixDataRoot ('oneclick_'+[guid]::NewGuid().ToString('N')+'.json')
  $launchArgs=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$thisScript+'"'),'-RequestedAction',$RequestedAction,'-UiLanguage',$UiLanguage,'-InstallDirectory',('"'+$selectedRose+'"'),'-FixDataRoot',('"'+$FixDataRoot+'"'),'-ElevatedChild','-OutcomeFile',('"'+$outcome+'"'))
  if($selectedGame){$launchArgs+=@('-LeagueFile',('"'+$selectedGame+'"'))}
  Write-Host (L 'Ready. Windows will request administrator permission to back up and update the Rose files.' '已備妥。Windows 將要求管理員權限，以備份並更新 Rose 的兩個檔案。')
  $elevated=Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList $launchArgs -PassThru
  $elevated.WaitForExit()
  if(-not (Test-Path -LiteralPath $outcome)){throw (L 'The administrator operation did not complete. Check the Windows permission prompt.' '管理員操作未完成，請檢查 Windows 權限確認。')}
  $reply=Get-Content -LiteralPath $outcome -Raw -Encoding UTF8 | ConvertFrom-Json
  if($reply.status -ne 'success'){throw $reply.message}
  Write-Host $reply.message -ForegroundColor Green
  exit 0
 }
 Assert-NoMatch
 $running=@(Get-Process -Name Rose -ErrorAction SilentlyContinue)
 foreach($app in $running){if($app.Path -ine (Join-Path $selectedRose 'Rose.exe')){throw (L 'Another Rose installation is running. No programs closed or files changed.' '另有不同路徑的 Rose 正在執行，未關閉或更換檔案。')}}
 foreach($app in $running){
  Assert-NoMatch
  if($app.MainWindowHandle -ne [IntPtr]::Zero){$null=$app.CloseMainWindow();$null=$app.WaitForExit(2500)}
  $app.Refresh()
  if(-not $app.HasExited){Stop-Process -Id $app.Id -ErrorAction Stop;$null=$app.WaitForExit(5000)}
 }
 Assert-NoMatch
 $message=Invoke-Operation $RequestedAction $selectedRose $selectedGame $FixDataRoot
 $null=Start-Process -FilePath (Join-Path $selectedRose 'Rose.exe') -WorkingDirectory $selectedRose -WindowStyle Normal -PassThru
 $message+=(L ' Rose has restarted; verify the skin in Practice Tool.' ' Rose 已重新開啟；請進訓練模式確認造型。')
 if($ElevatedChild){Save-Json @{status='success';message=$message} $OutcomeFile}
 else {Write-Host $message -ForegroundColor Green}
} catch {
 if($ElevatedChild -and $OutcomeFile){Save-Json @{status='failed';message=$_.Exception.Message} $OutcomeFile}
 else {Write-Host $_.Exception.Message -ForegroundColor Red}
 exit 1
}
