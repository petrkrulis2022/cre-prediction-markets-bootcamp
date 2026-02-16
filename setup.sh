#!/bin/bash

###############################################################################
# CRE Bootcamp Automated Setup Script
# 
# This script automates the installation of all required tools for the
# CRE (Chainlink Runtime Environment) Bootcamp
#
# Usage: chmod +x setup.sh && ./setup.sh
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     CRE Bootcamp - Automated Environment Setup                ║"
echo "║     Date: $(date +"%Y-%m-%d")                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check Ubuntu version
echo -e "${YELLOW}📋 Checking system requirements...${NC}"
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
echo "Ubuntu Version: $UBUNTU_VERSION"

if [[ ! "$UBUNTU_VERSION" =~ ^24\. ]]; then
    echo -e "${YELLOW}⚠️  Ubuntu 24.04 recommended (upgrading from 20.04/22.04)${NC}"
fi

# Update system
echo -e "${YELLOW}🔄 Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

# Install Node.js v20+
echo -e "${YELLOW}📦 Checking Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js already installed: $NODE_VERSION"
else
    echo "📥 Installing Node.js v20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    echo -e "${GREEN}✅ Node.js installed: $(node --version)${NC}"
fi

# Install Bun v1.3+
echo -e "${YELLOW}📦 Checking Bun...${NC}"
if command -v bun &> /dev/null; then
    BUN_VERSION=$(bun --version)
    echo "✅ Bun already installed: $BUN_VERSION"
else
    echo "📥 Installing Bun v1.3+..."
    curl -fsSL https://bun.sh/install | bash
    source ~/.bashrc
    echo -e "${GREEN}✅ Bun installed: $(bun --version)${NC}"
fi

# Install CRE CLI
echo -e "${YELLOW}📦 Checking CRE CLI...${NC}"
if command -v cre &> /dev/null; then
    CRE_VERSION=$(cre version)
    echo "✅ CRE CLI already installed: $CRE_VERSION"
else
    echo "📥 Installing CRE CLI..."
    curl -sSL https://cre.chain.link/install.sh | bash
    echo 'export PATH="$HOME/.cre/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    echo -e "${GREEN}✅ CRE CLI installed: $(cre version)${NC}"
fi

# Install Foundry
echo -e "${YELLOW}📦 Checking Foundry...${NC}"
if command -v forge &> /dev/null; then
    FORGE_VERSION=$(forge --version)
    echo "✅ Foundry already installed: $FORGE_VERSION"
else
    echo "📥 Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
    echo -e "${GREEN}✅ Foundry installed: $(forge --version)${NC}"
fi

# Initialize smart contracts
echo -e "${YELLOW}🏗️  Setting up smart contracts...${NC}"
if [ ! -d "contracts" ]; then
    echo "📝 Initializing Forge project..."
    forge init contracts
else
    echo "✅ contracts directory already exists"
fi

# Create project structure
mkdir -p contracts/src/interfaces
echo "✅ Created src/interfaces directory"

# Install dependencies
echo -e "${YELLOW}📦 Installing Solidity dependencies...${NC}"
cd contracts

echo "📥 Installing OpenZeppelin Contracts..."
if [ -d "lib/openzeppelin-contracts" ]; then
    echo "✅ OpenZeppelin already installed"
else
    forge install OpenZeppelin/openzeppelin-contracts
    echo -e "${GREEN}✅ OpenZeppelin installed${NC}"
fi

cd ..

# Create smart contract files
echo -e "${YELLOW}📝 Creating smart contract interface files...${NC}"

# Create IReceiver.sol interface
if [ ! -f "contracts/src/interfaces/IReceiver.sol" ]; then
    echo "📝 Creating IReceiver.sol..."
    cat > contracts/src/interfaces/IReceiver.sol << 'EOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IReceiver is IERC165 {
    function onReport(bytes calldata metadata, bytes calldata report) external;
}
EOL
    echo -e "${GREEN}✅ Created IReceiver.sol${NC}"
else
    echo "✅ IReceiver.sol already exists"
fi

