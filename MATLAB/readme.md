## Folder structure
The following is a description of folders and files

```
MATLAB        	   				
├── ACAD   		   				
	├── hyperACAD.m      					<-- ACAD algorithm 			
	├── hyperRXR.m       					<--	RX anomaly with R matrix				
├── ACER_exclude_targets 				
	├── hyperAceR_NT.m	    				<-- ACER algorithm using correlation matrix formed of non-target pixels
	├── hyperAceR_RTA_PI.m  				<-- Real-time adaptation using pseudoinverse and correlation matrix updating, with exclusion of target pixels based on mean			 				
	├── hyperAceR_RTA_SM_I.m				<-- Real time ShermanMorrison updating with initial identity matrix and target exclusion (from R and mean)
├── ASMF				
	├── hyperASMF.m	 						<-- ASMF algorithm (CEM+RX)
├── CEM_exclude_targets				
	├── hyperCem_NT.m						<-- CEM with all targets excluded from R based on gt
	├── hyperCem_RTA0x.m					<-- Real time ShermanMorrison updating with initial pseudoinverse matrix and target exclusion	
	├── hyperCem_SBSSM.m					<-- Real time ShermanMorrison updating with initial identity matrix (and added restreaming)	  
├── Real_time_testing				
	├── figures.m	      					<-- Creates figures displaying MCC, VIS, AUC based on testPCA.m resulting struct
	├── td_run.m	   						<-- Used to run algorithms
	├── testInit.m	    					<-- Setup test algorithms and other preferences	
	├── testPCA.m	    					<-- Should run this script to test detection performance	
├── Results_ACE								<-- Some results
├── SM_FP_testing	
