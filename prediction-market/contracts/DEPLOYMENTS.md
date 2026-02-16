# Smart Contract Deployments

This document tracks all deployed instances of the PredictionMarket contract across different networks.

---

## Sepolia Testnet

### PredictionMarket Contract

**Deployment Information:**

| Property                      | Value                                                                     |
| ----------------------------- | ------------------------------------------------------------------------- |
| **Contract Address**          | `0x5E8Aa6C48008B787B432764A7943e07A68b3c098`                              |
| **Deployer Address**          | `0x6ef27E391c7eac228c26300aA92187382cc7fF8a`                              |
| **Construction Arguments**    | Chainlink KeystoneForwarder: `0x15fc6ae953e024d975e77382eeec56a9101f9f88` |
| **Network**                   | Ethereum Sepolia Testnet                                                  |
| **RPC Endpoint**              | `https://ethereum-sepolia-rpc.publicnode.com`                             |
| **Block Number (Deployment)** | TBD                                                                       |
| **Transaction Hash**          | `0xdf34c0d135b25a547c0c392d40cb6ae0dc4060790c43091971f64dac2baa3a8f`      |
| **Deployment Date**           | February 16, 2026                                                         |
| **Status**                    | ✅ Live                                                                   |

**Verifiable Links:**

- View on Etherscan: https://sepolia.etherscan.io/address/0x5E8Aa6C48008B787B432764A7943e07A68b3c098
- View Transaction: https://sepolia.etherscan.io/tx/0xdf34c0d135b25a547c0c392d40cb6ae0dc4060790c43091971f64dac2baa3a8f
- Deployer Account: https://sepolia.etherscan.io/address/0x6ef27E391c7eac228c26300aA92187382cc7fF8a

**Key Features Enabled:**

- ✅ Binary prediction markets (Yes/No)
- ✅ Pool-based payouts
- ✅ CRE workflow integration via ReceiverTemplate
- ✅ Report processing and settlement
- ✅ Confidence scoring from CRE
- ✅ Winning claim mechanics

---

## Deployment Process

To deploy future versions, follow these steps:

```bash
# 1. Navigate to contracts directory
cd /home/petrunix/cre-ai-predicition-markets/prediction-market/contracts

# 2. Compile contracts
forge build

# 3. Load environment variables
source ../.env

# 4. Deploy PredictionMarket
forge create src/PredictionMarket.sol:PredictionMarket \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --private-key $CRE_ETH_PRIVATE_KEY \
  --broadcast \
  --constructor-args 0x15fc6ae953e024d975e77382eeec56a9101f9f88

# 5. Save the contract address from output
# Format: Deployed to: 0x...
```

**Save new deployment details to this file following the same format.**

---

## Contract Interfaces

### IReceiver

Located in: `src/interfaces/IReceiver.sol`

- Simple interface defining report receiver pattern
- Required function: `onReport(bytes metadata, bytes report)`
- Extends IERC165 for interface introspection

### ReceiverTemplate

Located in: `src/interfaces/ReceiverTemplate.sol`

- Abstract implementation of IReceiver
- Provides Chainlink Forwarder validation
- Supports optional workflow ID, author, and name validation
- Must be extended by concrete implementations (e.g., PredictionMarket)

### PredictionMarket

Located in: `src/PredictionMarket.sol`

- Main prediction market contract
- Extends ReceiverTemplate
- Deployed address: `0x5E8Aa6C48008B787B432764A7943e07A68b3c098` (Sepolia)

---

## Integration with CRE

The deployed contract is ready for integration with Chainlink Runtime Environment (CRE):

### Step 1: Update CRE Workflow Configuration

Update your workflow configuration to reference the deployed contract:

```bash
# Navigate to workflow directory
cd ../my-workflow

# Edit config.staging.json to include contract address
```

### Step 2: Edit config.staging.json

Update `config.staging.json` with the deployed contract address:

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

**Configuration Parameters:**

- `marketAddress` - Your deployed PredictionMarket contract address
- `chainSelectorName` - Network identifier (ethereum-testnet-sepolia for Sepolia)
- `gasLimit` - Gas limit for transactions (500000 is sufficient for prediction markets)

### Integration Flow

1. **Workflow Configuration:** ✅ Set contract address in CRE workflow config (see above)
2. **Report Routing:** ReceiverTemplate routes reports through `_processReport()`
3. **Settlement:** CRE reports trigger market settlement with confidence scores
4. **Claim:** Users can claim winnings after settlement

### What's Next

- HTTP trigger workflows will create markets via the configured contract
- CRE will orchestrate market reports and settlements
- Workflows will process Gemini AI responses for outcome determination

---

## Testing & Verification

### Manual Interaction

Use `cast` (Foundry) to interact with deployed contract:

```bash
# Get market count
cast call 0x5E8Aa6C48008B787B432764A7943e07A68b3c098 \
  "getMarket(uint256)(address,uint48,uint48,bool,uint16,uint8,uint256,uint256,string)" 0 \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"

# Check forwarder address
cast call 0x5E8Aa6C48008B787B432764A7943e07A68b3c098 \
  "s_forwarderAddress()(address)" \
  --rpc-url "https://ethereum-sepolia-rpc.publicnode.com"
```

### Etherscan Verification

Contract source code available for verification on Etherscan:

- https://sepolia.etherscan.io/address/0x5E8Aa6C48008B787B432764A7943e07A68b3c098#code

---

## Security Considerations

### Deployed Security Features

1. **Forwarder Validation:** Only Chainlink KeystoneForwarder can submit reports
2. **Ownership:** Contract owner can update security settings
3. **ERC165 Support:** Interface introspection for safe interactions
4. **Custom Errors:** Gas-efficient error handling

### Future Upgrades

For contract upgrades:

1. Deploy new version
2. Document here with version tag
3. Update CRE workflow configuration to new address
4. Keep historical records

---

## Notes

- **Private Key Management:** Never expose private keys; use .env file (in .gitignore)
- **Test First:** Always test on Sepolia before mainnet
- **Fund Account:** Ensure deployer address has sufficient Sepolia ETH
- **Monitor Transactions:** Use Etherscan to verify all deployments

---

**Last Updated:** February 16, 2026
