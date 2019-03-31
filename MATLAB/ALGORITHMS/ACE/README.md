## Target detection algorithms

* **hyperAce**: Performs the adaptive cosine/coherent estimator algorithm using covariance matrix
* **hyperAceR**: Performs the adaptive cosine/coherent estimator algorithm using correlation matrix
* **hyperAceR_SW_I**: Performs the adaptive cosine/coherent estimator algorithm MOVING ACE with a moving subset of pixels for correlation estimation - initial I
* **hyperAceR_SW_PI**: Performs the adaptive cosine/coherent estimator algorithm MOVING ACE with a moving subset of pixels for correlation estimation - initial pseudoinverse
* **hyperAceR_RT_PI**: Real-time adaptation using pseudoinverse and correlation matrix updating 
* **hyperAceR_RT_SM_I**: Real-time adaptation using Sherman-Morrison correlation matrix updating and I as initial
* **hyperAceR_RT_SM_PI**: Real-time adaptation using Sherman-Morrison correlation matrix updating and pseudoinverse as initial
* **hyperAceR_RTA_PI:** Real-time adaptation using pseudoinverse and correlation matrix updating, with exclusion of target pixels based on mean	
* **hyperAceR_SUB**: Performs the adaptive cosine/coherent estimator algorithm with correlation matrix using subset of rows/columns
* **hyperAceR_SUBRAND**: Performs the adaptive cosine/coherent estimator algorithm with correlation matrix using randomly selected subset of rows/columns

* **hyperAceR_FP**: Fixed point testing -- Implementation of hyperAceR in Fixed Point
* **hyperAceR_RT_SM_FP**: 	Fixed point testing -- Implementation of hyperAceR_SM_I in Fixed Point
