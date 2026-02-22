Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Config ---
# Support both \\wsl$ and \\wsl.localhost paths
$wslRoot = if (Test-Path "\\wsl.localhost\Ubuntu") { "\\wsl.localhost\Ubuntu" } else { "\\wsl$\Ubuntu" }
$configPath = "$wslRoot\home\hike-\.claude-launcher\projects.json"
$projectsDir = "$wslRoot\home\hike-\ClaudeProjects"
$wslProjectsDir = "/home/hike-/ClaudeProjects"
$script:projects = New-Object System.Collections.ArrayList

function Load-Projects {
    $script:projects = New-Object System.Collections.ArrayList
    if (Test-Path $configPath) {
        try {
            $json = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($json.projects) {
                foreach ($p in $json.projects) {
                    if ($p -ne $null -and $p.name -ne $null) {
                        [void]$script:projects.Add($p)
                    }
                }
            }
        } catch {}
    }
    # Auto-detect new projects from ClaudeProjects folder
    Auto-Detect-Projects
}

function Auto-Detect-Projects {
    if (-not (Test-Path $projectsDir)) { return }
    $existingPaths = @()
    foreach ($p in $script:projects) {
        $existingPaths += $p.path
    }
    $changed = $false
    Get-ChildItem -Path $projectsDir -Directory | ForEach-Object {
        $wslPath = "$wslProjectsDir/$($_.Name)"
        if ($existingPaths -notcontains $wslPath) {
            $newProject = [PSCustomObject]@{
                name = $_.Name
                path = $wslPath
            }
            [void]$script:projects.Add($newProject)
            $changed = $true
        }
    }
    if ($changed) { Save-Projects }
}

function Save-Projects {
    $arr = @()
    foreach ($p in $script:projects) {
        $arr += @{ name = $p.name; path = $p.path }
    }
    $json = @{ projects = $arr } | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($configPath, $json, [System.Text.Encoding]::UTF8)
}

# --- Icon Generation ---
function Create-Icon {
    $bmp = New-Object System.Drawing.Bitmap(64, 64)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::FromArgb(30, 30, 30))

    $brush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 131, 58))
    $g.FillEllipse($brush1, 8, 8, 48, 48)

    $font = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
    $brushW = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString(">_", $font, $brushW, 14, 16)

    $g.Dispose()
    $iconHandle = $bmp.GetHicon()
    return [System.Drawing.Icon]::FromHandle($iconHandle)
}

$icon = Create-Icon
Load-Projects

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Claude Code Launcher"
$form.Size = New-Object System.Drawing.Size(520, 480)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Icon = $icon
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# --- Title Label ---
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Claude Code Launcher"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(232, 131, 58)
$lblTitle.Size = New-Object System.Drawing.Size(480, 40)
$lblTitle.Location = New-Object System.Drawing.Point(20, 15)
$lblTitle.TextAlign = "MiddleCenter"
$form.Controls.Add($lblTitle)

# --- Subtitle ---
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Selecione um projeto para abrir com Claude"
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
$lblSub.Size = New-Object System.Drawing.Size(480, 25)
$lblSub.Location = New-Object System.Drawing.Point(20, 55)
$lblSub.TextAlign = "MiddleCenter"
$form.Controls.Add($lblSub)

# --- Project List ---
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(460, 240)
$listBox.Location = New-Object System.Drawing.Point(20, 90)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(39, 39, 42)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.BorderStyle = "None"
$listBox.Font = New-Object System.Drawing.Font("Cascadia Code, Consolas", 11)
$listBox.ItemHeight = 28
$form.Controls.Add($listBox)

# --- Refresh list display ---
function Refresh-List {
    $listBox.Items.Clear()
    foreach ($p in $script:projects) {
        $listBox.Items.Add("  $($p.name)  -  $($p.path)")
    }
    if ($script:projects.Count -eq 0) {
        $listBox.Items.Add("  (nenhum projeto - clique 'Adicionar')")
    }
}
Refresh-List

# --- Button Style Helper ---
function New-StyledButton($text, $x, $y, $w, $bgColor) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size($w, 40)
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bgColor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = "Hand"
    return $btn
}

$btnY = 345

