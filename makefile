################################################################################
# Makefile - frame_aligner UVM environment
################################################################################

TEST ?= my_test

# ------------------------------------------------------------------------------
# VCS compile options
# ------------------------------------------------------------------------------

VCS = vcs -sverilog -full64 -ntb_opts uvm \
      +incdir+tb+tb/sequences \
      -timescale="1ns/1ns" \
      -kdb -debug_acc+all \
      -f dut.fl \
      -o frame.simv

# Normal simulation command
SIM = ./frame.simv +UVM_TESTNAME=$(TEST)

# Coverage settings
COV_DB     = coverage.vdb
COV_REPORT = coverage_report
COV_FLAGS  = -cm line+cond+tgl+branch+fsm+assert

################################################################################
# Targets
################################################################################

# Default:
# make
# Compile and open normal simulation GUI
all: gui


# ------------------------------------------------------------------------------
# Compile only
# ------------------------------------------------------------------------------
comp:
	$(VCS)


# ------------------------------------------------------------------------------
# Normal simulation with GUI
# ------------------------------------------------------------------------------
gui: comp
	$(SIM) -gui &


# ------------------------------------------------------------------------------
# Normal simulation without GUI
# ------------------------------------------------------------------------------
run: comp
	$(SIM)


# ------------------------------------------------------------------------------
# Functional Coverage + Code Coverage
#
# Includes:
#   Functional Coverage - covergroups / coverpoints / bins / crosses
#
#   Code Coverage:
#       line
#       condition
#       toggle
#       branch
#       FSM
# ------------------------------------------------------------------------------
cov:
	$(VCS) $(COV_FLAGS) -cm_dir $(COV_DB)
	$(SIM) $(COV_FLAGS) -cm_dir $(COV_DB)
	urg -dir $(COV_DB) -report $(COV_REPORT) -format both
	@echo "------------------------------------------------"
	@echo "Coverage completed"
	@echo "Coverage database: $(COV_DB)"
	@echo "Coverage report:   $(COV_REPORT)"
	@echo "------------------------------------------------"


# ------------------------------------------------------------------------------
# Run Coverage and open it in Verdi
# ------------------------------------------------------------------------------
cov_gui: cov
	verdi -cov -covdir $(COV_DB) &


# ------------------------------------------------------------------------------
# Clean generated files
# ------------------------------------------------------------------------------
clean:
	rm -rf csrc \
	       frame.simv \
	       frame.simv.daidir \
	       *.vdb \
	       $(COV_REPORT) \
	       verdi_config_file* \
	       *.fsdb \
	       ucli.key
	@echo "Cleanup complete."


.PHONY: all comp gui run cov cov_gui clean
