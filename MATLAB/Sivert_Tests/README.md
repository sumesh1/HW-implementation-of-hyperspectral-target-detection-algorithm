## FILES

* **td_test_init.m** : Setting up the algorithms under test chosen by td_algs. Also set up q for dimensionality reduction.
* **test_all.m**	   : Testing chosen algorithms (td_test_init.m) and calculating MCC and visibility scores on full-dim data
* **test_all_mnf_green.m** : Testing chosen algorithms (td_test_init.m) and calculating MCC and visibility scores on MNF data
* **test_all_pca.m** : Testing chosen algorithms (td_test_init.m) and calculating MCC and visibility scores on PCA data
* **compute_summary_matrix.m** : creates figures from data generated using files above. Again td_algs variable has to be set as in td_test_init