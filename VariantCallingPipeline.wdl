workflow VariantCallingPipeline_Normal {
	
	## Run on Normal sample
	RenameBAM
	M1 for SNVs
	Filter M1 using vcftools
	M2 for indels
	Filter M2 using vcftools
	
}

workflow Oncotate and Filter {
	Gather M1, M2 using GATK CombineVariants
	Oncotate M3 = M1 | M2
	FilterGermline on M3	
}

updatePoNs {
	updatePoN M1
	updatePoN M2
}


## Workflow for updating PoN using all normals
