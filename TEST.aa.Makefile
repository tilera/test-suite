##===- test/Programs/TEST.aa.Makefile ----------------------*- Makefile -*-===##
#
# This recursively traverses the programs, computing the precision of various
# alias analysis passes on the programs.
#
##===----------------------------------------------------------------------===##

# We require the programs to be linked with libdummy
include $(LEVEL)/test/Programs/Makefile.dummylib

ifdef ENABLE_OPTIMIZED
AND_LIB := $(LIBRELEASE)/libAndersens.so
else
AND_LIB := $(LIBDEBUG)/libAndersens.so
endif

AA_IMPLS := basic steens-fi andersens steens ds-fi ds

SUFFIX = -aa-eval -time-passes -disable-output -disable-verify < $< 2> $@

$(PROGRAMS_TO_TEST:%=Output/%.aa.basic.txt): \
Output/%.aa.basic.txt: Output/%.lib.bc $(LOPT)
	-$(LOPT) -basicaa $(SUFFIX)

$(PROGRAMS_TO_TEST:%=Output/%.aa.steens-fi.txt): \
Output/%.aa.steens-fi.txt: Output/%.lib.bc $(LOPT)
	-$(LOPT) -steens-aa -disable-ds-field-sensitivity $(SUFFIX)

$(PROGRAMS_TO_TEST:%=Output/%.aa.steens.txt): \
Output/%.aa.steens.txt: Output/%.lib.bc $(LOPT)
	-$(LOPT) -steens-aa $(SUFFIX)

$(PROGRAMS_TO_TEST:%=Output/%.aa.andersens.txt): \
Output/%.aa.andersens.txt: Output/%.lib.bc $(LOPT) $(AND_LIB)
	-$(LOPT) -load $(AND_LIB) -andersens-aa $(SUFFIX)

$(PROGRAMS_TO_TEST:%=Output/%.aa.ds-fi.txt): \
Output/%.aa.ds-fi.txt: Output/%.lib.bc $(LOPT)
	-$(LOPT) -ds-aa -disable-ds-field-sensitivity $(SUFFIX)

$(PROGRAMS_TO_TEST:%=Output/%.aa.ds.txt): \
Output/%.aa.ds.txt: Output/%.lib.bc $(LOPT)
	-$(LOPT) -ds-aa $(SUFFIX)


AA_OUTPUTS := $(addsuffix .txt, $(AA_IMPLS))

# Overall tests: just run subordinate tests
$(PROGRAMS_TO_TEST:%=Output/%.$(TEST).report.txt): \
Output/%.$(TEST).report.txt: $(addprefix Output/%.aa., $(AA_OUTPUTS))
	-$(LDIS) < Output/$*.lib.bc | grep ^declare > $@
	@-for output in $(addprefix Output/$*.aa., $(AA_OUTPUTS)); do \
		echo -n "$$output:" >> $@; \
		grep Summary $$output >> $@; \
		echo "" >> $@; \
		echo -n "$$output: " >> $@; \
		grep "Total Execution" $$output >> $@; \
		echo "" >> $@; \
	done

$(PROGRAMS_TO_TEST:%=test.$(TEST).%): \
test.$(TEST).%: Output/%.$(TEST).report.txt
	@echo "---------------------------------------------------------------"
	@echo ">>> ========= '$*' Program"
	@echo "---------------------------------------------------------------"
	@cat $<

# Define REPORT_DEPENDENCIES so that the report is regenerated if analyze or
# dummylib is updated.
#
REPORT_DEPENDENCIES := $(DUMMYLIB) $(LANALYZE) $(LOPT)
