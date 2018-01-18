## Mutation Calling workflow for tumor samples

workflow MutationCalling_Tumor {

	### Tumor sample
	String tumor_id
	File tumor_bam
	File tumor_bai

	### Normal Sample
	String? normal_id
	File? normal_bam
	File? normal_bai
	File? match_normal_variants
	### References
	File reference_fasta
	File reference_fasta_index
	File reference_fasta_dict
	File targets_interval_list
	
	# PoNs
	File pon_mutect1
	File pon_mutect2

	### Databases
	File dbsnp_vcf
	File cosmic_vcf
	File dbsnp_vcf_index
	File cosmic_vcf_index
	File gnomad_vcf
	File gnomad_vcf_index
	File tcga_hotspots

	### Executables
	File mutect_jar
	File gatk_jar

	### Parameters
	Int downsample_to_coverage
	Float fraction_contamination

	### Oncotator Resources
	String oncotator_docker
	File? onco_ds_tar_gz
	File? default_config_file

	call mutect1 {
		input:
		mutect_jar=mutect_jar,
		tumor_id=tumor_id,
		tumor_bam=tumor_bam,
		tumor_bai=tumor_bai,
		normal_id=normal_id,
		normal_bam=normal_bam,
		normal_bai=normal_bai,
		reference_fasta=reference_fasta,
		reference_fasta_index=reference_fasta_index,
		reference_fasta_dict=reference_fasta_dict,
		targets_interval_list=targets_interval_list,
		pon_mutect1=pon_mutect1,
		dbsnp_vcf=dbsnp_vcf,
		dbsnp_vcf_index=dbsnp_vcf_index,
		cosmic_vcf=cosmic_vcf,
		cosmic_vcf_index=cosmic_vcf_index,
		downsample_to_coverage=downsample_to_coverage,
		fraction_contamination=fraction_contamination
	}

	call mutect2 {
		input:
		gatk_jar=gatk_jar,
		reference_fasta=reference_fasta,
		reference_fasta_index=reference_fasta_index,
		reference_fasta_dict=reference_fasta_dict,
		targets_interval_list=targets_interval_list,
		dbsnp_vcf=dbsnp_vcf,
		dbsnp_vcf_index=dbsnp_vcf_index,
		cosmic_vcf=cosmic_vcf,
		cosmic_vcf_index=cosmic_vcf_index,
		tumor_id=tumor_id,
		tumor_bam=tumor_bam,
		tumor_bai=tumor_bai,
		normal_id=normal_id,
		normal_bam=normal_bam,
		normal_bai=normal_bai,
		pon_mutect2=pon_mutect2
	}

	call filter_vcfs {
		input:
		tumor_id=tumor_id,
		mutect1_vcf=mutect1.vcf,
		mutect2_vcf=mutect2.vcf
	}

	call oncotate {
	    input:
        mutect1_vcf=filter_vcfs.mutect1_filtered_vcf,
        mutect2_vcf=filter_vcfs.mutect2_filtered_vcf,
        tumor_id=tumor_id,
        oncotator_docker=oncotator_docker,
        onco_ds_tar_gz=onco_ds_tar_gz,
        default_config_file=default_config_file,
	}

	output {
		### MuTect1
		File mutect1_vcf = filter_vcfs.mutect1_filtered_vcf
		File mutect1_callstats = mutect1.callstats
		File mutect1_powerwig = mutect1.powerwig
		File mutect1_coveragewig = mutect1.coveragewig
		### MuTect1
		File mutect2_vcf = filter_vcfs.mutect2_filtered_vcf
		### Oncotator
		File mutect1_oncotated_maf=oncotate.mutect1_maf
		File mutect2_oncotated_maf=oncotate.mutect2_maf
	}
}


task mutect1 {
	File mutect_jar
	String tumor_id
	File tumor_bam
	File tumor_bai
	String? normal_id
	File? normal_bam
	File? normal_bai
	File reference_fasta
	File reference_fasta_index
	File reference_fasta_dict
	File pon_mutect1
	File targets_interval_list
	File dbsnp_vcf
	File cosmic_vcf
	File dbsnp_vcf_index
	File cosmic_vcf_index
	Int downsample_to_coverage
	Float fraction_contamination

	command <<<

		# Match normal exists
		if [ ${normal_id} != NA ]; then
		  echo "Running Mutect1 with match normal"
		  match_normal_name="--normal_sample_name ${normal_id}"
		  match_normal_bam="-I:normal ${normal_bam}"
		fi
	
		java -jar -Xmx4g ${mutect_jar} \
			-T MuTect \
			-R ${reference_fasta} \
			--tumor_sample_name ${tumor_id} \
			-I:tumor ${tumor_bam} \
			$match_normal_name \
			$match_normal_bam \
			--normal_panel ${pon_mutect1} \
			--dbsnp ${dbsnp_vcf} \
			--cosmic ${cosmic_vcf} \
			-L ${targets_interval_list} \
			--fraction_contamination ${fraction_contamination} \
			--downsample_to_coverage ${downsample_to_coverage} \
			--out ${tumor_id}.callstats.txt \
			--coverage_file ${tumor_id}.coverage.wig.txt \
			--power_file ${tumor_id}.power.wig.txt \
			--vcf ${tumor_id}.mutect1.vcf
	>>>

	runtime {
		docker: "dockerbase/java7:latest"
		memory: "7 GB"
		disks: "local-disk 100 HDD"
		preemptible_attempts: "3"
	}

	output {
		File callstats="${tumor_id}.callstats.txt"
		File powerwig="${tumor_id}.power.wig.txt"
		File coveragewig="${tumor_id}.coverage.wig.txt"
		File vcf="${tumor_id}.mutect1.vcf"
	}
}

