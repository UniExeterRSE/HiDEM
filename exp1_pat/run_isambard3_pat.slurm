#!/bin/bash
#
# Slurm run script for HiDEM job on Isambard3
#  auto-generated using this command:
#  ../scripts/job_scripts/submit_isambard3.sh

#SBATCH --job-name=HiDEM_exp1_pat_inst
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition=grace
#SBATCH --account=brics.e5i
#SBATCH --qos=normal
#SBATCH --nodes=2
#SBATCH --ntasks=288               # total MPI ranks
#SBATCH --ntasks-per-node=144
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

export OMP_NUM_THREADS=1  # Set OMP threads for single-threaded tasks

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

# Load profiling tools
module load perftools-base/24.07.0
module load perftools

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

MODEL_EXE="../install_pat/HiDEM.inst"

# Clear and re-create output directories (to match input dat file)
rm -rf ./results ./work
mkdir -p ./results ./work

echo "========================================================================"
echo "Running: ${MODEL_EXE} in $(pwd)"
echo "Start time: $(date)"
echo "========================================================================"

START=$(date +%s.%N)
echo "srun --mpi=cray_shasta ${MODEL_EXE}"
srun --mpi=cray_shasta ${MODEL_EXE}
RETCODE=$?
END=$(date +%s.%N)

DURATION=$(echo "$END - $START" | bc)

echo "========================================================================"
echo "End time: $(date)"
echo "Duration: ${DURATION} seconds"
echo "Exit code: ${RETCODE}"
echo "========================================================================"

echo ""
echo ""

echo "========================================================================"
echo "Generating profiling report..."
echo "========================================================================"

for dir in ${MODEL_EXE##*/}+*/; do
    FILES=(${dir}/xf-files/*.xf)
    if [[ ${#FILES[@]} == 1 ]]; then
        # Generate report from single file
        echo "pat_report -f ap2 -o ${MODEL_EXE##*/}_timing_report.txt ${FILES[0]}"
        pat_report -f ap2 -o ${MODEL_EXE##*/}_timing_report.txt ${FILES[0]}
    else
        # Generate a single .ap2 file from all .xf files
        echo "pat_report -f ap2 -o ${dir}/merged.ap2 ${dir}/xf-files/*.xf"
        pat_report -f ap2 -o ${dir}/merged.ap2 ${dir}/xf-files/*.xf

        echo "pat_report -o ${MODEL_EXE##*/}_timing_report.txt ${dir}/merged.ap2"
        pat_report -o ${MODEL_EXE##*/}_timing_report.txt ${dir}/merged.ap2
    fi
done

# It should create these files
ls -l build-options.apa ${MODEL_EXE##*/}_timing_report.txt MPICH_RANK_ORDER.Grid

# Exit with the same code as the application
exit ${RETCODE}

