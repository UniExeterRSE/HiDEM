#!/bin/bash
#
# Slurm run script for HiDEM job on Isambard3
#  auto-generated using this command:
#  ../scripts/job_scripts/submit_isambard3.sh

#SBATCH --job-name=HiDEM_exp1_numa_placement
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition=grace
#SBATCH --account=brics.e5i
#SBATCH --qos=normal
#SBATCH --nodes=4
#SBATCH --ntasks=288               # total MPI ranks
#SBATCH --ntasks-per-node=72
#SBATCH --time=12:00:00

export OMP_NUM_THREADS=1  # Set OMP threads for single-threaded tasks
export OMP_PROC_BIND=close
export OMP_PLACES=cores

echo "========================================================================"
echo "Job HiDEM_exp1 started on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo "========================================================================"

echo "SLURM_NTASKS=${SLURM_NTASKS}"                    # Same as -n, –ntasks. The number of tasks.
echo "SLURM_NNODES=${SLURM_NNODES}"                    # Total number of nodes in the job’s resource allocation.
echo "SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"      # Number of CPUs per task.
echo "SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"  # Number of tasks requested per node.

echo "OMP_NUM_THREADS=${OMP_NUM_THREADS}"
echo "OMP_PROC_BIND=${OMP_PROC_BIND}"
echo "OMP_PLACES=${OMP_PLACES}"

# Load necessary modules for Isambard3
module purge
module load PrgEnv-cray          2>/dev/null
module load craype-network-ofi   2>/dev/null
module load cray-mpich           2>/dev/null

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# Create output directories (to match input dat file)
mkdir -p ./results ./work

# MPI run command using srun (see https://docs.isambard.ac.uk/user-documentation/guides/slurm)
RUN_CMD="srun --mpi=cray_shasta ../install/HiDEM"

echo "========================================================================"
echo "Running: ${RUN_CMD}"
echo "Start time: $(date)"
echo "========================================================================"

START=$(date +%s.%N)
time ${RUN_CMD}
RETCODE=$?
END=$(date +%s.%N)

DURATION=$(echo "$END - $START" | bc)

echo "========================================================================"
echo "End time: $(date)"
echo "Duration: ${DURATION} seconds"
echo "Exit code: ${RETCODE}"
echo "========================================================================"

# Exit with the same code as the application
exit ${RETCODE}