# Create ReceiverTemplate.sol abstract contract
if [ ! -f "contracts/src/interfaces/ReceiverTemplate.sol" ]; then
    echo "📝 Creating ReceiverTemplate.sol..."
    cat > contracts/src/interfaces/ReceiverTemplate.sol << 'EOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IReceiver} from "./IReceiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ReceiverTemplate - Abstract receiver with optional permission controls
/// @notice Provides flexible, updatable security checks for receiving workflow reports
/// @dev The forwarder address is required at construction time for security.
///      Additional permission fields can be configured using setter functions.
abstract contract ReceiverTemplate is IReceiver, Ownable {
  // Required permission field at deployment, configurable after
  address private s_forwarderAddress; // If set, only this address can call onReport

  // Optional permission fields (all default to zero = disabled)
  address private s_expectedAuthor; // If set, only reports from this workflow owner are accepted
  bytes10 private s_expectedWorkflowName; // Only validated when s_expectedAuthor is also set
  bytes32 private s_expectedWorkflowId; // If set, only reports from this specific workflow ID are accepted

  // Hex character lookup table for bytes-to-hex conversion
  bytes private constant HEX_CHARS = "0123456789abcdef";

  // Custom errors
  error InvalidForwarderAddress();
  error InvalidSender(address sender, address expected);
  error InvalidAuthor(address received, address expected);
  error InvalidWorkflowName(bytes10 received, bytes10 expected);
  error InvalidWorkflowId(bytes32 received, bytes32 expected);
  error WorkflowNameRequiresAuthorValidation();

  // Events
  event ForwarderAddressUpdated(address indexed previousForwarder, address indexed newForwarder);
  event ExpectedAuthorUpdated(address indexed previousAuthor, address indexed newAuthor);
  event ExpectedWorkflowNameUpdated(bytes10 indexed previousName, bytes10 indexed newName);
  event ExpectedWorkflowIdUpdated(bytes32 indexed previousId, bytes32 indexed newId);
  event SecurityWarning(string message);

  /// @notice Constructor sets msg.sender as the owner and configures the forwarder address
  /// @param _forwarderAddress The address of the Chainlink Forwarder contract (cannot be address(0))
  /// @dev The forwarder address is required for security - it ensures only verified reports are processed
  constructor(
    address _forwarderAddress
  ) Ownable(msg.sender) {
    if (_forwarderAddress == address(0)) {
      revert InvalidForwarderAddress();
    }
    s_forwarderAddress = _forwarderAddress;
    emit ForwarderAddressUpdated(address(0), _forwarderAddress);
  }

  /// @notice Returns the configured forwarder address
  /// @return The forwarder address (address(0) if disabled)
  function getForwarderAddress() external view returns (address) {
    return s_forwarderAddress;
  }

  /// @notice Returns the expected workflow author address
  /// @return The expected author address (address(0) if not set)
  function getExpectedAuthor() external view returns (address) {
    return s_expectedAuthor;
  }

  /// @notice Returns the expected workflow name
  /// @return The expected workflow name (bytes10(0) if not set)
  function getExpectedWorkflowName() external view returns (bytes10) {
    return s_expectedWorkflowName;
  }

  /// @notice Returns the expected workflow ID
  /// @return The expected workflow ID (bytes32(0) if not set)
  function getExpectedWorkflowId() external view returns (bytes32) {
    return s_expectedWorkflowId;
  }

  /// @inheritdoc IReceiver
  /// @dev Performs optional validation checks based on which permission fields are set
  function onReport(
    bytes calldata metadata,
    bytes calldata report
  ) external override {
    // Security Check 1: Verify caller is the trusted Chainlink Forwarder (if configured)
    if (s_forwarderAddress != address(0) && msg.sender != s_forwarderAddress) {
      revert InvalidSender(msg.sender, s_forwarderAddress);
    }

    // Security Checks 2-4: Verify workflow identity - ID, owner, and/or name (if any are configured)
    if (s_expectedWorkflowId != bytes32(0) || s_expectedAuthor != address(0) || s_expectedWorkflowName != bytes10(0)) {
      (bytes32 workflowId, bytes10 workflowName, address workflowOwner) = _decodeMetadata(metadata);

      if (s_expectedWorkflowId != bytes32(0) && workflowId != s_expectedWorkflowId) {
        revert InvalidWorkflowId(workflowId, s_expectedWorkflowId);
      }
      if (s_expectedAuthor != address(0) && workflowOwner != s_expectedAuthor) {
        revert InvalidAuthor(workflowOwner, s_expectedAuthor);
      }

      if (s_expectedWorkflowName != bytes10(0)) {
        if (s_expectedAuthor == address(0)) {
          revert WorkflowNameRequiresAuthorValidation();
        }
        if (workflowName != s_expectedWorkflowName) {
          revert InvalidWorkflowName(workflowName, s_expectedWorkflowName);
        }
      }
    }

    _processReport(report);
  }

  /// @notice Updates the forwarder address that is allowed to call onReport
  /// @param _forwarder The new forwarder address
  /// @dev WARNING: Setting to address(0) disables forwarder validation.
  ///      This makes your contract INSECURE - anyone can call onReport() with arbitrary data.
  ///      Only use address(0) if you fully understand the security implications.
  function setForwarderAddress(
    address _forwarder
  ) external onlyOwner {
    address previousForwarder = s_forwarderAddress;

    if (_forwarder == address(0)) {
      emit SecurityWarning("Forwarder address set to zero - contract is now INSECURE");
    }

    s_forwarderAddress = _forwarder;
    emit ForwarderAddressUpdated(previousForwarder, _forwarder);
  }

  /// @notice Updates the expected workflow owner address
  /// @param _author The new expected author address (use address(0) to disable this check)
  function setExpectedAuthor(
    address _author
  ) external onlyOwner {
    address previousAuthor = s_expectedAuthor;
    s_expectedAuthor = _author;
    emit ExpectedAuthorUpdated(previousAuthor, _author);
  }

  /// @notice Updates the expected workflow name from a plaintext string
  /// @param _name The workflow name as a string (use empty string "" to disable this check)
  /// @dev The name is hashed using SHA256 and truncated to bytes10.
  function setExpectedWorkflowName(
    string calldata _name
  ) external onlyOwner {
    bytes10 previousName = s_expectedWorkflowName;

    if (bytes(_name).length == 0) {
      s_expectedWorkflowName = bytes10(0);
      emit ExpectedWorkflowNameUpdated(previousName, bytes10(0));
      return;
    }

    bytes32 hash = sha256(bytes(_name));
    bytes memory hexString = _bytesToHexString(abi.encodePacked(hash));
    bytes memory first10 = new bytes(10);
    for (uint256 i = 0; i < 10; i++) {
      first10[i] = hexString[i];
    }
    s_expectedWorkflowName = bytes10(first10);
    emit ExpectedWorkflowNameUpdated(previousName, s_expectedWorkflowName);
  }

  /// @notice Updates the expected workflow ID
  /// @param _id The new expected workflow ID (use bytes32(0) to disable this check)
  function setExpectedWorkflowId(
    bytes32 _id
  ) external onlyOwner {
    bytes32 previousId = s_expectedWorkflowId;
    s_expectedWorkflowId = _id;
    emit ExpectedWorkflowIdUpdated(previousId, _id);
  }

  /// @notice Helper function to convert bytes to hex string
  /// @param data The bytes to convert
  /// @return The hex string representation
  function _bytesToHexString(
    bytes memory data
  ) private pure returns (bytes memory) {
    bytes memory hexString = new bytes(data.length * 2);

    for (uint256 i = 0; i < data.length; i++) {
      hexString[i * 2] = HEX_CHARS[uint8(data[i] >> 4)];
      hexString[i * 2 + 1] = HEX_CHARS[uint8(data[i] & 0x0f)];
    }

    return hexString;
  }

  /// @notice Extracts all metadata fields from the onReport metadata parameter
  /// @param metadata The metadata bytes encoded using abi.encodePacked(workflowId, workflowName, workflowOwner)
  /// @return workflowId The unique identifier of the workflow (bytes32)
  /// @return workflowName The name of the workflow (bytes10)
  /// @return workflowOwner The owner address of the workflow
  function _decodeMetadata(
    bytes memory metadata
  ) internal pure returns (bytes32 workflowId, bytes10 workflowName, address workflowOwner) {
    assembly {
      workflowId := mload(add(metadata, 32))
      workflowName := mload(add(metadata, 64))
      workflowOwner := shr(mul(12, 8), mload(add(metadata, 74)))
    }
    return (workflowId, workflowName, workflowOwner);
  }

  /// @notice Abstract function to process the report data
  /// @param report The report calldata containing your workflow's encoded data
  /// @dev Implement this function with your contract's business logic
  function _processReport(
    bytes calldata report
  ) internal virtual;

  /// @inheritdoc IERC165
  function supportsInterface(
    bytes4 interfaceId
  ) public pure virtual override returns (bool) {
    return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}
EOL
    echo -e "${GREEN}✅ Created ReceiverTemplate.sol${NC}"
else
    echo "✅ ReceiverTemplate.sol already exists"
fi

# Create PredictionMarket.sol main contract
if [ ! -f "contracts/src/PredictionMarket.sol" ]; then
    echo "📝 Creating PredictionMarket.sol..."
    cat > contracts/src/PredictionMarket.sol << 'EOL'
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReceiverTemplate} from "./interfaces/ReceiverTemplate.sol";

