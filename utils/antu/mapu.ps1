# Chequear si se encuentra el archivo de entrada para el SP de PostgreSQL, si lo encuentra, lo elimina
$archivo = ".\ingreso.csv"

$ExisteIngreso = Test-Path $archivo

If ($ExisteIngreso -eq $True) {
  Remove-Item -Path $archivo
}

# Cambia los caracteres Ñ y ñ por #, en el primer archivo de paso [TWSCPLST.PRUEBA1.txt.out]
$filename=".\TWSCPLST.PRUEBA1.txt"
$outputfile="$filename" + ".out"
Get-Content $filename | Foreach-object {
    $_ -replace 'Ñ', '#' `
       -replace 'ñ', '#' `
} | Set-Content $outputfile

# Elimina el archivo de entrada enviado desde Z
Remove-Item -Path .\TWSCPLST.PRUEBA1.txt

# Cambia la codificación de los datos, en un segundo archivo de paso [TWS-UTF8.txt]
Get-Content .\TWSCPLST.PRUEBA1.txt.out | Select-Object -SkipLast 1 | Set-Content TWS-UTF8.txt -Encoding UTF8

# Renombra el segundo archivo de paso, dejándolo con extensión .CSV [ingreso.csv]
Rename-Item -Path .\TWS-UTF8.txt -NewName "ingreso.csv"

# Elimina el primer archivo de paso [TWSCPLST.PRUEBA1.txt.out]
Remove-Item -Path .\TWSCPLST.PRUEBA1.txt.out
