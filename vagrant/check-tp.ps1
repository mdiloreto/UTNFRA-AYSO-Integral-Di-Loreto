# --------- Config ---------
$VMs = @("VM1-Grupo-diloreto","VM2-Grupo-diloreto")
$ExpectedOS = @("ubuntu","fedora")
$ExtraDisks = @("sdb","sdc","sdd","sde")
$HostsLines = @(
  "192.168.56.11 vm1-grupo-diloreto",
  "192.168.56.12 vm2-grupo-diloreto"
)
$VGname = "vg_datos"; $VGtemp="vg_temp"
$DockerLVsize="10M";  $WorkLVsize="2.5G"; $SwapDev="/dev/sdd"

# --------- helpers ---------
$green="`e[32m"; $red="`e[31m"; $yel="`e[33m"; $nc="`e[0m"
function Pass($m){Write-Host "$green✔$nc $m"}
function Fail($m){Write-Host "$red✘ $m$nc"}
function Warn($m){Write-Host "$yel⚠ $m$nc"}
function SSH-VM($vm,$cmd){ & vagrant ssh $vm -c $cmd 2>$null; $LASTEXITCODE }

Write-Host "🔍 1. VMs / box"
for($i=0;$i -lt $VMs.Count;$i++){
  if(vagrant status $VMs[$i] | Select-String -Quiet "running"){
    Pass "$($VMs[$i]) encendida"
  } else { Fail "$($VMs[$i]) apagada" }

  $os = (& vagrant ssh $VMs[$i] -c "grep ^ID= /etc/os-release | cut -d= -f2" 2>$null).Trim()
  if($os -like "$($ExpectedOS[$i])*"){ Pass "OS $os ok" }
  else { Fail "OS $os no coincide con $($ExpectedOS[$i])" }
}

Write-Host "🔍 2. Discos extra"
foreach($vm in $VMs){
  foreach($d in $ExtraDisks){
    if(SSH-VM $vm "[ -b /dev/$d ]" -eq 0){ Pass "$vm /dev/$d" }
    else { Fail "$vm falta /dev/$d" }
  }
}

Write-Host "🔍 3. /etc/hosts"
foreach($vm in $VMs){
  foreach($line in $HostsLines){
    if(SSH-VM $vm "grep -qx '$line' /etc/hosts" -eq 0){ Pass "$vm hosts ok ($line)" }
    else { Fail "$vm sin '$line'" }
  }
}

Write-Host "🔍 4. sudo NOPASSWD + paquetes"
foreach($vm in $VMs){
  if(SSH-VM $vm "sudo -n true" -eq 0){ Pass "$vm sudo NOPASSWD" }
  else { Fail "$vm pide password sudo" }

  foreach($pkg in @("git","tree")){
    if(SSH-VM $vm "command -v $pkg" -eq 0){ Pass "$vm tiene $pkg" }
    else { Fail "$vm sin $pkg" }
  }
}

Write-Host "🔍 5. SSH cruzado"
if(SSH-VM $VMs[0] "ssh -o BatchMode=yes $($VMs[1]) hostname" -eq 0){ Pass "VM1→VM2 OK" } else { Warn "VM1 no puede ssh VM2" }
if(SSH-VM $VMs[1] "ssh -o BatchMode=yes $($VMs[0]) hostname" -eq 0){ Pass "VM2→VM1 OK" } else { Warn "VM2 no puede ssh VM1" }

Write-Host "🔍 6. LVM"
function Test-LV($vm,$vg,$lv,$size,$mount){
  if(SSH-VM $vm "lvs --noheadings -o lv_size /dev/$vg/$lv | grep -q $size" -eq 0){
    Pass "$vm $lv size $size"
  } else { Fail "$vm $lv tamaño incorrecto" }
  if($mount){
    if(SSH-VM $vm "mount | grep -q '/dev/$vg/$lv on $mount '" -eq 0){
      Pass "$vm $lv montado en $mount"
    } else { Fail "$vm $lv no montado" }
  }
}
Test-LV $VMs[0] $VGname lv_docker $DockerLVsize "/var/lib/docker"
Test-LV $VMs[0] $VGname lv_work   $WorkLVsize   "/work"
if(SSH-VM $VMs[0] "vgs | grep -q $VGtemp" -eq 0){ Pass "VG temp $VGtemp existe" } else { Warn "falta VG temp $VGtemp" }

Write-Host "🔍 7. Swap"
if(SSH-VM $VMs[0] "swapon --summary | grep -q '$SwapDev'" -eq 0){ Pass "Swap activo" } else { Fail "Swap no activo" }

Write-Host "$green🏁  Validación COMPLETA – todo OK$nc"