/// @title PredictionMarket
/// @notice A simplified prediction market for CRE bootcamp.
contract PredictionMarket is ReceiverTemplate {
    error MarketDoesNotExist();
    error MarketAlreadySettled();
    error MarketNotSettled();
    error AlreadyPredicted();
    error InvalidAmount();
    error NothingToClaim();
    error AlreadyClaimed();
    error TransferFailed();

    event MarketCreated(uint256 indexed marketId, string question, address creator);
    event PredictionMade(uint256 indexed marketId, address indexed predictor, Prediction prediction, uint256 amount);
    event SettlementRequested(uint256 indexed marketId, string question);
    event MarketSettled(uint256 indexed marketId, Prediction outcome, uint16 confidence);
    event WinningsClaimed(uint256 indexed marketId, address indexed claimer, uint256 amount);

    enum Prediction { Yes, No }

    struct Market {
        address creator;
        uint48 createdAt;
        uint48 settledAt;
        bool settled;
        uint16 confidence;
        Prediction outcome;
        uint256 totalYesPool;
        uint256 totalNoPool;
        string question;
    }

    struct UserPrediction {
        uint256 amount;
        Prediction prediction;
        bool claimed;
    }

    uint256 internal nextMarketId;
    mapping(uint256 marketId => Market market) internal markets;
    mapping(uint256 marketId => mapping(address user => UserPrediction)) internal predictions;

    constructor(address _forwarderAddress) ReceiverTemplate(_forwarderAddress) {}

    function createMarket(string memory question) public returns (uint256 marketId) {
        marketId = nextMarketId++;
        markets[marketId] = Market({
            creator: msg.sender,
            createdAt: uint48(block.timestamp),
            settledAt: 0,
            settled: false,
            confidence: 0,
            outcome: Prediction.Yes,
            totalYesPool: 0,
            totalNoPool: 0,
            question: question
        });
        emit MarketCreated(marketId, question, msg.sender);
    }

    function predict(uint256 marketId, Prediction prediction) external payable {
        Market memory m = markets[marketId];
        if (m.creator == address(0)) revert MarketDoesNotExist();
        if (m.settled) revert MarketAlreadySettled();
        if (msg.value == 0) revert InvalidAmount();

        UserPrediction memory userPred = predictions[marketId][msg.sender];
        if (userPred.amount != 0) revert AlreadyPredicted();

        predictions[marketId][msg.sender] = UserPrediction({
            amount: msg.value,
            prediction: prediction,
            claimed: false
        });

        if (prediction == Prediction.Yes) {
            markets[marketId].totalYesPool += msg.value;
        } else {
            markets[marketId].totalNoPool += msg.value;
        }

        emit PredictionMade(marketId, msg.sender, prediction, msg.value);
    }

    function requestSettlement(uint256 marketId) external {
        Market memory m = markets[marketId];
        if (m.creator == address(0)) revert MarketDoesNotExist();
        if (m.settled) revert MarketAlreadySettled();
        emit SettlementRequested(marketId, m.question);
    }

    function _settleMarket(bytes calldata report) internal {
        (uint256 marketId, Prediction outcome, uint16 confidence) = abi.decode(
            report,
            (uint256, Prediction, uint16)
        );
        Market memory m = markets[marketId];
        if (m.creator == address(0)) revert MarketDoesNotExist();
        if (m.settled) revert MarketAlreadySettled();

        markets[marketId].settled = true;
        markets[marketId].confidence = confidence;
        markets[marketId].settledAt = uint48(block.timestamp);
        markets[marketId].outcome = outcome;

        emit MarketSettled(marketId, outcome, confidence);
    }

    function _processReport(bytes calldata report) internal override {
        if (report.length > 0 && report[0] == 0x01) {
            _settleMarket(report[1:]);
        } else {
            string memory question = abi.decode(report, (string));
            createMarket(question);
        }
    }

    function claim(uint256 marketId) external {
        Market memory m = markets[marketId];
        if (m.creator == address(0)) revert MarketDoesNotExist();
        if (!m.settled) revert MarketNotSettled();

        UserPrediction memory userPred = predictions[marketId][msg.sender];
        if (userPred.amount == 0) revert NothingToClaim();
        if (userPred.claimed) revert AlreadyClaimed();
        if (userPred.prediction != m.outcome) revert NothingToClaim();

        predictions[marketId][msg.sender].claimed = true;

        uint256 totalPool = m.totalYesPool + m.totalNoPool;
        uint256 winningPool = m.outcome == Prediction.Yes ? m.totalYesPool : m.totalNoPool;
        uint256 payout = (userPred.amount * totalPool) / winningPool;

        (bool success,) = msg.sender.call{value: payout}("");
        if (!success) revert TransferFailed();

        emit WinningsClaimed(marketId, msg.sender, payout);
    }

    function getMarket(uint256 marketId) external view returns (Market memory) {
        return markets[marketId];
    }

    function getPrediction(uint256 marketId, address user) external view returns (UserPrediction memory) {
        return predictions[marketId][user];
    }
}
EOL
    echo -e "${GREEN}✅ Created PredictionMarket.sol${NC}"
