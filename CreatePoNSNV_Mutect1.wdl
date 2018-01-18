workflow CreatePanelOfNormals {
    String PoN_name
    File mutect1_jar
    File reference_fasta
    File reference_fasta_fai
    File reference_fasta_dict
    File interval_list

    Array[File] normal_vcf_files
    
    call createPanelOfNormals {
        input: 
            PoN_name=PoN_name,
            mutect1_jar=mutect1_jar,
            normal_vcf_files=normal_vcf_files,
            reference_fasta=reference_fasta,
            reference_fasta_fai=reference_fasta_fai,
            reference_fasta_dict=reference_fasta_dict, 
            interval_list=interval_list
    }

    output {
    	File normals_pon_vcf = createPanelOfNormals.normals_pon_vcf
    }
}

task createPanelOfNormals {
    String PoN_name
    File mutect1_jar
    File reference_fasta
    File reference_fasta_fai
    File reference_fasta_dict
    File interval_list
    Array[File] normal_vcf_files
    
    command <<<
    	java -jar -Xmx4g ${mutect1_jar} \
    	        -T CombineVariants \
    	        -R ${reference_fasta} \
    	        -V ${sep=" -V " normal_vcf_files} \
    	        -minN 2 \
    	        --setKey "null" \
    	        --filteredAreUncalled \
    	        --filteredrecordsmergetype KEEP_IF_ANY_UNFILTERED \
    	        -L ${interval_list} \
    	        --genotypemergeoption UNIQUIFY \
    	        -o ${PoN_name}.mutect1.vcf

    >>>
    
    output {
        File normals_pon_vcf = "${PoN_name}.mutect1.vcf"
    }
    
    runtime {
    	docker: "dockerbase/java7:latest"
        memory: "8 GB"
        cpu: "1"
        disks: "local-disk 50 HDD"
    }
}
