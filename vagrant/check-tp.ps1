# -------------- Config -----------------
$VMs         = @('VM1-Grupo-diloreto','VM2-Grupo-diloreto')
$ExpectedOS  = @('ubuntu','fedora')
$ExtraDisks  = @('sdb','sdc','sdd','sde')
$HostsLines  = @(
  '192.168.56.11 vm1-grupo-diloreto',
  '192.168.56.12 vm2-grupo-diloreto'
)
$VGname='vg_datos'; $VGtemp='vg_temp'
$DockerLVsize=10   # MB, numeric for easier compare
$WorkLVsize  =2560 # MB (2.5 G)
$SwapDev='/dev/sdd1'

# -------------- Helpers ----------------
$esc = [char]27
if(-not $Host.UI.SupportsVirtualTerminal) { $esc='';$nc=''}
$green="$esc[32m"; $red="$esc[31m"; $yel="$esc[33m"; $nc="$esc[0m"
$global:HasFail=$false
function Pass($m){Write-Host "$green✔$nc $m"}
function Fail($m){Write-Host "$red✘ $m$nc"; $global:HasFail = $true}
function Warn($m){Write-Host "$yel⚠ $m$nc"}
function SSH-VM($vm,$cmd){
    & vagrant ssh $vm -c $cmd 2>$null | Out-Null
    return $LASTEXITCODE
}

# 1) Vagrant status + OS check
Write-Host '🔍 1. VMs / box'
for($i=0;$i -lt $VMs.Count;$i++){
    $vm=$VMs[$i]; $osExpected=$ExpectedOS[$i]
    if(vagrant status $vm | Select-String -Quiet 'running'){ Pass "$vm running" } else { Fail "$vm stopped" }
    $os=(& vagrant ssh $vm -c "awk -F= '/^ID=/{print \$2}' /etc/os-release" 2>$null).Trim()
    if($os -like "$osExpected*"){ Pass "OS $os ok" } else { Fail "OS $os ≠ $osExpected" }
}

# 2) Extra disks
Write-Host '🔍 2. Extra disks'
foreach($vm in $VMs){
    foreach($d in $ExtraDisks){
        if(SSH-VM $vm "[ -b /dev/$d ]" -eq 0){ Pass "$vm /dev/$d" } else { Fail "$vm missing /dev/$d" }
    }
}

# 3) /etc/hosts
Write-Host '🔍 3. /etc/hosts'
foreach($vm in $VMs){
    foreach($line in $HostsLines){
        if(SSH-VM $vm "grep -qx '$line' /etc/hosts" -eq 0){ Pass "$vm hosts ok ($line)" }
        else { Fail "$vm lacks '$line'" }
    }
}

# 4) sudo NOPASSWD + packages
Write-Host '🔍 4. sudo & packages'
foreach($vm in $VMs){
    if(SSH-VM $vm 'sudo -n true' -eq 0){ Pass "$vm sudo NOPASSWD" } else { Fail "$vm asks sudo password" }
    foreach($pkg in 'git','tree'){
        if(SSH-VM $vm "command -v $pkg" -eq 0){ Pass "$vm has $pkg" } else { Fail "$vm missing $pkg" }
    }
}

# 5) Cross-SSH
Write-Host '🔍 5. cross-SSH'
if(SSH-VM $VMs[0] "ssh -o BatchMode=yes ${VMs[1]} hostname" -eq 0){ Pass 'VM1→VM2 OK' } else { Warn 'VM1 cannot ssh VM2' }
if(SSH-VM $VMs[1] "ssh -o BatchMode=yes ${VMs[0]} hostname" -eq 0){ Pass 'VM2→VM1 OK' } else { Warn 'VM2 cannot ssh VM1' }

# 6) LVM
Write-Host '🔍 6. LVM'
function Test-LV($vm,$vg,$lv,$sizeMB,$mount){
    $cmd = "lvs --noheadings --units m --nosuffix -o lv_size /dev/$vg/$lv | awk '{print int(\$1+0.5)}'"
    $lvMB = (& vagrant ssh $vm -c $cmd 2>$null).Trim() -as [int]
    if($lvMB -eq $sizeMB){ Pass "$vm $lv size ${lvMB}M" } else { Fail "$vm $lv size ${lvMB}M ≠ ${sizeMB}M" }
    if($mount){
        if(SSH-VM $vm "mount | grep -q '/dev/$vg/$lv on $mount '" -eq 0){ Pass "$vm $lv mounted on $mount" }
        else { Fail "$vm $lv not mounted" }
    }
}
Test-LV $VMs[0] $VGname 'lv_docker' $DockerLVsize '/var/lib/docker'
Test-LV $VMs[0] $VGname 'lv_work'   $WorkLVsize   '/work'
if(SSH-VM $VMs[0] "vgs | grep -q $VGtemp" -eq 0){ Pass "VG temp $VGtemp exists" } else { Warn "missing VG temp $VGtemp" }

# 7) Swap
Write-Host '🔍 7. Swap'
if(SSH-VM $VMs[0] "swapon --summary | grep -q '$SwapDev'" -eq 0){ Pass 'Swap active' } else { Fail 'Swap not active' }

# Final banner
if(-not $global:HasFail){
    Write-Host "$green🏁  Validation PASSED – all OK$nc"
} else {
    Write-Host "$red🏁  Validation finished – some checks failed$nc"
}
