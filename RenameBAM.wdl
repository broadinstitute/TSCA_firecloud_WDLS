workflow RenameBAM {

  # Inputs
  String sample_id
  File bam_file
  File bai_file

  call renameBAM {
    input:
      sample_id=sample_id,
      bam_file=bam_file,
      bai_file=bai_file
  }

  output {
  	File renamed_bam = renameBAM.renamed_bam
    File renamed_bai = renameBAM.renamed_bai
  }
}

task renameBAM {
  String sample_id
  File bam_file
  File bai_file

  command <<<
        # Rename sample in BAM file
        # This usually tends to be the name of the well, which causes complications later on as they are not unique
        # Rename to sample_id, which is unique
        samtools view -H ${bam_file}  | sed "s/SM:[^\t]*/SM:${sample_id}/g" | samtools reheader - ${bam_file} > ${sample_id}_renamed.bam
        samtools index ${sample_id}_renamed.bam ${sample_id}_renamed.bai
    >>>

    runtime {
        docker: "broadinstitute/genomes-in-the-cloud:2.3-1498756809"
        memory: "4 GB"
        disks: "local-disk 20 SSD"
    }
    output {
        File renamed_bam = "${sample_id}_renamed.bam"
        File renamed_bai = "${sample_id}_renamed.bai"
    }
}