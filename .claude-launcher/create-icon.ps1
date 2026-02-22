Add-Type -AssemblyName System.Drawing

$sizes = @(16, 32, 48, 64, 128, 256)
$icoPath = "$env:USERPROFILE\.claude-launcher-icon.ico"

# Create a 256x256 bitmap
$bmp = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'

# Background - dark rounded rect
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(24, 24, 27))
$g.FillRectangle($bgBrush, 0, 0, 256, 256)

# Orange gradient circle
$orangeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 131, 58))
$g.FillEllipse($orangeBrush, 28, 28, 200, 200)

# Inner lighter circle
$lightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 166, 99))
$g.FillEllipse($lightBrush, 58, 58, 140, 140)

# Terminal prompt >_
$font = New-Object System.Drawing.Font("Consolas", 72, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(24, 24, 27))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = "Center"
$sf.LineAlignment = "Center"
$rect = New-Object System.Drawing.RectangleF(0, 0, 256, 256)
$g.DrawString(">_", $font, $textBrush, $rect, $sf)

$g.Dispose()

# Save as ICO using MemoryStream
$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $ms.ToArray()
$ms.Dispose()
$bmp.Dispose()

# Build ICO file manually (single 256x256 PNG entry)
$icoStream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter($icoStream)

# ICO header
$writer.Write([UInt16]0)      # reserved
$writer.Write([UInt16]1)      # type: icon
$writer.Write([UInt16]1)      # count: 1 image

# ICO directory entry
$writer.Write([byte]0)         # width (0 = 256)
$writer.Write([byte]0)         # height (0 = 256)
$writer.Write([byte]0)         # color palette
$writer.Write([byte]0)         # reserved
$writer.Write([UInt16]1)      # color planes
$writer.Write([UInt16]32)     # bits per pixel
$writer.Write([UInt32]$pngBytes.Length)  # size of PNG data
$writer.Write([UInt32]22)     # offset (6 header + 16 entry = 22)

# PNG data
$writer.Write($pngBytes)

$writer.Close()
$icoStream.Close()

Write-Host "Icon created at: $icoPath"
