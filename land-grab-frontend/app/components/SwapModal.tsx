"use client";

import { useState, useEffect } from "react";
import { Dialog } from "@headlessui/react";
import { usePublicClient, useWalletClient } from "wagmi";
import { LandRegistryABI } from "@/contracts/LandRegistryABI";
import { LandSwapABI } from "@/contracts/LandSwapABI";
import { toast } from "sonner";
import { toBigInt } from "ethers";

const LAND_REGISTRY_ADDRESS = "0xA45B1E87AfA000AB7c8B3099A43d57d38Fb8F0D0";
const LAND_SWAP_ADDRESS = "0xADbF04c9df2d3c3F9Bb84951DA5cF64Ee5cD8162";

interface SwapModalProps {
  isOpen: boolean;
  onClose: () => void;
  userAddress: string;
}

interface Land {
  what3words: string;
  owner: string;
  claimedAt: number;
  isClaimed: boolean;
}

export default function SwapModal({
  isOpen,
  onClose,
  userAddress,
}: SwapModalProps) {
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const [theirLandWords, setTheirLandWords] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [myLands, setMyLands] = useState<Land[]>([]);
  const [selectedLand, setSelectedLand] = useState<string>("");

  useEffect(() => {
    const fetchMyLands = async () => {
      if (!publicClient || !userAddress) return;

      try {
        const userLands = (await publicClient.readContract({
          address: LAND_REGISTRY_ADDRESS,
          abi: LandRegistryABI,
          functionName: "getUserLands",
          args: [userAddress],
        })) as string[];

        const landDetails = await Promise.all(
          userLands.map(async (words) => {
            const land = await publicClient.readContract({
              address: LAND_REGISTRY_ADDRESS,
              abi: LandRegistryABI,
              functionName: "getLandDetails",
              args: [words],
            });
            return land as Land;
          })
        );

        setMyLands(landDetails);
        if (landDetails.length > 0) {
          setSelectedLand(landDetails[0].what3words);
        }
      } catch (error) {
        console.error("Error fetching lands:", error);
        setError("Failed to fetch your lands");
      }
    };

    if (isOpen) {
      fetchMyLands();
    }
  }, [publicClient, userAddress, isOpen]);

  const handleSwapLand = async () => {
    if (!userAddress || !selectedLand || !walletClient || !publicClient) return;

    try {
      setLoading(true);
      setError(null);

      // 1. Propose the swap
      const proposeTx = await walletClient.writeContract({
        address: LAND_SWAP_ADDRESS,
        abi: LandSwapABI,
        functionName: "proposeSwap",
        args: [selectedLand, theirLandWords],
        gas: toBigInt(1000000),
      });
      await publicClient.waitForTransactionReceipt({ hash: proposeTx });

      // 2. Show toast with transaction hash
      toast.success(
        `Land swap proposed successfully! Transaction: ${proposeTx}`,
        {
          duration: 5000,
        }
      );

      // Reset form
      setTheirLandWords("");
      setSelectedLand("");
      setLoading(false);
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Failed to propose land swap";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm rounded-lg bg-white p-6">
          <Dialog.Title className="text-lg font-medium mb-4">
            Swap Land
          </Dialog.Title>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Your Land
              </label>
              <select
                value={selectedLand}
                onChange={(e) => setSelectedLand(e.target.value)}
                className="w-full rounded-md border border-gray-300 px-3 py-2"
              >
                {myLands.map((land) => (
                  <option key={land.what3words} value={land.what3words}>
                    {land.what3words}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Their Land (what3words)
              </label>
              <input
                type="text"
                value={theirLandWords}
                onChange={(e) => setTheirLandWords(e.target.value)}
                placeholder="hints.sporting.permit"
                className="w-full rounded-md border border-gray-300 px-3 py-2"
              />
            </div>

            {error && <p className="text-red-500 text-sm">{error}</p>}

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 rounded-md"
              >
                Cancel
              </button>
              <button
                onClick={handleSwapLand}
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-white bg-primary rounded-md hover:bg-primary/90 disabled:opacity-50"
              >
                {loading ? "Swapping..." : "Swap"}
              </button>
            </div>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
}
