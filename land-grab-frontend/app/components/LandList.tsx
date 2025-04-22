"use client";

import { useState, useEffect } from "react";
import { usePublicClient } from "wagmi";
import { LandRegistryABI } from "@/contracts/LandRegistryABI";

const LAND_REGISTRY_ADDRESS = "0xA45B1E87AfA000AB7c8B3099A43d57d38Fb8F0D0";

interface LandListProps {
  userAddress: string;
}

export default function LandList({ userAddress }: LandListProps) {
  const publicClient = usePublicClient();
  const [lands, setLands] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchLandsAndSwaps = async () => {
      if (!publicClient) return;

      try {
        setLoading(true);

        // Get user's lands
        const userLands = (await publicClient.readContract({
          address: LAND_REGISTRY_ADDRESS,
          abi: LandRegistryABI,
          functionName: "getUserLands",
          args: [userAddress],
        })) as string[];

        setLands(userLands);
      } catch (error) {
        console.error("Error fetching lands and swaps:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchLandsAndSwaps();
  }, [publicClient, userAddress]);

  if (loading) {
    return <div className="text-center py-4">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        {lands.length === 0 ? (
          <p className="text-gray-500">You don&apos;t own any lands yet.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {lands.map((land, index) => (
              <div
                key={index}
                className="p-4 border rounded-lg bg-white shadow-sm"
              >
                <p className="font-mono text-sm">{land}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
