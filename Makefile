
ifndef MODULE
$(error MODULE is not set)
endif

ifndef HDL
$(error HDL is not set)
endif


.PHONY: all compile execute verify clean


all: compile verify


compile: $(MODULE)_tb.out


# HDL-agnostic compilation
$(MODULE)_tb.out:
	@echo "Changing directory to $(MODULE) and compiling for $(HDL)"
	cd $(MODULE) && \
	if [ "$(HDL)" = "systemverilog" ]; then \
		iverilog -o $(MODULE)_tb.out -g2012 -I. $(MODULE)_pkg.sv $(MODULE)_tb.sv; \
	elif [ "$(HDL)" = "verilog" ]; then \
		iverilog -o $(MODULE)_tb.out -I. $(MODULE)_tb.v $(MODULE)_pkg.v; \
	elif [ "$(HDL)" = "vhdl" ]; then \
		ghdl -a $(MODULE)_tb.vhd && \
		ghdl -e $(MODULE)_tb && \
		ghdl -o $(MODULE)_tb.out -e $(MODULE)_tb; \
	else \
		echo "Unknown HDL: $(HDL)" && exit 1; \
	fi


execute: $(MODULE)_tb.vcd


$(MODULE)_tb.vcd: $(MODULE)_tb.out
	@echo "Changing directory to $(MODULE) and executing for $(HDL)"
	cd $(MODULE) && \
	if [ "$(HDL)" = "systemverilog" ] || [ "$(HDL)" = "verilog" ]; then \
		vvp $(MODULE)_tb.out; \
	elif [ "$(HDL)" = "vhdl" ]; then \
		ghdl -r $(MODULE)_tb --vcd=$(MODULE)_tb.vcd; \
	else \
		echo "Unknown HDL: $(HDL)" && exit 1; \
	fi


verify: compile
	@echo "Changing directory to $(MODULE) and verifying for $(HDL)"
	cd $(MODULE) && \
	if [ "$(HDL)" = "systemverilog" ] || [ "$(HDL)" = "verilog" ]; then \
		vvp $(MODULE)_tb.out | python3 validate.py; \
	elif [ "$(HDL)" = "vhdl" ]; then \
		ghdl -r $(MODULE)_tb --vcd=$(MODULE)_tb.vcd | python3 validate.py; \
	else \
		echo "Unknown HDL: $(HDL)" && exit 1; \
	fi


clean::
	@echo "Changing directory to $(MODULE) and cleaning"
	cd $(MODULE) && rm -fv *.vcd *.vvp *.out *.o *.cf *.ghw *.vcd *.vvp *.out *.o *.cf *.ghw