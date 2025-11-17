#!/bin/bash
# Script to submit a HiDEM job to ISCA, generating the slurm file from inp.dat

INP_FILE="inp.dat"
SLURM_FILE="run_isca.slurm"
NODES=10
NTASKS_PER_NODE=20


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
# Slurm run script for HiDEM job on ISCA (auto-generated)
#
#SBATCH --job-name=${RUN_NAME}
#SBATCH --output=%x-%j.out.log
#SBATCH --error=%x-%j.err.log
#SBATCH --partition=sq                             # serial queue
#SBATCH --account=Research_Project-T125973         # research project SWAIS-2C
#SBATCH --nodes=${NODES}
#SBATCH --ntasks=${NTASKS}               # total MPI ranks
#SBATCH --ntasks-per-node=${NTASKS_PER_NODE}
#SBATCH --time=24:00:00

echo "========================================================================"
echo "Job ${RUN_NAME} started on \$(hostname) at \$(date)"
echo "Job ID: \$SLURM_JOB_ID"
echo "========================================================================"

# Load necessary modules for ISCA
module load CMake/3.26.3-GCCcore-12.3.0 OpenMPI/4.1.5-GCC-12.3.0


echo "------------------------------------------------------------------------"
echo "Loaded modules:"
module list 2>&1 | cat
echo "------------------------------------------------------------------------"

# Set OMP threads for single-threaded tasks
export OMP_NUM_THREADS=1

# Create output directories (to match input dat file)
mkdir -p ${RESULTS_DIR} ${WORK_DIR}

# MPI run command on ISCA
RUN_CMD="mpirun --mca pml ucx --mca btl ^openib --mca fs ^gpfs ../install/HiDEM"

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
