#include <cuda.h>
#include <cuda_runtime.h>
#include "common.h"
#include "efficient.h"

#define blocksize 128

namespace StreamCompaction {
    namespace Efficient {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

		__global__ void upSweep(int n, int pow2dPlus1, int pow2d, int *odata)
		{
			int index = threadIdx.x + (blockIdx.x * blockDim.x);
			if (index >= n) {
				return;
			}

			index *= pow2dPlus1;
			if (index < n)
				odata[index + pow2dPlus1 - 1] += odata[index + pow2d - 1];
		}

		__global__ void downSweep(int n, int pow2dPlus1, int pow2d, int *odata)
		{
			int index = threadIdx.x + (blockIdx.x * blockDim.x);
			if (index >= n) {
				return;
			}

			index *= pow2dPlus1;
			if (index < n) {
				int t = odata[index + pow2d - 1];
				odata[index + pow2d - 1] = odata[index + pow2dPlus1 - 1];
				odata[index + pow2dPlus1 - 1] += t;
			}
		}

        /**
         * Performs prefix-sum (aka scan) on idata, storing the result into odata.
         */
        void scan(int n, int *odata, const int *idata) {
			dim3 fullBlocksPerGrid((n + blocksize - 1) / blocksize);
			
			int *out;
			cudaMalloc((void**)&out, n * sizeof(int));
			cudaMemcpy(out, idata, sizeof(int) * n, cudaMemcpyHostToDevice);

			timer().startGpuTimer();
            // TODO

			// Get the next power of 2
			int currPow = ilog2ceil(n) - 1;
			int nextPow = 2 << currPow;

			// Up-Sweep
			for (int d = 0; d <= ilog2ceil(n) - 1; d++) {
				int pow2dPlus1 = pow(2, d + 1);
				int pow2d = pow(2, d);

				upSweep << < fullBlocksPerGrid, blocksize >> > (n, pow2dPlus1, pow2d, out);
			}

			// Gotta find a better solution to this. lol
			cudaMemcpy(odata, out, sizeof(int) * n, cudaMemcpyDeviceToHost);
			odata[n - 1] = 0;
			cudaMemcpy(out, odata, sizeof(int) * n, cudaMemcpyHostToDevice);

			// Down-Sweep
			for (int d = ilog2ceil(n) - 1; d >= 0; d--) {
				int pow2dPlus1 = pow(2, d + 1);
				int pow2d = pow(2, d);
			
				downSweep << < fullBlocksPerGrid, blocksize >> > (n, pow2dPlus1, pow2d, out);
			}

			cudaMemcpy(odata, out, sizeof(int) * n, cudaMemcpyDeviceToHost);

			cudaFree(out);

            timer().endGpuTimer();
        }

        /**
         * Performs stream compaction on idata, storing the result into odata.
         * All zeroes are discarded.
         *
         * @param n      The number of elements in idata.
         * @param odata  The array into which to store elements.
         * @param idata  The array of elements to compact.
         * @returns      The number of elements remaining after compaction.
         */
        int compact(int n, int *odata, const int *idata) {
            timer().startGpuTimer();
            // TODO
            timer().endGpuTimer();
            return -1;
        }
    }
}
