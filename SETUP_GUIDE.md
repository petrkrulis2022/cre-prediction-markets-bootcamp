# CRE AI Prediction Markets - Complete Setup Guide

**Date Created:** February 16, 2026  
**Project:** cre-ai-predicition-markets  
**Environment:** Ubuntu 24.04 LTS

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Steps](#installation-steps)
3. [Verification](#verification)
4. [Environment Configuration](#environment-configuration)
5. [Quick Setup Script](#quick-setup-script)

---

## System Requirements

### OS

- **Ubuntu 24.04 LTS** (upgraded from 20.04)
- GLIBC 2.39+ (required for CRE CLI compatibility)

---

## Installation Steps

### 1. System Update & Ubuntu Upgrade (if needed)

```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# If on Ubuntu 20.04, upgrade to 24.04
sudo sed -i 's/focal/jammy/g' /etc/apt/sources.list
sudo sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list 2>/dev/null
sudo apt update

sudo sed -i 's/jammy/noble/g' /etc/apt/sources.list
sudo sed -i 's/jammy/noble/g' /etc/apt/sources.list.d/*.list 2>/dev/null
sudo apt update

sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y
```

### 2. Node.js v20+ (Status: ✅ v23.11.1)

Node.js usually comes pre-installed on modern Ubuntu. Check:

```bash
node --version
npm --version
```

If not installed:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Bun v1.3+ (Status: ✅ v1.3.9)

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
bun --version
```

### 4. CRE CLI (Status: ✅ v1.0.11)

```bash
curl -sSL https://cre.chain.link/install.sh | bash

# Add to PATH
echo 'export PATH="$HOME/.cre/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

cre version
```

### 5. Foundry / Forge (Status: ✅ v1.5.1-stable)

```bash
# Install foundryup
curl -L https://foundry.paradigm.xyz | bash

# Install Foundry tools
source ~/.bashrc
foundryup

forge --version
```

### 6. Smart Contracts Setup

```bash
# Navigate to project
cd /home/petrunix/cre-ai-predicition-markets/prediction-market

# Initialize forge project
forge init contracts

# Create interfaces directory
cd contracts
mkdir -p src/interfaces
```

### 7. OpenZeppelin Contracts Library (Status: ✅ v5.5.0)

```bash
# In contracts directory
forge install OpenZeppelin/openzeppelin-contracts
```

### 8. Environment Configuration (Status: ✅)

Create `.env` file in `prediction-market/` directory:

```bash
# prediction-market/.env
###############################################################################
### REQUIRED ENVIRONMENT VARIABLES - SENSITIVE INFORMATION                  ###
### DO NOT UPLOAD OR SHARE THIS FILE UNDER ANY CIRCUMSTANCES                ###
###############################################################################

# Ethereum private key (development only!)
CRE_ETH_PRIVATE_KEY=your-eth-private-key

# Gemini API Key
GEMINI_API_KEY=your-gemini-api-key

# Default CRE target
CRE_TARGET=staging-settings
```

**Important:** Add `.env` to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

## Compiling Smart Contracts

After setup, compile all contracts with Forge:

```bash
# Navigate to contracts directory
cd /home/petrunix/cre-ai-predicition-markets/prediction-market/contracts

# Compile all smart contracts
forge build
```

**Expected Output:**

```
Compiling 29 files with Solc 0.8.24
Compiler run successful!
```

This will generate contract artifacts in the `out/` directory and verify that all contracts (IReceiver.sol, ReceiverTemplate.sol, PredictionMarket.sol, Counter.sol) compile without errors.

---

## Deploying Smart Contracts

### Deploy PredictionMarket to Sepolia Testnet

After compilation, deploy the PredictionMarket contract to Sepolia testnet:

```bash
# Navigate to contracts directory
cd /home/petrunix/cre-ai-predicition-markets/prediction-market/contracts

# Load environment variables from .env file
source ../.env

# Deploy PredictionMarket with MockKeystoneForwarder address
forge create src/PredictionMarket.sol:PredictionMarket \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --broadcast \
  --constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88
```

**Parameters Explained:**

- `src/PredictionMarket.sol:PredictionMarket` - Contract to deploy
- `--rpc-url` - Sepolia testnet RPC endpoint
- `--private-key` - Loaded from .env (CRE_ETH_PRIVATE_KEY)
- `--broadcast` - Send transaction to network
- `--constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88` - Chainlink KeystoneForwarder address on Sepolia

**Expected Output:**

```
Deployer: 0x...
Deployed to: 0x...   <-- SAVE THIS ADDRESS!
Transaction hash: 0x...
```

**⚠️ Important:** Save the deployed contract address. You'll need it for:

- Integration with CRE workflows
- Settlement requests
- User interactions

---

## Verification

Run these commands to verify all installations:

```bash
echo "=== Ubuntu Version ==="
cat /etc/os-release | grep VERSION_ID

echo "=== GLIBC Version ==="
ldd --version | head -1

echo "=== Node.js ==="
node --version

echo "=== Bun ==="
bun --version

echo "=== CRE CLI ==="
cre version

echo "=== Foundry Forge ==="
forge --version

echo "=== OpenZeppelin Installed ==="
ls -la contracts/lib/openzeppelin-contracts/
```

**Expected Output:**

```
=== Ubuntu Version ===
VERSION_ID="24.04"

=== GLIBC Version ===
ldd (Ubuntu GLIBC 2.39-...) 2.39

=== Node.js ===
v23.11.1

=== Bun ===
1.3.9

=== CRE CLI ===
cre version v1.0.11

=== Foundry Forge ===
forge Version: 1.5.1-stable

=== OpenZeppelin Installed ===
/home/petrunix/cre-ai-predicition-markets/prediction-market/contracts/lib/openzeppelin-contracts/
```

---

## Environment Configuration

### Directory Structure

```
prediction-market/
├── project.yaml              # CRE project-wide settings
├── secrets.yaml              # CRE secret variable mappings
├── .env                      # Project environment variables (in .gitignore)
├── my-workflow/              # CRE workflow directory
│   ├── workflow.yaml         # Workflow-specific settings
│   ├── main.ts               # Workflow entry point
│   ├── config.staging.json   # Configuration for simulation
│   ├── config.production.json # Configuration for production
│   ├── package.json          # Node.js dependencies
│   ├── tsconfig.json         # TypeScript configuration
│   └── README.md             # Workflow documentation
└── contracts/                # Foundry project (Solidity smart contracts)
    ├── foundry.toml          # Foundry configuration with remappings
    ├── DEPLOYMENTS.md        # Deployed contract details and tracking
    ├── script/               # Deployment scripts (optional)
    ├── src/
    │   ├── PredictionMarket.sol      # Main prediction market contract
    │   ├── Counter.sol               # Sample contract (can be removed)
    │   └── interfaces/               # Smart contract interfaces
    │       ├── IReceiver.sol         # Interface for report receivers
    │       └── ReceiverTemplate.sol  # Abstract receiver with security controls
    ├── test/                 # Unit tests (optional)
    ├── lib/                  # Solidity dependencies
    │   └── openzeppelin-contracts/   # OpenZeppelin library
    └── README.md             # Contract documentation
```

### Key Configuration Files

**foundry.toml** (in `contracts/` directory):

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
```

**.env** (in `prediction-market/` directory):

```
CRE_ETH_PRIVATE_KEY=<your-key>
GEMINI_API_KEY=<your-key>
CRE_TARGET=staging-settings
```

**.gitignore** (should contain):

```
.env
node_modules/
/out
/dist
*.log
```

---

## Quick Setup Script

For future projects, simply run the automated `setup.sh` script:

```bash
chmod +x setup.sh
./setup.sh
```

**The script automatically handles:**

1. System updates
2. Node.js installation (v20+)
3. Bun installation (v1.3+)
4. CRE CLI installation
5. Foundry installation
6. Forge project initialization
7. ProjectStructure creation (src/interfaces)
8. OpenZeppelin Contracts installation
9. **Smart contract file creation:**
   - IReceiver.sol (interface)
   - ReceiverTemplate.sol (abstract contract with security controls)
   - PredictionMarket.sol (main prediction market contract)
10. Environment variables setup (.env)
11. Gitignore configuration
12. Final verification of all installations

### Smart Contract Files Created

The script automatically creates two key contract files:

#### IReceiver.sol

- Simple interface defining the `onReport()` function
- Extends IERC165 for interface introspection
- Contract receivers must implement this interface

#### ReceiverTemplate.sol

- Abstract base contract implementing IReceiver
- Provides flexible security controls:
  - Forwarder-only access (Chainlink validation)
  - Workflow ID validation
  - Workflow author (owner) validation
  - Workflow name validation (with author requirement)
  - Metadata decoding utilities
- Updatable security settings via setter functions
- ERC165 support
- Custom events and error handling

#### PredictionMarket.sol

- Main prediction market smart contract extending ReceiverTemplate
- Implements core prediction market functionality:
  - Create binary prediction markets (Yes/No)
  - Users can make predictions with ETH
  - Request market settlement (triggers CRE workflow)
  - CRE report settles market with AI-determined outcome
  - Users claim winnings based on correct prediction
- Features:
  - Pool-based payout system (winners split total pool)
  - Confidence score tracking for settlement certainty
  - Market metadata (creator, timestamp, question)
  - Custom errors and events for all actions
- Integration with CRE:
  - `_processReport()` handles both market creation and settlement
  - Prefix byte 0x01 routes to settlement, otherwise creates market
  - Full security inherited from ReceiverTemplate

**To add more smart contracts to the automatic setup:**

Edit `setup.sh` and add contract creation blocks in the "Creating smart contract interface files" section:

```bash
# Create IYourContract.sol interface
if [ ! -f "contracts/src/interfaces/IYourContract.sol" ]; then
    echo "📝 Creating IYourContract.sol..."
    cat > contracts/src/interfaces/IYourContract.sol << 'EOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IYourContract {
```

    // Your interface definition here

}
EOL
echo -e "${GREEN}✅ Created IYourContract.sol${NC}"
else
echo "✅ IYourContract.sol already exists"
fi

````

This makes the setup fully automated and reproducible for all team members.

---

## Compiling Smart Contracts

After setup, compile all contracts with Forge:

```bash
# Navigate to contracts directory
cd /home/petrunix/cre-ai-prediciction-markets/prediction-market/contracts

# Compile all smart contracts
forge build
```

**Expected Output:**

```
Compiling 29 files with Solc 0.8.24
Compiler run successful!
```

This will generate contract artifacts in the `out/` directory and verify that all contracts (IReceiver.sol, ReceiverTemplate.sol, PredictionMarket.sol, Counter.sol) compile without errors.

---

## Deploying Smart Contracts

### Deploy PredictionMarket to Sepolia Testnet

After compilation, deploy the PredictionMarket contract to Sepolia testnet:

```bash
# Navigate to contracts directory
cd /home/petrunix/cre-ai-predicicion-markets/prediction-market/contracts

# Load environment variables from .env file
source ../.env

# Deploy PredictionMarket with MockKeystoneForwarder address
forge create src/PredictionMarket.sol:PredictionMarket \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --broadcast \
  --constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88
```

**Parameters Explained:**

- `src/PredictionMarket.sol:PredictionMarket` - Contract to deploy
- `--rpc-url` - Sepolia testnet RPC endpoint
- `--private-key` - Loaded from .env (CRE_ETH_PRIVATE_KEY)
- `--broadcast` - Send transaction to network
- `--constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88` - Chainlink KeystoneForwarder address on Sepolia

**Expected Output:**

```
Deployer: 0x...
Deployed to: 0x...   <-- SAVE THIS ADDRESS!
Transaction hash: 0x...
```

### Example Deployment Results

```
Deployer: 0x6ef27E391c7eac228c26300aA92187382cc7fF8a
Deployed to: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098
Transaction hash: 0xdf34c0d135b25a547c0c392d40cb6ae0dc4060790c43091971f64dac2baa3a8f
```

**Contract Address (Sepolia):** `0x5E8Aa6C48008B787B432764A7943e07A68b3c098`

View on Etherscan: https://sepolia.etherscan.io/address/0x5E8Aa6C48008B787B432764A7943e07A68b3c098

**⚠️ Important:** Save the deployed contract address. You'll need it for:
- Integration with CRE workflows
- Settlement requests
- User interactions

**📋 All deployment details are saved in:** `contracts/DEPLOYMENTS.md`

---

## Post-Deployment: CRE Workflow Integration

After deploying the contract, configure your CRE workflow to use it:

### Update Workflow Configuration

Edit `my-workflow/config.staging.json`:

```json
{
  "geminiModel": "gemini-2.0-flash",
  "evms": [
    {
      "marketAddress": "0x5E8Aa6C48008B787B432764A7943e07A68b3c098",
      "chainSelectorName": "ethereum-testnet-sepolia",
      "gasLimit": "500000"
    }
  ]
}
```

Replace `marketAddress` with your deployed contract address.

**Configuration Reference:**

- `marketAddress` - Your PredictionMarket contract address (from deployment output)
- `chainSelectorName` - Sepolia testnet identifier
- `gasLimit` - Transaction gas limit (500000 is sufficient for markets)

### Next Steps

1. ✅ Contract deployed to Sepolia
2. ✅ Workflow configuration updated with contract address
3. 📌 Ready for HTTP trigger workflows (coming in next chapters)
4. 📌 CRE will orchestrate market creation and settlement

---



All contract deployments are documented in `contracts/DEPLOYMENTS.md`:

- Contract addresses across all networks
- Transaction hashes
- Deployer information
- Deployment dates
- Network details
- Integration links

Keep this file updated when deploying new versions or to additional networks.

---



These may be needed depending on bootcamp requirements:

### Potential Future Installations

```bash
# Hardhat (alternative to Forge)
npm install -g hardhat

# TypeScript support
npm install -g typescript

# Solidity language server
npm install -g @nomicfoundation/solidity-language-server

# Testing libraries
forge install ds-test

# Chainlink contracts (if needed)
forge install smartcontractkit/chainlink

# Uniswap V3 (if needed)
forge install Uniswap/v3-core
````

---

## Troubleshooting

### Issue: "GLIBC version not found"

**Solution:** Ensure Ubuntu 24.04+ with GLIBC 2.38+

```bash
ldd --version
cat /etc/os-release
```

### Issue: "cre command not found"

**Solution:** Add to PATH

```bash
echo 'export PATH="$HOME/.cre/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "forge not found after installation"

**Solution:** Restart terminal or source bashrc

```bash
source ~/.bashrc
foundryup
```

### Issue: ".env not being loaded"

**Solution:** Verify it's in the correct directory and loaded by your application

```bash
cat .env
source .env  # Manual load if needed
```

---

## Summary Checklist

- [x] Ubuntu 24.04 LTS (GLIBC 2.39+)
- [x] Node.js v23.11.1
- [x] Bun v1.3.9
- [x] CRE CLI v1.0.11
- [x] Foundry/Forge v1.5.1-stable
- [x] Smart Contracts initialized with forge
- [x] OpenZeppelin Contracts v5.5.0 installed
- [x] Smart contract interfaces created (IReceiver.sol, ReceiverTemplate.sol)
- [x] PredictionMarket.sol implementation created
- [x] foundry.toml configured with OpenZeppelin remappings
- [x] .env configured with secrets
- [x] .gitignore updated
- [x] Project structure verified and documented
- [x] Smart contracts compiled successfully with forge build
- [x] PredictionMarket.sol deployed to Sepolia (0x5E8Aa6C48008B787B432764A7943e07A68b3c098)
- [x] CRE workflow configuration updated with contract address

---

## Final Verification: What You Now Have

### ✅ Smart Contract Infrastructure

- **PredictionMarket Contract:** `0x5E8Aa6C48008B787B432764A7943e07A68b3c098` (Sepolia)
- **Deployment Status:** Live and verified on Etherscan
- **Security:** Forwarder validation via Chainlink KeystoneForwarder
- **Interface Support:** ERC165 introspection enabled

### ✅ CRE Integration Ready

- **Event Listener:** `SettlementRequested` event that CRE can monitor

  ```solidity
  event SettlementRequested(uint256 indexed marketId, string question);
  ```

  - Triggers when users request market settlement
  - Contains market ID and question for CRE context

- **Report Handler:** `onReport()` function that CRE can call

  ```solidity
  function onReport(bytes calldata metadata, bytes calldata report) external
  ```

  - Receives AI-determined outcomes from CRE
  - Routes settlement reports via `_processReport()`
  - Validates sender via Chainlink Forwarder

- **Settlement Logic:** Market settlement with confidence scores

  ```solidity
  function _settleMarket(bytes calldata report) internal
  ```

  - Processes CRE reports with prediction outcomes
  - Stores confidence scores from AI
  - Marks market as settled for payouts

### ✅ Winner Payout System

- **Pool-Based Payouts:** Fair distribution of winnings

  ```solidity
  uint256 payout = (userAmount * totalPool) / winningPool;
  ```

  - Winners split the total pool proportionally
  - Losers' ETH goes to winners as prize pool
  - Transparent calculation for all participants

- **Claim Function:** Users can withdraw winnings

  ```solidity
  function claim(uint256 marketId) external
  ```

  - Verifies market settled
  - Checks user predicted correctly
  - Transfers ETH payout to claimer

- **Event Tracking:** All payouts logged
  ```solidity
  event WinningsClaimed(uint256 indexed marketId, address indexed claimer, uint256 amount);
  ```

### ✅ End-to-End Workflow

```
1. User creates market → createMarket() event
                          ↓
2. Users make predictions → predict() with ETH
                          ↓
3. User requests settlement → SettlementRequested event (CRE listens)
                          ↓
4. CRE evaluates question → Calls onReport() with outcome
                          ↓
5. Market settled → _settleMarket() processes result
                          ↓
6. Winners claim earnings → claim() transfers payout
                          ↓
7. Event logged → WinningsClaimed event
```

### ✅ Configuration Verified

**Workflow Config:** `my-workflow/config.staging.json`

```json
{
  "marketAddress": "0x5E8Aa6C48008B787B432764A7943e07A68b3c098",
  "chainSelectorName": "ethereum-testnet-sepolia",
  "gasLimit": "500000"
}
```

**Environment:** `prediction-market/.env`

- CRE_ETH_PRIVATE_KEY ✓
- GEMINI_API_KEY ✓
- CRE_TARGET=staging-settings ✓

### ✅ Documentation Complete

- [x] SETUP_GUIDE.md - Full reference guide
- [x] setup.sh - Automated setup script
- [x] DEPLOYMENTS.md - Contract tracking and integration
- [x] config.staging.json - CRE workflow configuration

---

**✨ Your CRE Bootcamp Environment is Complete and Ready! 🚀**

All components are in place for the Chainlink Runtime Environment to:

- Listen for settlement requests
- Evaluate prediction market questions
- Settle markets with AI-determined outcomes
- Enable winner payouts

Next: You're ready for HTTP trigger workflows and market creation automation in the next bootcamp chapters!

---

## Building HTTP Trigger Workflows

Following **[Chapter 05: HTTP Trigger](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/05-http-trigger.html)**, we'll now create a workflow that receives HTTP requests to create prediction markets.

### Step 1: Create httpCallback.ts

Create `my-workflow/httpCallback.ts` to handle incoming HTTP requests:

```typescript
// prediction-market/my-workflow/httpCallback.ts

import {
  cre,
  type Runtime,
  type HTTPPayload,
  decodeJson,
} from "@chainlink/cre-sdk";

// Simple interface for our HTTP payload
interface CreateMarketPayload {
  question: string;
}

type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

export function onHttpTrigger(
  runtime: Runtime<Config>,
  payload: HTTPPayload,
): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: HTTP Trigger - Create Market");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // Step 1: Parse and validate the incoming payload
  if (!payload.input || payload.input.length === 0) {
    runtime.log("[ERROR] Empty request payload");
    return "Error: Empty request";
  }

  const inputData = decodeJson(payload.input) as CreateMarketPayload;
  runtime.log(`[Step 1] Received market question: "${inputData.question}"`);

  if (!inputData.question || inputData.question.trim().length === 0) {
    runtime.log("[ERROR] Question is required");
    return "Error: Question is required";
  }

  // Steps 2-6: EVM Write (covered in next chapter)
  // We'll complete this in the EVM Write chapter

  return "Success";
}
```

**What this does:**

- Receives HTTP POST requests with JSON body
- Extracts market question from payload
- Validates that question is not empty
- Logs processing steps for debugging
- Returns success status for simulation

### Step 2: Update main.ts

Replace the cron trigger in `my-workflow/main.ts` with the HTTP trigger:

```typescript
// prediction-market/my-workflow/main.ts

import { cre, Runner, type Runtime } from "@chainlink/cre-sdk";
import { onHttpTrigger } from "./httpCallback";

type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

const initWorkflow = (config: Config) => {
  const httpCapability = new cre.capabilities.HTTPCapability();
  const httpTrigger = httpCapability.trigger({});

  return [cre.handler(httpTrigger, onHttpTrigger)];
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();
```

**What changed:**

- Removed `CronCapability` (schedule-based trigger)
- Added `HTTPCapability` (request-based trigger)
- Registered `onHttpTrigger` callback to handle HTTP requests
- Updated Config type to match your `config.staging.json`

### Step 3: Test with Workflow Simulation

Test your HTTP trigger workflow locally:

```bash
# Navigate to project root
cd /home/petrunix/cre-ai-predicition-markets/prediction-market

# Run workflow simulation
cre workflow simulate my-workflow
```

**When prompted for input, paste:**

```json
{ "question": "Will Argentina win the 2022 World Cup?" }
```

**Actual test result (✅ PASSED):**

```
Workflow compiled

🔍 HTTP Trigger Configuration:
Please provide JSON input for the HTTP trigger.

Parsed JSON input successfully
Created HTTP trigger payload with 1 fields
2026-02-16T17:32:50Z [SIMULATION] Simulator Initialized
2026-02-16T17:32:50Z [SIMULATION] Running trigger trigger=http-trigger@1.0.0-alpha
2026-02-16T17:32:50Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-16T17:32:50Z [USER LOG] CRE Workflow: HTTP Trigger - Create Market
2026-02-16T17:32:50Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-16T17:32:50Z [USER LOG] [Step 1] Received market question: "Will Argentina win the 2022 World Cup?"

Workflow Simulation Result:
 "Success"

2026-02-16T17:32:50Z [SIMULATION] Execution finished signal received
```

✅ **HTTP Trigger is working correctly!**

### Step 4: Test Error Handling

**Empty question test (✅ PASSED):**

```bash
echo '{"question": ""}' | cre workflow simulate my-workflow
```

**Actual result:**

```
2026-02-16T17:33:18Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-16T17:33:18Z [USER LOG] CRE Workflow: HTTP Trigger - Create Market
2026-02-16T17:33:18Z [USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2026-02-16T17:33:18Z [USER LOG] [Step 1] Received market question: ""
2026-02-16T17:33:18Z [USER LOG] [ERROR] Question is required

Workflow Simulation Result:
 "Error: Question is required"
```

✅ **Validation is working correctly - rejects empty questions!**

### Try Other Market Questions

Once validation is confirmed, test with different predictions:

```json
{ "question": "Will Bitcoin reach $100k by end of 2026?" }
```

```json
{ "question": "Will the Mets win the World Series?" }
```

```json
{ "question": "Will AI systems pass ASI benchmarks by 2027?" }
```

### Files Created

**Status:** ✅ Complete & Tested

- [httpCallback.ts](my-workflow/httpCallback.ts) - HTTP request handler (1.6K)
- [main.ts](my-workflow/main.ts) - Updated with HTTP trigger (626 B)

### Chapter 5 Summary

**HTTP Trigger Workflow: ✅ COMPLETE**

Your workflow now:

- ✅ Receives HTTP POST requests with market questions
- ✅ Validates input (rejects empty questions)
- ✅ Parses JSON payloads
- ✅ Logs processing steps
- ✅ Returns success/error messages

**Next Chapter:** Chapter 06 - EVM Write (Call PredictionMarket contract)

You've now implemented:

- ✅ HTTP request parsing
- ✅ JSON payload decoding
- ✅ Input validation
- ✅ Workflow simulation testing
- ✅ Error handling for edge cases

**Next Chapter:** [06. EVM Write - Contract Interaction](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/06-evm-write.html)

- Call your deployed contract's `createMarket()` function
- Write market data to Sepolia blockchain
- Complete the end-to-end workflow

---

Use these links to continue learning and building:

### CRE Bootcamp Day 1 - Chapters

- [01. Smart Contract Intro](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/01-smart-contract-intro.html)
- [02. Understanding Events](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/02-events.html)
- [03. Report Receiver Pattern](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/03-report-receiver.html)
- [04. Building the PredictionMarket Contract](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/04-smart-contract.html)
- [05. HTTP Trigger - Receiving Requests](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/05-http-trigger.html) ⭐ **Next Chapter**
  - Receive HTTP POST requests to create markets
  - Parse JSON payloads with market questions
  - Simulate workflows with test data
- [06. EVM Write - Contract Interaction](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/06-evm-write.html)
- [07. Settlement Listener - Event Processing](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/07-settlement-listener.html)
- [08. Gemini Integration - AI Evaluation](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/08-gemini-integration.html)

### Official Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/)
- [Chainlink CRE Docs](https://docs.chain.link/cre)
- [Sepolia Testnet Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)
- [Google AI Studio (Gemini)](https://aistudio.google.com/app)

---

## 🎓 Important: This is a Bootcamp Learning Project

### ⚠️ For Future Projects & Real Implementations

**The complete setup in this guide is FOR THE BOOTCAMP ONLY.** This projects follows the CRE bootcamp curriculum with predefined workflows and triggers.

**When building REAL projects, expect to:**

#### Different Workflows

- Bootcamp: Single `my-workflow` following tutorial structure
- **Real Projects:** Multiple workflows for different business logic (e.g., `market-creation-workflow`, `settlement-workflow`, `reporting-workflow`)

#### Different Triggers & Capabilities

- **Bootcamp:** Hardcoded HTTP trigger for receiving market questions
- **Real Projects:** Mix of capabilities depending on use case:
  - `HTTPCapability` - For receiving API requests
  - `CronCapability` - For scheduled tasks (e.g., daily settlement checks)
  - `ContractEventCapability` - For listening to blockchain events
  - `CustomCapability` - For domain-specific integrations

#### Different Configuration

- **Bootcamp:** Simple `config.staging.json` with one contract
- **Real Projects:** Multiple environments (dev/staging/production), multiple contracts, different chain selectors, complex authorization rules

#### Different Handler Structure

- **Bootcamp:** Single `onHttpTrigger` callback
- **Real Projects:** Multiple handler functions per workflow, complex error handling, state management, logging

### What is Reusable?

✅ **Core Infrastructure (Keep for next project):**

- System setup: Ubuntu, Node.js, Bun, CRE CLI, Foundry (SETUP_GUIDE.md Section 1-2)
- Smart contract patterns: Report Receiver interface, IReceiver implementation
- Solidity contracts: Review PredictionMarket.sol for design patterns

❌ **Bootcamp-Specific (Replace for real projects):**

- `prediction-market/my-workflow/` directory structure - Create new workflow directories for each real workflow
- `httpCallback.ts` - Rewrite for your specific business logic
- `main.ts` - Update capability registration for your real triggers
- `config.staging.json` - Create new configs for each environment/workflow

### For Next Project Checklist

When starting a real project, you can reference this guide for:

1. System setup pattern (Node.js, Bun, CRE CLI, Foundry installation)
2. Smart contract structure and deployment patterns
3. Workflow architecture concepts
4. But replace all bootcamp-specific code with your own business logic

---

**✨ CRE Bootcamp Environment Complete! 🚀**

For questions or updates, refer to official documentation:

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/)
- [Chainlink CRE Docs](https://docs.chain.link/cre)
- [Sepolia Testnet Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)
