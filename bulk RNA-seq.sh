#!/bin/bash

# Bulk RNA-seq Processing Pipeline
# Author: lyma

# =============================================
# Configuration Section
# =============================================

# Set the directory containing raw data files (you can change this to any directory)
fqdir='CASZ1-OE'

# Set the reference index for RSEM
rsemref='/bulk-seq/rsem_index/hg19/hg19'

# =============================================
# Main Processing Loop
# =============================================

echo "Starting bulk RNA-seq processing pipeline..."
echo "Processing files in directory: $fqdir"

for f in ${fqdir}/*_R1.fq.gz; do
    # Check if file exists
    if [ ! -f "$f" ]; then
        echo "No R1 files found in $fqdir"
        break
    fi
    
    # Extract base filename
    root=$(basename "$f")
    bf=$(echo "$root" | sed -r 's/_R1.fq.gz//g')
    f1="${root}"
    f2=$(echo "$root" | sed 's/_R1/_R2/g')
    
    echo "============================================="
    echo "Processing sample: $bf"
    echo "Forward read: $f1"
    echo "Reverse read: $f2"
    echo "============================================="
    
    # Step 1: Quality Control with fastp
    echo "Step 1: Running quality control with fastp..."
    fastp -i $fqdir/$f1 -o $fqdir/c_$f1 -I $fqdir/$f2 -O $fqdir/c_$f2 --thread 10 -h $fqdir/$bf.html
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully completed quality control for $bf"
    else
        echo "✗ Error in quality control for $bf"
        continue  # Skip to next sample if fastp fails
    fi
    
    # Step 2: Expression Calculation with RSEM
    echo "Step 2: Calculating expression with RSEM..."
    rsem-calculate-expression -p 10 --bowtie2 --bowtie2-sensitivity-level very_sensitive --no-bam-output --estimate-rspd --paired-end $fqdir/c_$f1 $fqdir/c_$f2 $rsemref $bf
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully calculated expression for $bf"
    else
        echo "✗ Error calculating expression for $bf"
    fi
    
    echo "Completed processing for sample: $bf"
    echo ""
done

echo "Pipeline finished!"
echo "All samples processed."
