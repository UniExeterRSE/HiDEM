#!/bin/bash
# Script to submit a HiDEM job to Isambard3, generating the slurm file

CMD_LINE=$(printf %q "$BASH_SOURCE")$((($#)) && printf ' %q' "$@")

INP_FILE="inp.dat"
SLURM_FILE="run_isambard3.slurm"
NODES=1
NTASKS_PER_NODE=144

# Print usage
usage() {
	echo "Usage: $0 [-n|--nodes N] [-h|--help]"
	echo "  -n, --nodes N     Number of nodes (default: $NODES)"
	echo "  -h, --help        Show this help message and exit"
}

# Parse command line options
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-n|--nodes)
			NODES="$2"
			shift; shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			shift
			;;
	esac
done

# Calculate total number of MPI ranks
NTASKS=$((NODES * NTASKS_PER_NODE))

# Parse Run Name, Work Directory, and Results Directory from inp.dat
RUN_NAME=$(grep -E '^Run Name' "$INP_FILE" | sed -E 's/.*=\s*"([^"]+)".*/\1/')
WORK_DIR=$(grep -E '^Work Directory' "$INP_FILE" | sed -E 's/.*=\s*"?([^\"]+)"?.*/\1/')
RESULTS_DIR=$(grep -E '^Results Directory' "$INP_FILE" | sed -E 's/.*=\s*"?([^\"]+)"?.*/\1/')

# Write the slurm script
cat > "$SLURM_FILE" <<EOF
#!/bin/bash
#
# Slurm run script for HiDEM job on Isambard3
#  auto-generated using this command:
#  $CMD_LINE

#SBATCH --job-name=${RUN_NAME}
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition=grace
#SBATCH --account=brics.e5i
#SBATCH --qos=normal
#SBATCH --nodes=${NODES}
#SBATCH --ntasks=${NTASKS}               # total MPI ranks
#SBATCH --ntasks-per-node=${NTASKS_PER_NODE}
#SBATCH --cpus-per-task=1
#SBATCH --distribution=block:block:block
#SBATCH --time=6:00:00

echo "========================================================================"
echo "Job ${RUN_NAME} started on \$(hostname) at \$(date)"
echo "Job ID: \$SLURM_JOB_ID"
echo "========================================================================"

echo "SLURM_NTASKS=\${SLURM_NTASKS}"                    # Same as -n, –ntasks. The number of tasks.
echo "SLURM_NNODES=\${SLURM_NNODES}"                    # Total number of nodes in the job’s resource allocation.
echo "SLURM_CPUS_PER_TASK=\${SLURM_CPUS_PER_TASK}"      # Number of CPUs per task.
echo "SLURM_NTASKS_PER_NODE=\${SLURM_NTASKS_PER_NODE}"  # Number of tasks requested per node.

# Load necessary modules for Isambard3
module purge
module load PrgEnv-cray          2>/dev/null
module load craype-network-ofi   2>/dev/null
module load cray-mpich           2>/dev/null

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# MPI and OpenMP optimization settings
# These settings improve on-node communication and reduce MPI overhead
export OMP_NUM_THREADS=1
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# NUMA-aware MPI optimizations for Grace architecture
export MPICH_OFI_NIC_POLICY=NUMA           # Use NUMA-local NICs
export MPICH_RANK_REORDER_METHOD=1         # SMP reordering for better on-node communication
export MPICH_CPUMASK_DISPLAY=0             # Set to 1 to debug CPU binding

# Additional MPI performance tuning
export MPICH_ENV_DISPLAY=0                 # Set to 1 to see all MPI env vars
export MPICH_OPTIMIZED_MEMCPY=1            # Use optimized memcpy for large messages

# Create output directories (to match input dat file)
mkdir -p ${RESULTS_DIR} ${WORK_DIR}

# MPI run command using srun (see https://docs.isambard.ac.uk/user-documentation/guides/slurm)
RUN_CMD="srun --mpi=cray_shasta ../install/HiDEM"

echo "========================================================================"
echo "Running: \${RUN_CMD}"
echo "Start time: \$(date)"
echo "========================================================================"

START=\$(date +%s.%N)
time \${RUN_CMD}
RETCODE=\$?
END=\$(date +%s.%N)

DURATION=\$(echo "\$END - \$START" | bc)

echo "========================================================================"
echo "End time: \$(date)"
echo "Duration: \${DURATION} seconds"
echo "Exit code: \${RETCODE}"
echo "========================================================================"

# Exit with the same code as the application
exit \${RETCODE}
EOF

# Submit the job
sbatch "${SLURM_FILE}"

/usr/bin/squeue -o "%.8i %.9P %.32j %.12u %.12T %.7M %.4C %.12l %.7m %.3D %R" --sort=+i --me