# --- Add Button ---
$btnAdd = New-StyledButton "Adicionar Projeto" 20 $btnY 150 ([System.Drawing.Color]::FromArgb(34, 139, 34))
$btnAdd.Add_Click({
    $nameForm = New-Object System.Windows.Forms.Form
    $nameForm.Text = "Novo Projeto"
    $nameForm.Size = New-Object System.Drawing.Size(420, 220)
    $nameForm.StartPosition = "CenterParent"
    $nameForm.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 27)
    $nameForm.ForeColor = [System.Drawing.Color]::White
    $nameForm.FormBorderStyle = "FixedDialog"
    $nameForm.MaximizeBox = $false
    $nameForm.MinimizeBox = $false
    $nameForm.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $nameForm.Icon = $icon

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = "Nome do projeto:"
    $lbl1.Location = New-Object System.Drawing.Point(15, 15)
    $lbl1.Size = New-Object System.Drawing.Size(370, 25)
    $nameForm.Controls.Add($lbl1)

    $txtName = New-Object System.Windows.Forms.TextBox
    $txtName.Location = New-Object System.Drawing.Point(15, 42)
    $txtName.Size = New-Object System.Drawing.Size(370, 28)
    $txtName.BackColor = [System.Drawing.Color]::FromArgb(39, 39, 42)
    $txtName.ForeColor = [System.Drawing.Color]::White
    $txtName.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $nameForm.Controls.Add($txtName)

    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Text = "Caminho WSL (ex: /home/hike-/meu-projeto):"
    $lbl2.Location = New-Object System.Drawing.Point(15, 78)
    $lbl2.Size = New-Object System.Drawing.Size(370, 25)
    $nameForm.Controls.Add($lbl2)

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(15, 105)
    $txtPath.Size = New-Object System.Drawing.Size(370, 28)
    $txtPath.BackColor = [System.Drawing.Color]::FromArgb(39, 39, 42)
    $txtPath.ForeColor = [System.Drawing.Color]::White
    $txtPath.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $nameForm.Controls.Add($txtPath)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "Salvar"
    $btnOK.Size = New-Object System.Drawing.Size(100, 35)
    $btnOK.Location = New-Object System.Drawing.Point(285, 142)
    $btnOK.FlatStyle = "Flat"
    $btnOK.FlatAppearance.BorderSize = 0
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(232, 131, 58)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnOK.DialogResult = "OK"
    $nameForm.Controls.Add($btnOK)
    $nameForm.AcceptButton = $btnOK

    $result = $nameForm.ShowDialog()
    if ($result -eq "OK" -and $txtName.Text.Trim() -ne "" -and $txtPath.Text.Trim() -ne "") {
        $newPath = $txtPath.Text.Trim()
        if (-not $newPath.StartsWith("/")) {
            [System.Windows.Forms.MessageBox]::Show("O caminho deve ser absoluto (comecar com /).`nExemplo: /home/hike-/meu-projeto", "Erro", "OK", "Error")
        } else {
            $wslCheck = "$wslRoot" + ($newPath -replace "/", "\")
            if (-not (Test-Path $wslCheck)) {
                [System.Windows.Forms.MessageBox]::Show("Pasta nao encontrada: $newPath`nVerifique se o caminho existe no WSL.", "Erro", "OK", "Error")
            } else {
                $newProject = [PSCustomObject]@{
                    name = $txtName.Text.Trim()
                    path = $newPath
                }
                [void]$script:projects.Add($newProject)
                Save-Projects
                Refresh-List
            }
        }
    }
    $nameForm.Dispose()
})
$form.Controls.Add($btnAdd)

# --- Delete Button ---
$btnDel = New-StyledButton "Deletar Projeto" 180 $btnY 150 ([System.Drawing.Color]::FromArgb(180, 40, 40))
$btnDel.Add_Click({
    $idx = $listBox.SelectedIndex
    if ($idx -ge 0 -and $idx -lt $script:projects.Count) {
        $name = $script:projects[$idx].name
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Tem certeza que deseja remover '$name'?`n(Isso NAO deleta os arquivos do projeto)",
            "Confirmar",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($confirm -eq "Yes") {
            $script:projects.RemoveAt($idx)
            Save-Projects
            Refresh-List
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Selecione um projeto primeiro.", "Aviso", "OK", "Information")
    }
})
$form.Controls.Add($btnDel)

# --- Launch Button ---
$btnLaunch = New-StyledButton "Abrir com Claude" 340 $btnY 140 ([System.Drawing.Color]::FromArgb(232, 131, 58))
$btnLaunch.Add_Click({
    $idx = $listBox.SelectedIndex
    if ($idx -ge 0 -and $idx -lt $script:projects.Count) {
        $projPath = $script:projects[$idx].path
        if (-not $projPath.StartsWith("/")) {
            [System.Windows.Forms.MessageBox]::Show("Caminho invalido (nao e absoluto): $projPath`nRemova e adicione o projeto novamente.", "Erro", "OK", "Error")
            return
        }
        $wslPath = "$wslRoot" + ($projPath -replace "/", "\")
        if (-not (Test-Path $wslPath)) {
            [System.Windows.Forms.MessageBox]::Show("Pasta nao encontrada: $projPath`nVerifique se o projeto existe no WSL.", "Erro", "OK", "Error")
            return
        }
        $escapedPath = $projPath -replace "'", "'\\''"
        Start-Process "wt.exe" -ArgumentList "wsl.exe -d Ubuntu -- bash -lc `"cd '$escapedPath' && /home/hike-/.local/bin/claude`""
        $form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Selecione um projeto primeiro.", "Aviso", "OK", "Information")
    }
})
$form.Controls.Add($btnLaunch)

# --- Double click to launch ---
$listBox.Add_DoubleClick({
    $btnLaunch.PerformClick()
})

# --- Footer ---
$lblFooter = New-Object System.Windows.Forms.Label
$lblFooter.Text = "Duplo clique ou selecione + 'Abrir com Claude'"
$lblFooter.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$lblFooter.Size = New-Object System.Drawing.Size(460, 25)
$lblFooter.Location = New-Object System.Drawing.Point(20, 400)
$lblFooter.TextAlign = "MiddleCenter"
$lblFooter.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($lblFooter)

# --- Show ---
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
$form.Dispose()
