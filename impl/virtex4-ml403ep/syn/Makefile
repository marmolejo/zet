all: kotku.bit

tmp/mult.v: mult.xco
	mkdir -p tmp
	(cd tmp/ && coregen -b ../mult.xco)

tmp/kotku.ngc: tmp/mult.v kotku.prj kotku.xst
	(cd tmp/ && xst -ifn ../kotku.xst)

tmp/kotku.ngd: tmp/kotku.ngc ml403.ucf tmp/mult.ngc
	(cd tmp/ && ngdbuild -uc ../ml403.ucf -sd .. kotku.ngc)

tmp/kotku.ncd: tmp/kotku.ngd
	(cd tmp/ && map kotku.ngd)

tmp/kotku-par.ncd: tmp/kotku.ncd
	(cd tmp/ && par -w kotku.ncd kotku-par.ncd)

tmp/kotku.bit: tmp/kotku-par.ncd
	(cd tmp/ && bitgen -w kotku-par.ncd kotku.bit)

kotku.bit: tmp/kotku.bit
	cp tmp/kotku.bit .

clean:
	rm -fR tmp/
