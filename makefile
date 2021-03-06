SRC=src
TEST=tests
VPATH=.:$(SRC):$(SRC)/nkmp:$(SRC)/sw:$(TEST)

FC=ifort -O3 -mkl -nocheck -inline-level=2 -shared-intel -mcmodel=medium -xSSE4.2 -ipo -openmp

LOBJS=model_sw_t.o model_nkmp.o TemperedParticleFilter.o other_filters.o
# ifdef CONDA_BUILD
LIB=$(CONDA_PREFIX)/lib
INC=$(CONDA_PREFIX)/include
# else
#LIB=$(HOME)/anaconda3/lib
#INC=$(HOME)/anaconda3/include
CONDA_BUILD=0
# endif				
export SRC_DIR='.'
FPP=fypp -m os -f none
FRUIT=-I$(INC)/fruit -L$(LIB) -lfruit
FLAP=-I$(INC)/flap -L$(LIB) -lflap
FORTRESS=-I$(INC)/fortress -L$(LIB) -lfortress
JSON=-I$(INC)/json-fortran -L$(LIB)/json-fortran -ljsonfortran
LAPACK=-lopenblas 
SIMDIR = ~/tmp
SIMS= $(SIMDIR)/output_states_bootstrap_moderation.json	\
$(SIMDIR)/output_states_tpf_40k_r2_moderation.json \
$(SIMDIR)/output_states_tpf_40k_r3_moderation.json \
$(SIMDIR)/output_states_tpf_4k_r2_moderation.json \
$(SIMDIR)/output_states_tpf_4k_r3_moderation.json

%.o : %.f90
	$(FPP) -DCONDA_BUILD=$(CONDA_BUILD) -DGFORTRAN $< $(notdir $(basename $<))_tmp.f90
	$(FC) $(FRUIT) $(FLAP) $(FORTRESS) $(JSON) -fPIC -fopenmp -c $(notdir $(basename $<)_tmp.f90) -o $(notdir $(basename $<)).o
	rm $(notdir $(basename $<))_tmp.f90

tpf_driver_tmp.f90 : tpf_driver.f90
	$(FPP) -DCONDA_BUILD=$(CONDA_BUILD) -DGFORTRAN $< $(notdir $(basename $<))_tmp.f90

tpf_driver: tpf_driver_tmp.f90 $(LOBJS)
	$(FC) $^  $(FRUIT) $(FORTRESS) $(FLAP) $(JSON)  -o $@
	rm tpf_driver_tmp.f90
	mkdir -p bin
	cp tpf_driver bin
test_driver: test_driver.f90 $(LOBJS) test_nkmp.o
	$(FC) $^  $(FRUIT) $(FORTRESS) $(FLAP) $(JSON) -o $@

fig_std:
	cd src && ipython tpf_std_filtered_state.py $(SIMS)

fig_bspf:
	cd src && python tpf_evolution_figures.py $(SIMDIR)/output_states_bootstrap.json --output ../../paper/figures/fig_bspf_2008Q4.pdf


test:
	python conda/run_test.py

clean:
	rm -f *.o *.mod
