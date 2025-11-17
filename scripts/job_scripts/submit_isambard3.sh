#!/bin/bash
# Script to submit a HiDEM job to Isambard3, generating the slurm file


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
# Slurm run script for HiDEM job on Isambard3 (auto-generated)
#
#SBATCH --job-name=${RUN_NAME}
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition=grace
#SBATCH --account=brics.e5i
#SBATCH --qos=normal
#SBATCH --nodes=${NODES}
#SBATCH --ntasks=${NTASKS}               # total MPI ranks
#SBATCH --ntasks-per-node=${NTASKS_PER_NODE}
#SBATCH --time=6:00:00

echo "========================================================================"
echo "Job ${RUN_NAME} started on \$(hostname) at \$(date)"
echo "Job ID: \$SLURM_JOB_ID"
echo "========================================================================"

# Load necessary modules for Isambard3
module purge
module load PrgEnv-cray          2>/dev/null
module load craype-network-ofi   2>/dev/null
module load cray-mpich           2>/dev/null

echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# Set OMP threads for single-threaded tasks
export OMP_NUM_THREADS=1

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

DURATION=\$(echo "$\END - \$START" | bc)

echo "========================================================================"
echo "End time: \$(date)"
echo "Duration: \${DURATION} seconds"
echo "Exit code: \${RETCODE}"
echo "========================================================================"

# Exit with the same code as the application
exit \${RETCODE}
EOF

# Submit the job
sbatch "$SLURM_FILE"

/usr/bin/squeue -o "%.8i %.9P %.32j %.12u %.12T %.7M %.4C %.12l %.7m %.3D %R" --sort=+i --me
