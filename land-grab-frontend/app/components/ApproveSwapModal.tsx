"use client";

import { useState } from "react";
import { Dialog } from "@headlessui/react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { toast } from "sonner";
import { useWalletClient, usePublicClient } from "wagmi";
import { LandSwapABI } from "@/contracts/LandSwapABI";

const LAND_SWAP_ADDRESS = "0xADbF04c9df2d3c3F9Bb84951DA5cF64Ee5cD8162";

interface ApproveSwapModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function ApproveSwapModal({
  isOpen,
  onClose,
}: ApproveSwapModalProps) {
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const [loading, setLoading] = useState(false);
  const [proposerAddress, setProposerAddress] = useState("");

  const handleApproveSwap = async () => {
    if (!walletClient || !publicClient) {
      toast.error("Wallet not connected");
      return;
    }

    if (!proposerAddress) {
      toast.error("Please enter a proposer address");
      return;
    }

    try {
      setLoading(true);

      // Approve the swap
      const approveTx = await walletClient.writeContract({
        address: LAND_SWAP_ADDRESS,
        abi: LandSwapABI,
        functionName: "approveSwap",
        args: [proposerAddress],
        gas: BigInt(1000000),
      });

      await publicClient.waitForTransactionReceipt({ hash: approveTx });

      toast.success("Swap approved successfully!");
      onClose();
      setProposerAddress("");
    } catch (error) {
      console.error("Error approving swap:", error);
      toast.error("Failed to approve swap");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm rounded-lg bg-white p-6">
          <div className="flex justify-between items-center mb-4">
            <Dialog.Title className="text-lg font-semibold">
              Approve Land Swap
            </Dialog.Title>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <label
                htmlFor="proposer"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Proposer Address
              </label>
              <input
                type="text"
                id="proposer"
                value={proposerAddress}
                onChange={(e) => setProposerAddress(e.target.value)}
                placeholder="0x..."
                className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>

          <div className="mt-6 flex justify-end space-x-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 rounded-md"
            >
              Cancel
            </button>
            <button
              onClick={handleApproveSwap}
              disabled={loading || !proposerAddress}
              className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary/90 rounded-md disabled:opacity-50"
            >
              {loading ? "Approving..." : "Approve Swap"}
            </button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
