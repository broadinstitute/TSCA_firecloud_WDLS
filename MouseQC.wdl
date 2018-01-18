workflow MouseQC {

    String sample_id
    File bam_file
    File bai_file
    File mouse_reference_snps

    call mouseQC {
        input:
        sample_id=sample_id,
        bam_file=bam_file,
        bai_file=bai_file,
        mouse_reference_snps=mouse_reference_snps
    }

    output {
        File mouse_qc_results = mouseQC.mouse_qc_results
        String mouse_qc_contamination = mouseQC.mouse_qc_contamination
    }
}

task mouseQC {
    String sample_id
    File bam_file
    File bai_file
    File mouse_reference_snps
    
    command <<<
        cat /TSCA/docker_v

        Rscript /TSCA/mouse_qc.R \
                    --sample_id ${sample_id} \
                    --bam_path ${bam_file} \
                    --mouse_reference_snps ${mouse_reference_snps}

        python /TSCA/evaluate_mouse_contamination.py \
                    --mouse_qc_file ${sample_id}.mouse_qc.txt
    >>>

    output {
        File mouse_qc_results = "${sample_id}.mouse_qc.txt"
        String mouse_qc_contamination=read_string("mouse_qc_status.txt")
    }
    
    runtime {
        docker: "mcadosch/tsca:latest"
        memory: "4 GB"
        cpu: "1"
        disks: "local-disk 20 HDD"
        preemptible_attempts: "2"
    }
}
