diff resultsNewC/boxbox.out     (nim r -d:testsHighPrecision boxbox | psub)
diff resultsNewC/boxcyl.out     (nim r -d:testsHighPrecision boxcyl | psub)
diff resultsNewC/cylcyl.out     (nim r -d:testsHighPrecision cylcyl | psub)
diff resultsNewC/mpr_boxbox.out (nim r -d:testsHighPrecision mpr_boxbox | psub)
diff resultsNewC/mpr_boxcyl.out (nim r -d:testsHighPrecision mpr_boxcyl | psub)
diff resultsNewC/mpr_cylcyl.out (nim r -d:testsHighPrecision mpr_cylcyl | psub)
nim r -d:testsHighPrecision spheresphere

nim r boxbox
nim r boxcyl
nim r cylcyl
nim r mpr_boxbox
nim r mpr_boxcyl
nim r mpr_cylcyl
nim r spheresphere
