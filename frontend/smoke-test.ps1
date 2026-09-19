$ErrorActionPreference = 'Stop'
$base = 'http://localhost:8080/api'

function J($o){ ConvertTo-Json -InputObject $o -Compress }
function AH($t){ @{ Authorization = "Bearer $t" } }
function Reg($o){ Invoke-RestMethod -Uri "$base/auth/register" -Method Post -ContentType 'application/json' -Body (J $o) }

# ---- auth ----
$r1 = Reg @{ email='firesmoke@test.com'; fullName='Fire Smoke'; password='secret123' }
$t1 = $r1.token
Write-Output "register ok: user=$($r1.fullName) tokenLen=$($t1.Length)"

try { Reg @{ email='firesmoke@test.com'; fullName='Dup'; password='x' } | Out-Null; Write-Output 'dup register: NO ERROR (BAD)' }
catch { Write-Output "dup register -> $($_.Exception.Response.StatusCode.value__)" }

try { Invoke-RestMethod -Uri "$base/auth/login" -Method Post -ContentType 'application/json' -Body (J @{ email='firesmoke@test.com'; password='wrong' }) | Out-Null; Write-Output 'bad login: NO ERROR (BAD)' }
catch { Write-Output "bad login -> $($_.Exception.Response.StatusCode.value__)" }

try { Invoke-RestMethod -Uri "$base/tasks" | Out-Null; Write-Output 'no-token list: NO ERROR (BAD)' }
catch { Write-Output "no-token list -> $($_.Exception.Response.StatusCode.value__)" }

# ---- tasks ----
$c = Invoke-RestMethod -Uri "$base/tasks" -Method Post -ContentType 'application/json' -Headers (AH $t1) -Body (J @{ title='Fire task'; description='fire desc'; status='TODO' })
$id = [string]$c.id
Write-Output "create ok: id=$id status=$($c.status)"

try { Invoke-RestMethod -Uri "$base/tasks" -Method Post -ContentType 'application/json' -Headers (AH $t1) -Body (J @{ title=''; description='x'; status='DONE' }) | Out-Null; Write-Output 'invalid create: NO ERROR (BAD)' }
catch { Write-Output "invalid create -> $($_.Exception.Response.StatusCode.value__)" }

Write-Output "list count: $((@( (Invoke-RestMethod -Uri "$base/tasks" -Headers (AH $t1)) )).Count)"
Write-Output "status DONE count: $((@( (Invoke-RestMethod -Uri "$base/tasks?status=DONE" -Headers (AH $t1)) )).Count)"
Write-Output "search 'fire' count: $((@( (Invoke-RestMethod -Uri "$base/tasks?search=fire" -Headers (AH $t1)) )).Count)"

Write-Output '-- update --'
$u = Invoke-RestMethod -Uri "$base/tasks/$id" -Method Put -ContentType 'application/json' -Headers (AH $t1) -Body (J @{ title='Fire task UPD'; description='d2'; status='DONE' })
Write-Output "  updated status=$($u.status)"

Write-Output '-- second user cannot touch --'
$r2 = Reg @{ email='fireother@test.com'; fullName='Fire Other'; password='secret123' }
$t2 = $r2.token
try { Invoke-RestMethod -Uri "$base/tasks/$id" -Method Get -Headers (AH $t2) | Out-Null; Write-Output '  cross get: NO ERROR (BAD)' }
catch { Write-Output "  cross get -> $($_.Exception.Response.StatusCode.value__)" }

Write-Output '-- delete --'
Invoke-RestMethod -Uri "$base/tasks/$id" -Method Delete -Headers (AH $t1) | Out-Null
Write-Output "  final list count: $((@( (Invoke-RestMethod -Uri "$base/tasks" -Headers (AH $t1)) )).Count)"

Write-Output 'SMOKE-TEST-COMPLETE'