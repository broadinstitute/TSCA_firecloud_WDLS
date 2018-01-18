workflow FilterGermlineVariants_NormalSample {
	### Sample
	String normal_id
	File mutect1_oncotated_maf
	File mutect1_callstats
	File mutect2_oncotated_maf

	### References
	File tcga_hotspots

	call filterGermlineEvents {
		input:
		sample_id=normal_id,
		mutect1_oncotated_maf=mutect1_oncotated_maf,
		mutect1_callstats=mutect1_callstats,
		mutect2_oncotated_maf=mutect2_oncotated_maf,
		tcga_hotspots=tcga_hotspots
	}

	output {
		File filtered_variants=filterGermlineEvents.filtered_variants
		File clear_snvs=filterGermlineEvents.clear_snvs
	}
}

task filterGermlineEvents {
	String sample_id
	File mutect1_oncotated_maf
	File mutect1_callstats
	File mutect2_oncotated_maf
	File tcga_hotspots

	command <<<
		python /TSCA/filter_variants.py \
			--sample_type Normal \
			--sample_id ${sample_id} \
			--mutect1_oncotated_maf ${mutect1_oncotated_maf} \
			--mutect1_callstats ${mutect1_callstats} \
			--mutect2_oncotated_maf ${mutect2_oncotated_maf} \
			--TCGAhotspots_path ${tcga_hotspots} \
			--match_normal_sample_id NA
	>>>

	runtime {
	    docker: "mcadosch/tsca:latest"
	    memory: "4 GB"
	    disks: "local-disk 20 SSD"
	}
	output {
	    File filtered_variants="${sample_id}.filtered.variants.tsv"
	    File clear_snvs=read_string("clear_snvs.txt")
	}
}
