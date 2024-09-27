sample_links = {"ERR458493": "https://osf.io/5daup/download",
                "ERR458494": "https://osf.io/8rvh5/download",
                "ERR458495": "https://osf.io/2wvn3/download",
                "ERR458500": "https://osf.io/xju4a/download",
                "ERR458501": "https://osf.io/nmqe6/download",
                "ERR458502": "https://osf.io/qfsze/download"}

# the sample names are dictionary keys in sample_links. extract them to a list we can use below
SAMPLES=sample_links.keys()

rule all:
    input:
        # create a new filename for every entry in SAMPLES,
        # replacing {name} with each entry.
        expand("rnaseq/quant/{name}_quant/quant.sf", name=SAMPLES),

# download yeast rna-seq data from Schurch et al, 2016 study
rule download_reads:
    output: "rnaseq/raw_data/{sample}.fq.gz" 
    params:
        download_link = lambda wildcards: sample_links[wildcards.sample]
    shell:
        """
        curl -L {params.download_link} -o {output}
        """

### download and index the yeast transcriptome ###
rule download_yeast_transcriptome:
    output: "rnaseq/reference/Saccharomyces_cerevisiae.R64-1-1.cdna.all.fa.gz" 
    shell:
        """
        curl -L ftp://ftp.ensembl.org/pub/release-99/fasta/saccharomyces_cerevisiae/cdna/Saccharomyces_cerevisiae.R64-1-1.cdna.all.fa.gz -o {output}
        """

rule salmon_index:
    input: "rnaseq/reference/Saccharomyces_cerevisiae.R64-1-1.cdna.all.fa.gz" 
    output: directory("rnaseq/quant/sc_ensembl_index")
    shell:
        """
        salmon index --index {output} --transcripts {input} # --type quasi
        """

### quantify reads with salmon
rule salmon_quantify:
    input:
        reads="rnaseq/raw_data/{sample}.fq.gz",
        index_dir="rnaseq/quant/sc_ensembl_index"
    output: "rnaseq/quant/{sample}_quant/quant.sf"
    params:
        outdir= lambda wildcards: "rnaseq/quant/" + wildcards.sample + "_quant"
    shell:
        """
        salmon quant -i {input.index_dir} --libType A -r {input.reads} -o {params.outdir} --seqBias --gcBias --validateMappings
        """