task mutect2 {
	File gatk_jar
	File reference_fasta
	File reference_fasta_index
	File reference_fasta_dict
	File targets_interval_list
	File dbsnp_vcf
	File dbsnp_vcf_index
	File cosmic_vcf
	File cosmic_vcf_index
	String tumor_id
	File tumor_bam
	File tumor_bai
	String? normal_id
	File? normal_bam
	File? normal_bai
	File pon_mutect2

	command <<< 
	# Match normal exists
	if [ ${normal_id} != NA ]; then
	  echo "Running Mutect2 with match normal"
	  match_normal_option="-I:normal ${normal_bam}"
	fi

	java -jar ${gatk_jar} \
		-T MuTect2 \
		-R ${reference_fasta} \
		-I:tumor ${tumor_bam} \
		$match_normal_option \
		--dbsnp ${dbsnp_vcf} \
		--cosmic ${cosmic_vcf} \
		-L ${targets_interval_list} \
		-PON ${pon_mutect2} \
		-o ${tumor_id}.mutect2.vcf.gz
	>>>

	runtime {
	docker: "broadinstitute/genomes-in-the-cloud:2.3.1-1501706336"
	memory:  "16 GB"
	disks: "local-disk 50 HDD"
	preemptible_attempts: "3"
	}

	output {
		File vcf = "${tumor_id}.mutect2.vcf.gz"
		File vcf_index = "${tumor_id}.mutect2.vcf.gz.tbi"
	}
}

task filter_vcfs {
	String tumor_id
	File mutect1_vcf
	File mutect2_vcf

	command <<<
		# Filter variants that didn't pass MuTect 1 or 2 filters
		vcftools --vcf ${mutect1_vcf} --remove-filtered-all --recode --out ${tumor_id}.mutect1
		vcftools --gzvcf ${mutect2_vcf} --remove-filtered-all --recode --out ${tumor_id}.mutect2
	>>>

	runtime {
		docker: "biocontainers/vcftools:latest"
		memory: "8 GB"
		disks: "local-disk 4 HDD"
	}

	output {
		File mutect1_filtered_vcf="${tumor_id}.mutect1.recode.vcf"
		File mutect2_filtered_vcf="${tumor_id}.mutect2.recode.vcf"
	}
}

task oncotate {
    File mutect1_vcf
    File mutect2_vcf
    String tumor_id
    String oncotator_docker
    File? onco_ds_tar_gz
    File? default_config_file

    command <<<

        # fail if *any* command below (not just the last) doesn't return 0
        set -e

        mkdir onco_dbdir
        tar zxvf ${onco_ds_tar_gz} -C onco_dbdir --strip-components 1

        /root/oncotator_venv/bin/oncotator --db-dir onco_dbdir/ \
            -c $HOME/tx_exact_uniprot_matches.AKT1_CRLF2_FGFR1.txt  \
            -v ${mutect1_vcf} ${tumor_id}.mutect1.maf.annotated hg19 -i VCF -o TCGAMAF \
            --skip-no-alt --infer-onps --collapse-number-annotations \
            --log_name oncotator.log \
            ${"--default_config " + default_config_file}

        /root/oncotator_venv/bin/oncotator --db-dir onco_dbdir/ \
            -c $HOME/tx_exact_uniprot_matches.AKT1_CRLF2_FGFR1.txt  \
            -v ${mutect2_vcf} ${tumor_id}.mutect2.maf.annotated hg19 -i VCF -o TCGAMAF \
            --skip-no-alt --infer-onps --collapse-number-annotations \
            --log_name oncotator.log \
            ${"--default_config " + default_config_file}
    >>>

    runtime {
        docker: "${oncotator_docker}"
        memory: "8 GB"
        bootDiskSizeGb: 12
        disks: "local-disk 50 HDD"
        preemptible: "3"
    }

    output {
        File mutect1_maf="${tumor_id}.mutect1.maf.annotated"
        File mutect2_maf="${tumor_id}.mutect2.maf.annotated"
    }
}