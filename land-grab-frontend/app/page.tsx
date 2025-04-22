"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useState, useEffect } from "react";
import { useAccount, usePublicClient, useWalletClient } from "wagmi";
import { MapIcon, ArrowPathIcon, TrashIcon } from "@heroicons/react/24/outline";
import axios from "axios";
import { toast } from "sonner";
import SwapModal from "./components/SwapModal";
import LandList from "./components/LandList";
import { UserRegistryABI } from "@/contracts/UserRegistryABI";
import { LandRegistryABI } from "@/contracts/LandRegistryABI";
import { toBigInt } from "ethers";
import ApproveSwapModal from "./components/ApproveSwapModal";

const USER_REGISTRY_ADDRESS = "0x5D7cc7cb12C4389940b9b756BCfA7921bF78Ca73";
const LAND_REGISTRY_ADDRESS = "0xA45B1E87AfA000AB7c8B3099A43d57d38Fb8F0D0";

interface User {
  userAddress: string;
  username: string;
  isActive: boolean;
  createdAt: number;
  lastActive: number;
}

export default function Home() {
  const { address } = useAccount();
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const [mounted, setMounted] = useState(false);
  const [what3words, setWhat3words] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSwapModalOpen, setIsSwapModalOpen] = useState(false);
  const [isApproveSwapModalOpen, setIsApproveSwapModalOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  const getCurrentLocation = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!navigator.geolocation) {
        throw new Error("Geolocation is not supported by your browser");
      }

      const position = await new Promise<GeolocationPosition>(
        (resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject);
        }
      );

      const { latitude, longitude } = position.coords;

      // Convert coordinates to what3words
      const response = await fetch(
        `https://mapapi.what3words.com/api/convert-to-3wa?coordinates=${latitude},${longitude}&language=en&format=json`
      );
      const data = await response.json();
      setWhat3words(data.words);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to get location");
    } finally {
      setLoading(false);
    }
  };

  const handleClaimLand = async () => {
    if (!address || !what3words || !walletClient || !publicClient) return;

    try {
      setLoading(true);
      setError(null);

      // 1. Get coordinates from what3words API
      const { data: w3wData } = await axios.get(
        `https://mapapi.what3words.com/api/convert-to-coordinates?words=${what3words}`
      );

      if (!w3wData.coordinates) {
        throw new Error("Invalid what3words address");
      }

      // 2. Check if user exists and register if not
      const user = (await publicClient.readContract({
        address: USER_REGISTRY_ADDRESS,
        abi: UserRegistryABI,
        functionName: "getUser",
        args: [address],
      })) as User;

      if (!user.isActive) {
        const registerTx = await walletClient.writeContract({
          address: USER_REGISTRY_ADDRESS,
          abi: UserRegistryABI,
          functionName: "registerUser",
          args: [Math.random().toString(36).substring(2, 7)],
          gas: toBigInt(1000000), // Gas limit for registerUser function
        });
        await publicClient.waitForTransactionReceipt({ hash: registerTx });
        toast.success("User registered successfully!");
      }

      // 3. Claim the land
      const claimTx = await walletClient.writeContract({
        address: LAND_REGISTRY_ADDRESS,
        abi: LandRegistryABI,
        functionName: "claimLand",
        args: [what3words],
        gas: toBigInt(1000000),
      });
      await publicClient.waitForTransactionReceipt({ hash: claimTx });

      // 4. Show toast with transaction hash
      toast.success(`Land claimed successfully! Transaction: ${claimTx}`, {
        duration: 5000,
      });

      // Reset form
      setWhat3words("");
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Failed to claim land";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAccount = async () => {
    if (!address || !walletClient || !publicClient) return;

    try {
      setLoading(true);
      setError(null);

      // Check if user exists
      const user = (await publicClient.readContract({
        address: USER_REGISTRY_ADDRESS,
        abi: UserRegistryABI,
        functionName: "getUser",
        args: [address],
      })) as User;

      console.log(user);
      console.log(address);
      if (!user.isActive) {
        toast.error("Account already deleted!", {
          duration: 5000,
        });
        return;
      }

      const deleteTx = await walletClient.writeContract({
        address: USER_REGISTRY_ADDRESS,
        abi: UserRegistryABI,
        functionName: "deleteUser",
        args: [],
        gas: toBigInt(1000000),
      });
      await publicClient.waitForTransactionReceipt({ hash: deleteTx });

      // 3. Show toast with success message
      toast.success(
        "Account deleted successfully! All lands have been released.",
        {
          duration: 5000,
        }
      );
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Failed to delete account";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-primary">Land Grab</h1>
          <ConnectButton />
        </div>

        <div className="bg-surface rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-xl font-semibold mb-4">Your Location</h2>
          <div className="flex items-center gap-4">
            <button
              onClick={getCurrentLocation}
              disabled={loading}
              className="flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90 disabled:opacity-50"
            >
              <MapIcon className="w-5 h-5" />
              {loading ? "Getting Location..." : "Get Current Location"}
            </button>
            {what3words && (
              <div className="flex-1">
                <p className="text-sm text-gray-600">what3words address:</p>
                <p className="font-mono">{what3words}</p>
              </div>
            )}
          </div>
          {error && <p className="text-error mt-2">{error}</p>}
        </div>

        {address && (
          <>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
              <button
                onClick={handleClaimLand}
                disabled={!what3words || loading}
                className="flex items-center justify-center gap-2 bg-green-600 text-white p-4 rounded-lg hover:bg-green-600 /90 disabled:opacity-50"
              >
                <MapIcon className="w-5 h-5" />
                Claim Land
              </button>
              <button
                onClick={() => setIsSwapModalOpen(true)}
                disabled={loading}
                className="flex items-center justify-center gap-2 bg-primary text-white p-4 rounded-lg hover:bg-primary/90 disabled:opacity-50"
              >
                <ArrowPathIcon className="w-5 h-5" />
                Propose Swap
              </button>
              <button
                onClick={() => setIsApproveSwapModalOpen(true)}
                disabled={loading}
                className="flex items-center justify-center gap-2 bg-slate-600 text-white p-4 rounded-lg hover:bg-slate-600/90 disabled:opacity-50"
              >
                <ArrowPathIcon className="w-5 h-5" />
                Approve Swap
              </button>
              <button
                onClick={handleDeleteAccount}
                disabled={loading}
                className="flex items-center justify-center gap-2 bg-error text-white p-4 rounded-lg hover:bg-error/90 disabled:opacity-50"
              >
                <TrashIcon className="w-5 h-5" />
                Delete Account
              </button>
            </div>

            <div className="bg-surface rounded-lg shadow-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Your Lands</h2>
              <LandList userAddress={address} />
            </div>
          </>
        )}

        <SwapModal
          isOpen={isSwapModalOpen}
          onClose={() => setIsSwapModalOpen(false)}
          userAddress={address!}
        />

        <ApproveSwapModal
          isOpen={isApproveSwapModalOpen}
          onClose={() => setIsApproveSwapModalOpen(false)}
        />
      </div>
    </main>
  );
}