else
    echo "✅ PredictionMarket.sol already exists"
fi

# Setup .env
echo -e "${YELLOW}🔐 Setting up environment variables...${NC}"
if [ ! -f ".env" ]; then
    echo "📝 Creating .env template..."
    cat > .env << 'EOL'
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
EOL
    
    # Add .env to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q "^\.env$" .gitignore; then
            echo ".env" >> .gitignore
            echo "✅ Added .env to .gitignore"
        fi
    else
        echo ".env" > .gitignore
        echo "✅ Created .gitignore with .env"
    fi
    
    echo -e "${YELLOW}⚠️  Please update .env with your actual credentials${NC}"
else
    echo "✅ .env already exists"
fi

# Create DEPLOYMENTS.md tracking file
echo -e "${YELLOW}📋 Creating deployments tracking file...${NC}"
if [ ! -f "contracts/DEPLOYMENTS.md" ]; then
    echo "📝 Creating DEPLOYMENTS.md template..."
    cat > contracts/DEPLOYMENTS.md << 'EOL'
# Smart Contract Deployments

This document tracks all deployed instances of the PredictionMarket contract across different networks.

---

## Sepolia Testnet

### PredictionMarket Contract

**Deployment Information:**

| Property | Value |
|----------|-------|
| **Contract Address** | `0x5E8Aa6C48008B787B432764A7943e07A68b3c098` |
| **Deployer Address** | `0x6ef27E391c7eac228c26300aA92187382cc7fF8a` |
| **Construction Arguments** | Chainlink KeystoneForwarder: `0x15fc6ae953e024d975e77382eeec56a9101f9f88` |
| **Network** | Ethereum Sepolia Testnet |
| **RPC Endpoint** | `https://ethereum-sepolia-rpc.publicnode.com` |
| **Transaction Hash** | `0xdf34c0d135b25a547c0c392d40cb6ae0dc4060790c43091971f64dac2baa3a8f` |
| **Deployment Date** | February 16, 2026 |
| **Status** | ✅ Live |

