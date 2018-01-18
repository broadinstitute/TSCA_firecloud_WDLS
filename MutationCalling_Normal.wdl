## Mutation Calling workflow for normal samples
## MuTect 1 + MuTect 2 + Oncotator

workflow MutationCalling_Normal {
	### Sample
	String normal_id
	File normal_bam
	File normal_bai

	### References
	File reference_fasta
	File reference_fasta_index
	File reference_fasta_dict
	File targets_interval_list
	File tcga_hotspots

	### Databases
	File dbsnp_vcf
	File cosmic_vcf
	File dbsnp_vcf_index
	File cosmic_vcf_index
	File gnomad_vcf
	File gnomad_vcf_index

	### Executables
	File mutect_jar
	File gatk_jar

	# Oncotator Resources
	String oncotator_docker
	File? onco_ds_tar_gz
	File? default_config_file

	call mutect1 {
		input:
		mutect_jar=mutect_jar,
		normal_id=normal_id,
		normal_bam=normal_bam,
		normal_bai=normal_bai,
		reference_fasta=reference_fasta,
		reference_fasta_index=reference_fasta_index,
		reference_fasta_dict=reference_fasta_dict,
		targets_interval_list=targets_interval_list,
		dbsnp_vcf=dbsnp_vcf,
		dbsnp_vcf_index=dbsnp_vcf_index,
		cosmic_vcf=cosmic_vcf,
		cosmic_vcf_index=cosmic_vcf_index
	}

	call mutect2 {
		input:
		gatk_jar=gatk_jar,
		reference_fasta=reference_fasta,
		reference_fasta_index=reference_fasta_index,
		reference_fasta_dict=reference_fasta_dict,
		targets_interval_list=targets_interval_list,
		normal_id=normal_id,
		normal_bam=normal_bam,
		normal_bai=normal_bai,
		dbsnp_vcf=dbsnp_vcf,
		dbsnp_vcf_index=dbsnp_vcf_index,
		cosmic_vcf=cosmic_vcf,
		cosmic_vcf_index=cosmic_vcf_index
	}

	call filter_vcfs {
		input:
		normal_id=normal_id,
		mutect1_vcf=mutect1.vcf,
		mutect2_vcf=mutect2.vcf
	}

	call oncotate {
	    input:
        mutect1_vcf=filter_vcfs.mutect1_filtered_vcf,
        mutect2_vcf=filter_vcfs.mutect2_filtered_vcf,
        sample_id=normal_id,
        oncotator_docker=oncotator_docker,
        onco_ds_tar_gz=onco_ds_tar_gz,
        default_config_file=default_config_file
	}

	output {
		# MuTect1
		File mutect1_vcf = filter_vcfs.mutect1_filtered_vcf
		File mutect1_callstats = mutect1.callstats
		File mutect1_powerwig = mutect1.powerwig
		File mutect1_coveragewig = mutect1.coveragewig
		# MuTect2
		File mutect2_vcf = filter_vcfs.mutect2_filtered_vcf
		# Oncotator
		File mutect1_oncotated_maf=oncotate.mutect1_maf
		File mutect2_oncotated_maf=oncotate.mutect2_maf
	}
}

task mutect1 {
	File mutect_jar
	String normal_id
	File normal_bam
	File normal_bai
	File reference_fasta
	File reference_fasta_index
	File reference_fasta_dict
	File targets_interval_list
	File dbsnp_vcf
	File cosmic_vcf
	File dbsnp_vcf_index
	File cosmic_vcf_index

	command <<<
		java -jar -Xmx4g ${mutect_jar} \
			-T MuTect \
			-R ${reference_fasta} \
			--tumor_sample_name ${normal_id} \
			-I:tumor ${normal_bam} \
			--artifact_detection_mode \
			--dbsnp ${dbsnp_vcf} \
			--cosmic ${cosmic_vcf} \
			-L ${targets_interval_list} \
			--out ${normal_id}.callstats.txt \
			--coverage_file ${normal_id}.coverage.wig.txt \
			--power_file ${normal_id}.power.wig.txt \
			--vcf ${normal_id}.mutect1.vcf
	>>>

	runtime {
		docker: "dockerbase/java7:latest"
		memory: "8 GB"
		disks: "local-disk 100 HDD"
		preemptible_attempts: "3"
	}

	output {
		File callstats="${normal_id}.callstats.txt"
		File powerwig="${normal_id}.power.wig.txt"
		File coveragewig="${normal_id}.coverage.wig.txt"
		File vcf="${normal_id}.mutect1.vcf"
	}
}

task mutect2 {
  File gatk_jar
  File reference_fasta
  File reference_fasta_index
  File reference_fasta_dict
  File targets_interval_list
  String normal_id
  File normal_bam
  File normal_bai
  File dbsnp_vcf
  File dbsnp_vcf_index
  File cosmic_vcf
  File cosmic_vcf_index

  command <<< 
    java -jar ${gatk_jar} \
      -T MuTect2 \
      -R ${reference_fasta} \
      -I:tumor ${normal_bam} \
      --dbsnp ${dbsnp_vcf} \
      --cosmic ${cosmic_vcf} \
      -L ${targets_interval_list} \
      -o ${normal_id}.mutect2.vcf.gz
  >>>

  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.3.1-1501706336"
    memory:  "16 GB"
    disks: "local-disk 50 HDD"
    preemptible_attempts: "3"
  }

  output {
    File vcf = "${normal_id}.mutect2.vcf.gz"
    File vcf_index = "${normal_id}.mutect2.vcf.gz.tbi"
  }
}

task filter_vcfs {
	String normal_id
	File mutect1_vcf
	File mutect2_vcf

	command <<<
		# Filter variants that didn't pass MuTect 1 or 2 filters
		vcftools --vcf ${mutect1_vcf} --remove-filtered-all --recode --out ${normal_id}.mutect1
		vcftools --gzvcf ${mutect2_vcf} --remove-filtered-all --recode --out ${normal_id}.mutect2
	>>>

	runtime {
		docker: "biocontainers/vcftools:latest"
		memory: "8 GB"
		disks: "local-disk 4 HDD"
	}

	output {
		File mutect1_filtered_vcf="${normal_id}.mutect1.recode.vcf"
		File mutect2_filtered_vcf="${normal_id}.mutect2.recode.vcf"
	}
}

task oncotate {
    File mutect1_vcf
    File mutect2_vcf
    String sample_id
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
            -v ${mutect1_vcf} ${sample_id}.mutect1.maf.annotated hg19 -i VCF -o TCGAMAF \
            --skip-no-alt --infer-onps --collapse-number-annotations \
            --log_name oncotator.log \
            ${"--default_config " + default_config_file}

        /root/oncotator_venv/bin/oncotator --db-dir onco_dbdir/ \
            -c $HOME/tx_exact_uniprot_matches.AKT1_CRLF2_FGFR1.txt  \
            -v ${mutect2_vcf} ${sample_id}.mutect2.maf.annotated hg19 -i VCF -o TCGAMAF \
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
        File mutect1_maf="${sample_id}.mutect1.maf.annotated"
        File mutect2_maf="${sample_id}.mutect2.maf.annotated"
    }
}