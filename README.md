# Land Grab - Decentralized Land Registry System

Land Grab is a decentralized application (dApp) that revolutionizes virtual land ownership and trading using blockchain technology and the what3words addressing system. The project consists of two main components: a blockchain backend for land registration and management, and a modern web frontend for user interaction.

## Project Components

### 1. Land Grab Blockchain (`land-grab-blockchain/`)

The blockchain component consists of smart contracts deployed on the Ethereum network that handle:

- Land registration and ownership
- Land swapping between users
- User account management
- Land metadata storage

#### Smart Contracts

- **LandRegistry**: Manages land ownership and registration

  - Address: `0xA45B1E87AfA000AB7c8B3099A43d57d38Fb8F0D0`
  - Functions: claimLand, releaseLand, getUserLands, getLandDetails

- **LandSwap**: Handles land swap proposals and approvals

  - Address: `0xADbF04c9df2d3c3F9Bb84951DA5cF64Ee5cD8162`
  - Functions: proposeSwap, approveSwap, getPendingSwaps

- **UserRegistry**: Manages user accounts and authentication
  - Address: `0x7f1C5B3C9E8F2A4D6B8C0E1F3A5B7D9E2F4C6A8B`
  - Functions: registerUser, deleteUser, getUserDetails, isUserRegistered

### 2. Land Grab Frontend (`land-grab-frontend/`)

A modern web application built with Next.js that provides:

- User-friendly interface for land management
- Real-time land ownership visualization
- Seamless wallet integration
- Location services integration

## Features

- **Land Claiming**: Claim virtual land parcels using what3words addresses
- **Land Management**: View and manage your owned land parcels
- **Land Swapping**: Propose and approve land swaps with other users
- **User Registration**: Create and manage your user account
- **Account Management**: Delete your account and release all owned lands
- **Location Services**: Get your current location and convert it to what3words

## Tech Stack

### Blockchain

- Solidity
- Foundry
- OpenZeppelin Contracts

### Frontend

- Next.js
- React
- TypeScript
- Tailwind CSS
- wagmi
- RainbowKit
- what3words API
- Sonner

## Getting Started

### Prerequisites

- Node.js (v18 or later)
- npm or yarn
- MetaMask or other Web3 wallet
- what3words API key

### Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   ```

2. Install blockchain dependencies:

   ```bash
   cd land-grab-blockchain
   npm install
   ```

3. Install frontend dependencies:

   ```bash
   cd ../land-grab-frontend
   npm install
   ```

4. Create a `.env.local` file in the frontend directory and add your what3words API key:

   ```
   NEXT_PUBLIC_W3W_API_KEY=your_api_key_here
   ```

5. Start the development servers:

   ```bash
   # In land-grab-blockchain directory
   npm run dev

   # In land-grab-frontend directory
   npm run dev
   ```

6. Open [http://localhost:3000](http://localhost:3000) in your browser

## Project Structure

```
land-grab/
├── land-grab-blockchain/     # Smart contracts and blockchain code
│   ├── contracts/            # Solidity smart contracts
│   ├── scripts/              # Deployment and interaction scripts
│   └── test/                 # Smart contract tests
│
└── land-grab-frontend/       # Web application
    ├── app/                  # Next.js application code
    │   ├── components/       # React components
    │   ├── contracts/        # Smart contract ABIs
    │   ├── api/             # API routes
    │   └── page.tsx         # Main application page
    └── public/              # Static assets
```

## Usage

1. **Connect Wallet**: Click the "Connect Wallet" button to connect your Web3 wallet
2. **Claim Land**:
   - Click "Get Current Location" or enter a what3words address
   - Click "Claim Land" to register the land in your name
3. **View Lands**: Your claimed lands will appear in the "Your Lands" section
4. **Swap Land**:
   - Click "Propose Swap" to open the swap modal
   - Select your land and enter the other party's land details
   - The other party can approve the swap through the "Approve Swap" button
5. **Delete Account**: Use the "Delete Account" button to release all your lands and delete your account

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [what3words](https://what3words.com/) for the addressing system
- [RainbowKit](https://www.rainbowkit.com/) for wallet integration
- [wagmi](https://wagmi.sh/) for Ethereum interaction
- [Next.js](https://nextjs.org/) for the framework
- [Foundry](https://book.getfoundry.sh/) for smart contract development