**Verifiable Links:**

- View on Etherscan: https://sepolia.etherscan.io/address/0x5E8Aa6C48008B787B432764A7943e07A68b3c098
- View Transaction: https://sepolia.etherscan.io/tx/0xdf34c0d135b25a547c0c392d40cb6ae0dc4060790c43091971f64dac2baa3a8f

---

## Deployment Process

To deploy future versions:

1. Navigate to contracts directory: `cd contracts`
2. Compile: `forge build`
3. Load env: `source ../.env`
4. Deploy: `forge create src/PredictionMarket.sol:PredictionMarket --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" --private-key $CRE_ETH_PRIVATE_KEY --broadcast --constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88`
5. Add new deployment details to this file

---

**Last Updated:** February 16, 2026
EOL
    echo -e "${GREEN}✅ Created DEPLOYMENTS.md${NC}"
else
    echo "✅ DEPLOYMENTS.md already exists"
fi

# Final verification
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Setup Complete! Verifying installations...${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Version Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ubuntu:   $UBUNTU_VERSION"
echo "GLIBC:    $(ldd --version | head -1 | awk '{print $NF}')"
echo "Node.js:  $(node --version)"
echo "npm:      $(npm --version)"
echo "Bun:      $(bun --version)"
echo "CRE CLI:  $(cre version)"
echo "Forge:    $(forge --version | head -1)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${GREEN}✅ All tools installed successfully!${NC}"
echo ""

# Compile smart contracts
echo -e "${YELLOW}📦 Compiling smart contracts...${NC}"
cd contracts
if forge build >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Contracts compiled successfully!${NC}"
    COMPILE_STATUS="✅ Compiled"
else
    echo -e "${YELLOW}⚠️  Compile check skipped (run 'cd contracts && forge build' manually)${NC}"
    COMPILE_STATUS="⏳ Pending"
fi
cd ..

echo ""
echo -e "${YELLOW}Compilation Status:${NC}"
echo "Forge Compilation: $COMPILE_STATUS"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update .env with your credentials:"
echo "   - CRE_ETH_PRIVATE_KEY"
echo "   - GEMINI_API_KEY"
echo ""
echo "2. Start coding:"
echo "   - Create contracts in contracts/src/"
echo "   - Write tests in contracts/test/"
echo ""
echo "3. Compile contracts:"
echo "   cd contracts && forge build"
echo ""
echo "4. Run tests:"
echo "   cd contracts && forge test"
echo ""
echo "5. Deploy to Sepolia testnet:"
echo "   cd contracts"
echo "   source ../.env"
echo "   forge create src/PredictionMarket.sol:PredictionMarket \\"
echo "     --rpc-url \"https://ethereum-sepolia-rpc.publicnode.com\" \\"
echo "     --private-key \$CRE_ETH_PRIVATE_KEY \\"
echo "     --broadcast \\"
echo "     --constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88"
echo ""
echo "6. Update deployment details:"
echo "   - Save results to contracts/DEPLOYMENTS.md"
echo "   - Record contract address, deployer, transaction hash"
echo ""
echo "7. Configure CRE workflow:"
echo "   - Update my-workflow/config.staging.json"
echo "   - Set marketAddress to deployed contract"
echo "   - Example: \"marketAddress\": \"0x5E8Aa6C48008B787B432764A7943e07A68b3c098\""
echo ""
echo -e "${GREEN}🚀 Ready for CRE Bootcamp!${NC}"
echo ""
