The project website is no loger avaialble and only can be found in Web Archive.  

## Useful links:  

1. Overview : https://web.archive.org/web/20191112072251/http://zet.aluzina.org/index.php/Zet_processor  
2. Source Code (Version 1.3.1) : https://web.archive.org/web/20191112072251/http://zet.aluzina.org/images/3/32/Zet-1.3.1.zip
3. DE1 Installation Guide : https://web.archive.org/web/20191030135504/http://zet.aluzina.org/index.php/Altera_DE1_Installation_guide  
4. OpenCores page : https://opencores.org/projects/zet86 
5. Pictures : https://web.archive.org/web/20190518194322/http://zet.aluzina.org/index.php/Pictures

## Differences between GIT source and Web Source 1.3.1 :  

Some files seems to be missing when comparing two source codes using  
`robocopy I:\x\Zet-1.3.1-Archive I:\ZetCPU\zet-master-new\zet-master /MIR /FP /NDL /NP /L > DIR_DIFF.txt`  
which leads to compilation errors with Quartus II.  

The files differences are shown in "DIR_DIFF.txt"     

Source : I:\x\Zet-1.3.1-Archive\  <= Source Code (Version 1.3.1) from Web Archive  
Dest : I:\ZetCPU\zet-master-new\zet-master\  <= Forked GitHub Repo  

## Tested Quartus II version:     

Quartus II 13.0.1 64-Bit Version Build 232 06/12/2013 SJ Web Edition (Service Pack Installed : 1)  
Downloaded from:  
https://www.intel.com/content/www/us/en/software-kit/711791/intel-quartus-ii-web-edition-design-software-version-13-0sp1-for-windows.html  
