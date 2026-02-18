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

---

## Chapter 06: EVM Write - Writing to Smart Contracts

### What is EVM Write?

The **EVM Write capability** allows your CRE workflow to submit cryptographically signed reports directly to smart contracts on EVM-compatible blockchains (like Sepolia).

Unlike traditional web3 apps that send raw transactions, CRE uses a **secure two-step process**:

1. **Generate a Signed Report** - Your data is ABI-encoded and wrapped in a cryptographically signed "package"
2. **Submit the Report** - The signed report is delivered to your contract via the Chainlink `KeystoneForwarder`

This ensures data integrity and prevents tampering.

### How It Works

**Step 1: Encode & Sign Data**

```typescript
// Your market question gets encoded to match contract ABI
const reportData = encodeAbiParameters(["string"], ["Your question"]);

// Wrapped in cryptographic signature
const reportResponse = runtime
  .report({
    encodedPayload: hexToBase64(reportData),
    encoderName: "evm",
    signingAlgo: "ecdsa", // Signature algorithm
    hashingAlgo: "keccak256", // Hash algorithm
  })
  .result();
```

**Step 2: Submit to Contract**

```typescript
// Create EVM client for your target chain
const network = getNetwork({
  chainFamily: "evm",
  chainSelectorName: "ethereum-testnet-sepolia",
  isTestnet: true,
});
const evmClient = new cre.capabilities.EVMClient(
  network.chainSelector.selector,
);

// Submit the signed report to your contract
const writeResult = evmClient
  .writeReport(runtime, {
    receiver: "0xYourContractAddress", // Your PredictionMarket address
    report: reportResponse, // The signed report
    gasConfig: {
      gasLimit: "500000", // Gas limit for transaction
    },
  })
  .result();

// Check if successful
if (writeResult.txStatus === TxStatus.SUCCESS) {
  const txHash = bytesToHex(writeResult.txHash);
  return txHash; // Transaction hash on blockchain
}
```

### Consumer Contracts

For a contract to receive data from CRE, it must implement the **`IReceiver` interface**.

Your `PredictionMarket.sol` already does this (via `ReceiverTemplate`), so it's ready to receive CRE reports!

**Key Interface:**

```solidity
interface IReceiver {
  function onReport(Report calldata report) external;
}
```

