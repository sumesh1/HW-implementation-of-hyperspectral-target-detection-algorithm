# Hardware-Software codesign implementation of Adaptive Cosine estimator on Zynq-7000 development platform

## Folder structure

* C -> SW  - Full software solution of ACE, CEM and SAM algorithm on Zynq PS
* C -> HW/SW - C code for ACE implementation using accelerator on PL

* MATLAB - Matlab codes for testing algorithms

* SIMULATION_FILES - files used for simulating the accelerator design (based on Salinas scene pre-processed using PCA, reduced to 16 bands)

* VHDL - All design files and testbenches

* VIVADO_PROJECT - Folder for easy creation of project and block designs supported by tcl scripts
