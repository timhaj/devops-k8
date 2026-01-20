// Backend service to securely resolve RPS games
// Install: npm install express cors web3 body-parser dotenv

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Web3 } = require('web3');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configuration
const PORT = 3000;
const VERSION = 'v1';

// For local Ganache development:
// const RPC_URL = 'http://127.0.0.1:7545';

// For Sepolia testnet:
const RPC_URL = process.env.SEPOLIA_RPC_URL || 'http://127.0.0.1:7545';

const CONTRACT_ADDRESS = '0xF2C0149bD9c12f9A9695FbCeD94bd4067B185522';
const CONTRACT_ABI = require('./build/contracts/RPSBetting.json').abi;

// Web3 setup
const web3 = new Web3(RPC_URL);
const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);

// Owner account setup
let ownerAccount;

// Initialize
async function init() {
    try {
        if (process.env.PRIVATE_KEY) {
            // For Sepolia or any network with private key
            const account = web3.eth.accounts.privateKeyToAccount('0x' + process.env.PRIVATE_KEY);
            web3.eth.accounts.wallet.add(account);
            ownerAccount = account.address;
            console.log('Using private key authentication');
        } else {
            // For local Ganache
            const accounts = await web3.eth.getAccounts();
            ownerAccount = accounts[0];
            console.log('Using Ganache account');
        }

        console.log('Backend initialized with owner account:', ownerAccount);
        console.log('Contract address:', CONTRACT_ADDRESS);
        console.log('Connected to:', RPC_URL);

        // Check contract balance
        const balance = await contract.methods.getContractBalance().call();
        console.log('Contract balance:', web3.utils.fromWei(balance, 'ether'), 'ETH');
    } catch (error) {
        console.error('Initialization error:', error.message);
        process.exit(1);
    }
}

// Store active games (in production, use a database like MongoDB or PostgreSQL)
const activeGames = new Map();

// Endpoint: Notify backend that a game has started
app.post('/api/game/started', async (req, res) => {
    try {
        const { gameId, player, prediction } = req.body;

        console.log(`Game ${gameId} started by ${player}, prediction: ${prediction}`);

        // Store game info
        activeGames.set(gameId, {
            player,
            prediction,
            startTime: Date.now(),
            resolved: false
        });

        res.json({ success: true, message: 'Game registered' });
    } catch (error) {
        console.error('Error registering game:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Resolve a game
app.post('/api/game/resolve', async (req, res) => {
    try {
        const { gameId, winner } = req.body;

        console.log(`Resolving game ${gameId} with winner: ${winner}`);

        if (!activeGames.has(gameId)) {
            return res.status(404).json({ success: false, error: 'Game not found' });
        }

        const game = activeGames.get(gameId);
        if (game.resolved) {
            return res.status(400).json({ success: false, error: 'Game already resolved' });
        }

        // Map winner string to enum
        const winnerMap = { 'rock': 0, 'paper': 1, 'scissors': 2 };
        const winnerEnum = winnerMap[winner.toLowerCase()];

        if (winnerEnum === undefined) {
            return res.status(400).json({ success: false, error: 'Invalid winner' });
        }

        console.log(`Calling smart contract to resolve game ${gameId}: winner is ${winner} (enum: ${winnerEnum})`);

        // Call smart contract to resolve game
        const result = await contract.methods.resolveGame(gameId, winnerEnum).send({
            from: ownerAccount,
            gas: 500000
        });

        console.log(`✅ Game ${gameId} resolved. Transaction: ${result.transactionHash}`);

        // Mark as resolved
        game.resolved = true;
        game.resolvedAt = Date.now();
        game.winner = winner;
        game.txHash = result.transactionHash;

        // Get game details from contract
        const gameDetails = await contract.methods.getGame(gameId).call();
        const playerWon = parseInt(gameDetails.prediction) === winnerEnum;

        console.log(`Player ${playerWon ? 'WON' : 'LOST'} the game`);

        res.json({
            success: true,
            gameId,
            winner,
            playerWon,
            txHash: result.transactionHash
        });
    } catch (error) {
        console.error('Error resolving game:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Get game status
app.get('/api/game/:gameId', async (req, res) => {
    try {
        const gameId = req.params.gameId;

        // Get from blockchain
        const gameDetails = await contract.methods.getGame(gameId).call();

        const elementNames = ['Rock', 'Paper', 'Scissors'];

        res.json({
            success: true,
            game: {
                player: gameDetails.player,
                betAmount: web3.utils.fromWei(gameDetails.betAmount, 'ether'),
                prediction: elementNames[gameDetails.prediction],
                active: gameDetails.active,
                resolved: gameDetails.resolved,
                winner: gameDetails.resolved ? elementNames[gameDetails.winner] : null
            }
        });
    } catch (error) {
        console.error('Error getting game:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Get contract balance
app.get('/api/contract/balance', async (req, res) => {
    try {
        const balance = await contract.methods.getContractBalance().call();
        res.json({
            success: true,
            balance: web3.utils.fromWei(balance, 'ether'),
            balanceWei: balance
        });
    } catch (error) {
        console.error('Error getting balance:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Fund contract (owner only, for testing)
app.post('/api/contract/fund', async (req, res) => {
    try {
        const { amount } = req.body; // amount in ETH

        if (!amount || amount <= 0) {
            return res.status(400).json({ success: false, error: 'Invalid amount' });
        }

        const amountWei = web3.utils.toWei(amount.toString(), 'ether');

        console.log(`Funding contract with ${amount} ETH...`);

        const result = await contract.methods.depositFunds().send({
            from: ownerAccount,
            value: amountWei,
            gas: 500000
        });

        const newBalance = await contract.methods.getContractBalance().call();

        console.log(`✅ Contract funded. New balance: ${web3.utils.fromWei(newBalance, 'ether')} ETH`);

        res.json({
            success: true,
            txHash: result.transactionHash,
            newBalance: web3.utils.fromWei(newBalance, 'ether')
        });
    } catch (error) {
        console.error('Error funding contract:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: List all active games (for debugging)
app.get('/api/games/active', (req, res) => {
    try {
        const games = Array.from(activeGames.entries()).map(([id, game]) => ({
            gameId: id,
            ...game
        }));
        res.json({
            success: true,
            count: games.length,
            games
        });
    } catch (error) {
        console.error('Error listing games:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'RPS Betting Backend is running',
        version: VERSION,
        owner: ownerAccount,
        contract: CONTRACT_ADDRESS,
        network: RPC_URL.includes('sepolia') ? 'Sepolia' :
            RPC_URL.includes('127.0.0.1') ? 'Ganache Local' : 'Unknown',
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, async () => {
    console.log('\n' + '='.repeat(50));
    console.log('🎮 RPS Betting Backend Server');
    console.log('='.repeat(50));
    await init();
    console.log('='.repeat(50));
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
    console.log('='.repeat(50) + '\n');
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n\nShutting down backend server...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n\nShutting down backend server...');
    process.exit(0);
});

// Error handling for uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});