Устанавливать также как и gcdrom.sys, параметры те же.

1.Добавить в config.sys

device=<путь\>xgcdrom.sys /d:XGCD01 /Cn
 где
	/d:XGCD01 	- имя драйвера для MSCDEX (можно свое)
	/Cn		- n от 0 до 6, порядковый номер контроллера на шине PCI во время сканирования

2.Добавить в autoexec.bat

mscdex.exe /d:XGCD01

Пример:

В config.sys

device=c:\dos\xgcdrom.sys /d:XGCD01 /C0
device=c:\dos\xgcdrom.sys /d:XGCD02 /C1
device=c:\dos\xgcdrom.sys /d:XGCD03 /C2

В autoexec.bat

mscdex.exe /d:XGCD01 /d:XGCD02 /d:XGCD03

---------------------------------------------------------------------------

Install this driver like gcdrom.sys, parameters are the same

1.Add in config.sys line

device=<path>\xgcdrom.sys /d:XGCD01 /Cn
 where
	/d:XGCD01 	- device driver name for MSCDEX (you may use your own)
	/Cn		- n from 0 to 6 is ordinal number of scanned controller on PCI bus


2.Add in autoexec.bat line

mscdex.exe /d:XGCD01

Example:

In config.sys

device=c:\dos\xgcdrom.sys /d:XGCD01 /C0
device=c:\dos\xgcdrom.sys /d:XGCD02 /C1
device=c:\dos\xgcdrom.sys /d:XGCD03 /C2

In autoexec.bat

mscdex.exe /d:XGCD01 /d:XGCD02 /d:XGCD03

Regards,
lexapass 

http://lexapass.narod.ru