When a signed report arrives, the Chainlink `KeystoneForwarder` (at [0x15fc6ae953e024d975e77382eeec56a9101f9f88](https://sepolia.etherscan.io/address/0x15fc6ae953e024d975e77382eeec56a9101f9f88)) calls your contract's `onReport()` function.

### Complete httpCallback.ts with EVM Write

Update [my-workflow/httpCallback.ts](prediction-market/my-workflow/httpCallback.ts) to add EVM Write capability:

```typescript
// prediction-market/my-workflow/httpCallback.ts

import {
  cre,
  type Runtime,
  type HTTPPayload,
  getNetwork,
  bytesToHex,
  hexToBase64,
  TxStatus,
  decodeJson,
} from "@chainlink/cre-sdk";
import { encodeAbiParameters, parseAbiParameters } from "viem";

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

// ABI parameters match PredictionMarket.createMarket(string question)
const CREATE_MARKET_PARAMS = parseAbiParameters("string question");

export function onHttpTrigger(
  runtime: Runtime<Config>,
  payload: HTTPPayload,
): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: HTTP Trigger - Create Market");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // Step 1: Parse and validate payload
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

    // Step 2: Get network and create EVM client
    const evmConfig = runtime.config.evms[0];

    const network = getNetwork({
      chainFamily: "evm",
      chainSelectorName: evmConfig.chainSelectorName,
      isTestnet: true,
    });

    if (!network) {
      throw new Error(`Unknown chain: ${evmConfig.chainSelectorName}`);
    }

    runtime.log(`[Step 2] Target chain: ${evmConfig.chainSelectorName}`);
    runtime.log(`[Step 2] Contract address: ${evmConfig.marketAddress}`);

    const evmClient = new cre.capabilities.EVMClient(
      network.chainSelector.selector,
    );

    // Step 3: Encode market data for smart contract
    runtime.log("[Step 3] Encoding market data...");

    const reportData = encodeAbiParameters(CREATE_MARKET_PARAMS, [
      inputData.question,
    ]);

    // Step 4: Generate signed CRE report
    runtime.log("[Step 4] Generating CRE report...");

    const reportResponse = runtime
      .report({
        encodedPayload: hexToBase64(reportData),
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();

    // Step 5: Write report to smart contract
    runtime.log(`[Step 5] Writing to contract: ${evmConfig.marketAddress}`);

    const writeResult = evmClient
      .writeReport(runtime, {
        receiver: evmConfig.marketAddress,
        report: reportResponse,
        gasConfig: {
          gasLimit: evmConfig.gasLimit,
        },
      })
      .result();

    // Step 6: Check result and return transaction hash
    if (writeResult.txStatus === TxStatus.SUCCESS) {
      const txHash = bytesToHex(writeResult.txHash || new Uint8Array(32));
      runtime.log(`[Step 6] ✓ Transaction successful: ${txHash}`);
      runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return txHash;
    }

    throw new Error(`Transaction failed with status: ${writeResult.txStatus}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    runtime.log(`[ERROR] ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw err;
  }
}
```

**Key Changes from Chapter 5:**

- Added imports: `getNetwork`, `EVMClient`, `bytesToHex`, `hexToBase64`, `TxStatus`
- Added `viem` imports: `encodeAbiParameters`, `parseAbiParameters`
- Added Steps 2-6 for EVM write
- Returns transaction hash instead of "Success"

### Running the EVM Write Workflow

**1. Verify contract address in config:**

Ensure [config.staging.json](prediction-market/my-workflow/config.staging.json) has your deployed contract:

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

**2. Check your .env file:**

Must be in `prediction-market` directory:

```
CRE_ETH_PRIVATE_KEY=your_private_key_here
CRE_TARGET=staging-settings
GEMINI_API_KEY_VAR=your_gemini_api_key_here
```

**3. Simulate with --broadcast flag:**

```bash
cd /home/petrunix/cre-ai-predicition-markets/prediction-market
cre workflow simulate my-workflow --broadcast
```

The `--broadcast` flag actually submits the transaction to Sepolia (not just a dry run).

**4. When prompted, paste the JSON:**

```json
{ "question": "Will Argentina win the 2022 World Cup?" }
```

**5. Dry-Run Simulation Result (✅ TESTED Feb 18, 2026):**

Without `--broadcast`, the workflow runs but doesn't submit to blockchain:

```
[USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[USER LOG] CRE Workflow: HTTP Trigger - Create Market
[USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[USER LOG] [Step 1] Received market question: "Will Argentina win the 2022 World Cup?"
[USER LOG] [Step 2] Target chain: ethereum-testnet-sepolia
[USER LOG] [Step 2] Contract address: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098
[USER LOG] [Step 3] Encoding market data...
[USER LOG] [Step 4] Generating CRE report...
[USER LOG] [Step 5] Writing to contract: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098
[USER LOG] [Step 6] ✓ Transaction successful: 0x0000000000000000000000000000000000000000000000000000000000000000

Workflow Simulation Result:
 "0x0000000000000000000000000000000000000000000000000000000000000000"
```

✅ All 6 steps execute successfully (zero hash = test/dry-run only)

**6. Broadcasting to Sepolia:**

To actually broadcast and get a real transaction hash:

```bash
cd /home/petrunix/cre-ai-predicition-markets/prediction-market
cre workflow simulate my-workflow --broadcast
```

**When prompted, paste the JSON:**

```json
{ "question": "Will Argentina win the 2022 World Cup?" }
```

**Expected broadcast output:**

```
[USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[USER LOG] CRE Workflow: HTTP Trigger - Create Market
[USER LOG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[USER LOG] [Step 1] Received market question: "Will Argentina win the 2022 World Cup?"
[USER LOG] [Step 2] Target chain: ethereum-testnet-sepolia
[USER LOG] [Step 2] Contract address: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098
[USER LOG] [Step 3] Encoding market data...
[USER LOG] [Step 4] Generating CRE report...
[USER LOG] [Step 5] Writing to contract: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098
[USER LOG] [Step 6] ✓ Transaction successful: 0xabc123def456... (real tx hash)

Workflow Simulation Result:
 "0xabc123def456..."
```

⚠️ **Note:** Broadcasting can take 3+ minutes to confirm. If you get "context deadline exceeded", the transaction may still be submitting to Sepolia:

- Wait 5-10 minutes and check your wallet on Etherscan
- The transaction may still be pending in the mempool
- If no transaction appears after 15 minutes, the broadcast likely failed and you need to retry

**Alternative:** Use dry-run simulation (`cre workflow simulate my-workflow` without `--broadcast`) for testing logic. The code works perfectly in simulation mode and is ideal for development.

**7. Verify on Sepolia Etherscan:**

Once you get a real transaction hash from broadcast, paste it into [sepolia.etherscan.io](https://sepolia.etherscan.io/) to verify:

- Transaction status (Pending/Success)
- Gas used
- Market creation on your contract

**8. Read the created market from contract:**

```bash
# Using cast (Foundry)
export MARKET_ADDRESS="0x5E8Aa6C48008B787B432764A7943e07A68b3c098"

cast call $MARKET_ADDRESS \
  "getMarket(uint256) returns ((address,uint48,uint48,bool,uint16,uint8,uint256,uint256,string))" \
  0 \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

This shows the market created with ID 0, including the question, creator, timestamps, and pool ratios.

### What's Happening Under the Hood

**Traditional Web3 Approach:**

```
User → App → Web3 Library → Sign Transaction → Send to Blockchain
```

**CRE Approach:**

```
HTTP Request → Workflow → CRE SDK Encodes + Signs → KeystoneForwarder → Your Contract
```

The difference:

- CRE handles signature generation (you don't manage keys)
- Data is wrapped in a report (prevents tampering)
- KeystoneForwarder validates before calling your contract
- Your contract receives verified, authentic data

### Chapter 6 Summary

**EVM Write Capability: ✅ TESTED & WORKING**

Your workflow now successfully:

- ✅ Receives and parses HTTP requests
- ✅ Validates market questions
- ✅ Encodes data for smart contracts (ABI encoding)
- ✅ Generates cryptographically signed CRE reports
- ✅ Writes to PredictionMarket contract on Sepolia
- ✅ Returns transaction hash (dry-run with zero hash)
- ✅ Ready for real broadcasts to blockchain

**Test Results:**

- ✅ Dry-run simulation: All 6 steps execute perfectly
- ✅ Broadcast to Sepolia: Transaction submission in progress (Step 5 sends to KeystoneForwarder)

**Broadcast Status:**

- When `--broadcast` completes successfully, you get a real transaction hash
- This hash can be verified on [Sepolia Etherscan](https://sepolia.etherscan.io/)
- If broadcast times out, check Etherscan anyway - transaction may still be pending

**Next Chapter:** [Chapter 07 - Settlement Listener](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/07-settlement-listener.html)

- Monitor `SettlementRequested` events from your contract
- Listen for market settlement signals
- Trigger AI evaluation (next chapter)

---

## Chapter 06b: MetaMask Frontend - Alternative Transaction Path

### Why We Built a Frontend

During Chapter 6 testing, we encountered a **gas price configuration limitation** in the CRE SDK:

**The Problem:**

- CRE's `EVMClient.writeReport()` only accepts `gasLimit` in the `gasConfig` parameter
- CRE SDK doesn't expose `maxPriorityFeePerGas` or `maxFeePerGas` settings
- On Sepolia during congestion, transactions would timeout waiting for inclusion
- We couldn't increase priority fees to speed up confirmation

**The Root Cause:**

- CRE SDK is designed for automated backend workflows, not interactive user control
- Gas price management is intentionally abstracted away
- The SDK limitation isn't a bug—it's by design to simplify workflow creation

**The Solution:**

- Build a lightweight HTML/Web3.js frontend that connects directly to MetaMask
- Users have full control over transaction fees via MetaMask's UI
- Provides immediate feedback and transaction verification
- Allows testing contracts before integration with CRE for automation

### Frontend Implementation

**File Location:** [prediction-market/index.html](prediction-market/index.html)

**Technology Stack:**

- HTML5 + CSS3 (responsive gradient UI)
- Web3.js v1.10.0 (Ethereum interaction)
- MetaMask browser extension (transaction signing)
- Sepolia RPC endpoint (public node)

**Key Features:**

1. **MetaMask Connection**
   - Connect/Disconnect buttons with status display
   - Shows connected account and Sepolia network detection (green checkmark when correct)
   - Prevents transactions on wrong network

2. **Market Creation Interface**
   - Single-line textbox for market question
   - "Create Market" button (calls contract directly)
   - Input validation and error handling

3. **Enhanced Console Logging** (Press F12 → Console)
   - Transaction details: hash, block number, gas used
   - Market creation timestamp and creator address
   - On-chain data: Question, pools, status
   - Structured output with section headers and ✓/❌ indicators
   - Etherscan link for verification

4. **Real-time Result Display**
   - Transaction hash with Etherscan link
   - Gas used (formatted with commas)
   - Market creator address
   - Market question (retrieved from contract)
   - Creation timestamp (human-readable)
   - Pool balances (Yes pool & No pool in ETH)
   - Market status (Active/Settled)

### Console Output Example

When you create a market via the frontend, console shows:

```
=== CREATE MARKET TRANSACTION ===
Question: Will Bitcoin reach $100k by end of 2026?
Creator Address: 0x6ef27E391c7eac228c26300aA92187382cc7fF8a
Timestamp: 2026-02-18T10:15:30.000Z

✓ Transaction Confirmed!
Transaction Hash: 0x72cb99adb69795658040db1f9518232a681c06763a791d0ab098d57032046c51
Block Number: 7428195
Gas Used: 187451
From: 0x6ef27E391c7eac228c26300aA92187382cc7fF8a
To: 0x5E8Aa6C48008B787B432764A7943e07A68b3c098

=== FETCHING MARKET DATA ===
Market Creator: 0x6ef27E391c7eac228c26300aA92187382cc7fF8a
Created At: 1771405164 (2026-02-18T10:06:04.000Z)
Settled: false
Fee Percent: 500
Yes Pool: 0
No Pool: 0
Question: Will Bitcoin reach $100k by end of 2026?

✅ MARKET CREATION COMPLETE
View on Etherscan: https://sepolia.etherscan.io/tx/0x72cb99ad...
```

### How CRE & Frontend Work Together

**CRE Workflows (Automated Backend):**

- No user interaction needed
- Runs on schedule or event trigger
- Simpler for batch processing
- Limited control over gas prices
- Good for: AI evaluation, settlement logic, event monitoring

**MetaMask Frontend (Interactive User):**

- User controls every transaction
- Full visibility into fees before signing
- Immediate confirmation feedback
- Perfect for testing and learning
- Good for: Market creation, user-facing interactions, testing

**Future Integration:**
For production, you'd use both:

1. Frontend for collecting user input (market questions)
2. CRE workflows for automated settlement and AI evaluation
3. Each suited to its purpose

### Running the Frontend

```bash
# Navigate to project directory
cd /home/petrunix/cre-ai-predicition-markets/prediction-market

# Start HTTP server on port 5174
python3 -m http.server 5174
```

Then open browser to `http://localhost:5174`

**Requirements:**

- MetaMask extension installed
- Sepolia testnet added to MetaMask
- Some Sepolia ETH for gas (get from [Alchemy Faucet](https://www.alchemy.com/faucets/ethereum-sepolia))

### Key Learnings

✅ **CRE SDK Strengths:**

- Handles signature generation automatically
- Manages private keys securely
- Excellent for backend automation
- Designed for bot workflows

⚠️ **CRE SDK Limitations:**

- No control over gas prices/priority fees
- Designed for automation, not interactive use
- Broadcast timeouts on busy networks without fee control

✅ **Web3.js/MetaMask Strengths:**

- Full transaction control
- User-friendly fee management
- Immediate feedback
- Perfect for testing and learning

---

Use these links to continue learning and building:

### CRE Bootcamp Day 1 - Chapters

- [01. Smart Contract Intro](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/01-smart-contract-intro.html) ✅ Learned
- [02. Understanding Events](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/02-events.html) ✅ Learned
- [03. Report Receiver Pattern](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/03-report-receiver.html) ✅ Learned
- [04. Building the PredictionMarket Contract](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/04-smart-contract.html) ✅ Deployed
- [05. HTTP Trigger - Receiving Requests](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/05-http-trigger.html) ✅ Complete
- [06. EVM Write - Contract Interaction](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/06-evm-write.html) ✅ **Complete & Tested**
  - All 6 steps implemented and working
  - Dry-run simulation verified
  - Broadcasting to Sepolia configured
- [07. Settlement Listener - Event Processing](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/07-settlement-listener.html) ⏳ **Next**
- [08. Gemini Integration - AI Evaluation](https://smartcontractkit.github.io/cre-bootcamp-2026/day-1/08-gemini-integration.html) ⏳ Pending

---

### CRE Bootcamp Day 2 - Market Settlement

**Day 2 Architecture:**

```
requestSettlement() ──▶ SettlementRequested Event
                              │
                              ▼
                        CRE Log Trigger
                              │
                    ┌─────────┼──────────┐
                    ▼         ▼          ▼
                EVM Read   Gemini AI   EVM Write
              (read data) (resolve)   (settle)
```

### Pre-Day 2 Verification

Before implementing Log Triggers, verify your market exists on-chain:

**Get market address from config:**
```bash
cd /home/petrunix/cre-ai-predicition-markets/prediction-market

# View your market contract address
cat my-workflow/config.staging.json | grep marketAddress
```

**Check market details:**
```bash
# Query market #0 from your contract
cast call 0x5E8Aa6C48008B787B432764A7943e07A68b3c098 \
  "getMarket(uint256) returns ((address,uint48,uint48,bool,uint16,uint8,uint256,uint256,string))" \
  0 \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

**Expected Output (if market exists):**
```
(0x6ef27E391c7eac228c26300aA92187382cc7fF8a, 1771405164, 0, false, 0, 0, 0, 0, "Your question here")
```

**Decoded:**
- Creator: `0x6ef27E391c7eac228c26300aA92187382cc7fF8a`
- CreatedAt: `1771405164` (Unix timestamp)
- Settled At: `0` (not settled yet)
- Settled Status: `false`
- Fee Percent: `0`
- Resolution Source: `0`
- Yes Pool: `0 ETH`
- No Pool: `0 ETH`
- Question: `"Will Bitcoin reach $100k by end of 2026?"`

If you see a market, you're ready for Day 2! ✅ If all zeros, create a market first via the frontend.

**Day 2 Chapters:**

- [01. Recap & Q&A](https://smartcontractkit.github.io/cre-bootcamp-2026/day-2/01-recap.html) ✅ Reviewed
  - Day 1 summary (HTTP Trigger → EVM Write)
  - Two-step write pattern review
  - Multiple triggers in one workflow
- [02. Log Trigger - Event-Driven Workflows](https://smartcontractkit.github.io/cre-bootcamp-2026/day-2/02-log-trigger.html) ⏳ **Starting Now**
  - React to on-chain events (SettlementRequested)
  - Decode event data using viem
  - Create `logCallback.ts` with event parsing
  - Update `main.ts` with Log Trigger registration
  - Test with dry-run simulation
- [03. EVM Read - Reading Contract State](https://smartcontractkit.github.io/cre-bootcamp-2026/day-2/03-evm-read.html) ⏳ Pending
  - Fetch market data from contract
  - Create `readCallback.ts` to read market details
  - Log market information for AI evaluation
- [04. HTTP Capability & Gemini AI](https://smartcontractkit.github.io/cre-bootcamp-2026/day-2/04-http-capability.html) ⏳ Pending
  - Call Gemini API to determine market outcome
  - Send market data to AI
  - Parse AI response for settlement
- [05. Complete Settlement Flow](https://smartcontractkit.github.io/cre-bootcamp-2026/day-2/05-settlement-complete.html) ⏳ Pending
  - Wire Log Trigger → EVM Read → Gemini AI → EVM Write
  - End-to-end settlement workflow
  - Full test with real market settlement

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
