del \tb3\*.*
xcopy *.* \tb3
del \tb3\tool\*.*
xcopy tool \tb3\tool
del \tb3\ali6117\*.*
xcopy ali6117 \tb3\ali6117
del \tb3\ali1487\*.*
xcopy ali1487 \tb3\ali1487
pz -arp %1 \tb3\*.*
