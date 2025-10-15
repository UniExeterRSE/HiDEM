#!/bin/bash
#
# Slurm run script for example job on ISCA
#

#SBATCH --job-name=HiDEM
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition sq                             # serial queue
#SBATCH --account Research_Project-HPC-Training    # research project to submit under.
#SBATCH --nodes=7
#SBATCH --ntasks-per-node=20
#SBATCH --ntasks=140                               # number of MPI ranks
#SBATCH --time=06:00:00

module load CMake/3.26.3-GCCcore-12.3.0 OpenMPI/4.1.5-GCC-12.3.0

# Set OMP_NUM_THREADS for single-threaded tasks
export OMP_NUM_THREADS=1

# Create directories
mkdir -p ./Results ./work

RUN_CMD="mpirun --mca pml ucx --mca btl ^openib --mca fs ^gpfs ../install/HiDEM"
#RUN_CMD="mpirun --mca fs ^gpfs ../install/HiDEM"

echo "Start date $(date)"
echo "time ${RUN_CMD}"
START=$(date +%s.%N)

time ${RUN_CMD}

END=$(date +%s.%N)
DURATION=$(echo "$END - $START" | bc)
echo "End date $(date) [${DURATION}]"
