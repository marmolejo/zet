SOURCES=tb_fmlbrg.v $(wildcard ../rtl/*.v)

all: fmlbrg

fmlbrg: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f verilog.log

.PHONY: clean fmlbrg
