 perl ../Step1_data_transform.pl raw.data.matrix.csv  >data.matrix.format
 perl ../Step2_determine_variable_type.pl data.matrix.format variable.inital.types /data/Public_tools/R-4.0.2/bin/Rscript >data.matrix.format.newtype
perl ../Step3_two_variables_correlation.pl data.matrix.format.newtype data.matrix.format.newtype.correlated /data/Public_tools/R-4.0.2/bin/Rscript
