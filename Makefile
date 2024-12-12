ifndef MODULE
$(error MODULE is not set)
endif

.PHONY: all compile execute verify clean

all: compile verify

compile: $(MODULE)_tb.vvp

$(MODULE)_tb.vvp:
	@echo "Changing directory to $(MODULE) and compiling"
	cd $(MODULE) && iverilog -o $(MODULE)_tb.vvp -g2012 -I. $(MODULE)_pkg.sv $(MODULE)_tb.sv

execute: $(MODULE)_tb.vcd

$(MODULE)_tb.vcd: $(MODULE)_tb.vvp
	@echo "Changing directory to $(MODULE) and executing"
	cd $(MODULE) && vvp $(MODULE)_tb.vvp

verify: compile
	@echo "Changing directory to $(MODULE) and verifying"
	cd $(MODULE) && vvp $(MODULE)_tb.vvp | python3 validate.py

clean::
	@echo "Changing directory to $(MODULE) and cleaning"
	cd $(MODULE) && rm -fv *.vcd *.vvp