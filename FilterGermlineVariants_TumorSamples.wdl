workflow FilterGermlineVariants_TumorSample {
  ### Tumor sample
  String tumor_id
  File mutect1_oncotated_maf
  File mutect1_callstats
  File mutect2_oncotated_maf

  ### Normal Sample
  String? normal_id
  File? match_normal_variants

  File tcga_hotspots

  call filterGermlineEvents {
    input:
    tumor_id=tumor_id,
    normal_id=normal_id,
    mutect1_oncotated_maf=mutect1_oncotated_maf,
    mutect1_callstats=mutect1_callstats,
    mutect2_oncotated_maf=mutect2_oncotated_maf,
    match_normal_variants=match_normal_variants,
    tcga_hotspots=tcga_hotspots
  }

  output {
    File filtered_variants = filterGermlineEvents.filtered_variants
    String clear_snvs = filterGermlineEvents.clear_snvs
  }
}

task filterGermlineEvents {
  String tumor_id
  String? normal_id
  File mutect1_oncotated_maf
  File mutect1_callstats
  File mutect2_oncotated_maf
  File? match_normal_variants
  File tcga_hotspots

  command <<<
    # Function call depends on whether sample has match normal or not
    if [ ${normal_id} != NA ]; then
      echo "Filtering variants with match normal"
      match_normal_variants="--match_normal_filtered_variants ${match_normal_variants}"
    else
      echo "Filtering variants with no match normal"
    fi
    python /TSCA/filter_variants.py \
      --sample_type Tumor \
      --sample_id ${tumor_id} \
      --mutect1_oncotated_maf ${mutect1_oncotated_maf} \
      --mutect1_callstats ${mutect1_callstats} \
      --mutect2_oncotated_maf ${mutect2_oncotated_maf} \
      --TCGAhotspots_path ${tcga_hotspots} \
      --match_normal_sample_id ${normal_id} \
      $match_normal_variants

  >>>

  runtime {
      docker: "mcadosch/tsca:latest"
      memory: "4 GB"
      disks: "local-disk 20 SSD"
  }
  output {
      File filtered_variants="${tumor_id}.filtered.variants.tsv"
      String clear_snvs=read_string("clear_snvs.txt")
  }
}