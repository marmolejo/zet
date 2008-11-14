all: Zet.ace

Zet.ace: tmp/kotku_ml403.bit
	(cd tmp/ && ../../ace/ml40x_bit2ace kotku_ml403.bit ../Zet.ace ../../ace/)

tmp/mult.v: mult.xco
	mkdir -p tmp
	(cd tmp/ && coregen -b ../mult.xco)

tmp/kotku_ml403.ngc: tmp/mult.v kotku.prj kotku.xst
	(cd tmp/ && xst -ifn ../kotku.xst)

tmp/kotku_ml403.ngd: tmp/kotku_ml403.ngc ml403.ucf tmp/mult.ngc
	(cd tmp/ && ngdbuild -uc ../ml403.ucf kotku_ml403.ngc)

tmp/kotku_ml403.ncd: tmp/kotku_ml403.ngd
	(cd tmp/ && map kotku_ml403.ngd)

tmp/kotku_ml403-par.ncd: tmp/kotku_ml403.ncd
	(cd tmp/ && par -w kotku_ml403.ncd kotku_ml403-par.ncd)

tmp/kotku_ml403.bit: tmp/kotku_ml403-par.ncd
	(cd tmp/ && bitgen -w kotku_ml403-par.ncd kotku_ml403.bit)

kotku.bit: tmp/kotku_ml403.bit
	cp tmp/kotku_ml403.bit ./kotku.bit

clean:
	rm -fR tmp/

dist-clean:
	rm -fR Zet.ace kotku.bit tmp/
