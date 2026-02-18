// prediction-market/my-workflow/logCallback.ts

import {
  cre,
  type Runtime,
  type EVMLog,
  getNetwork,
  bytesToHex,
  hexToBase64,
  encodeCallMsg,
  TxStatus,
  LAST_FINALIZED_BLOCK_NUMBER,
} from "@chainlink/cre-sdk";
import {
  decodeEventLog,
  parseAbi,
  encodeFunctionData,
  decodeFunctionResult,
  encodeAbiParameters,
  parseAbiParameters,
  zeroAddress,
} from "viem";
import { askGemini } from "./gemini";

type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

interface Market {
  creator: string;
  createdAt: number;
  settledAt: number;
  settled: boolean;
  confidence: number;
  outcome: number;
  totalYesPool: bigint;
  totalNoPool: bigint;
  question: string;
}

// Define the SettlementRequested event ABI
const EVENT_ABI = parseAbi([
  "event SettlementRequested(uint256 indexed marketId, string question)",
]);

// Define the getMarket function ABI for reading
const GET_MARKET_ABI = [
  {
    name: "getMarket",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "marketId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "creator", type: "address" },
          { name: "createdAt", type: "uint48" },
          { name: "settledAt", type: "uint48" },
          { name: "settled", type: "bool" },
          { name: "confidence", type: "uint16" },
          { name: "outcome", type: "uint8" },
          { name: "totalYesPool", type: "uint256" },
          { name: "totalNoPool", type: "uint256" },
          { name: "question", type: "string" },
        ],
      },
    ],
  },
] as const;

// ABI parameters for settlement encoding (outcome as uint8: 0=YES, 1=NO)
const SETTLEMENT_PARAMS = parseAbiParameters(
  "uint256 marketId, uint8 outcome, uint16 confidence",
);

export function onLogTrigger(runtime: Runtime<Config>, log: EVMLog): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: Log Trigger - Settle Market");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Decode the SettlementRequested event
    // ─────────────────────────────────────────────────────────────
    const topics = log.topics.map((t: Uint8Array) => bytesToHex(t)) as [
      `0x${string}`,
      ...`0x${string}`[],
    ];
    const data = bytesToHex(log.data);

    const decodedLog = decodeEventLog({
      abi: EVENT_ABI,
      data,
      topics,
    });

    const marketId = decodedLog.args.marketId as bigint;
    const question = decodedLog.args.question as string;

    runtime.log(`[Step 1] Settlement requested for Market #${marketId}`);
    runtime.log(`[Step 1] Market question: "${question}"`);

    // ─────────────────────────────────────────────────────────────
    // Step 2: Read market details from contract (EVM Read)
    // ─────────────────────────────────────────────────────────────
    runtime.log("[Step 2] Reading market data from contract...");

    const evmConfig = runtime.config.evms[0];
    const network = getNetwork({
      chainFamily: "evm",
      chainSelectorName: evmConfig.chainSelectorName,
      isTestnet: true,
    });

    if (!network) {
      throw new Error(`Unknown chain: ${evmConfig.chainSelectorName}`);
    }

    const evmClient = new cre.capabilities.EVMClient(
      network.chainSelector.selector,
    );

    // Encode the getMarket function call
    const callData = encodeFunctionData({
      abi: GET_MARKET_ABI,
      functionName: "getMarket",
      args: [marketId],
    });

    // Call the contract
    const readResult = evmClient
      .callContract(runtime, {
        call: encodeCallMsg({
          from: zeroAddress,
          to: evmConfig.marketAddress as `0x${string}`,
          data: callData,
        }),
        blockNumber: LAST_FINALIZED_BLOCK_NUMBER,
      })
      .result();

    // Decode the market data
    const market = decodeFunctionResult({
      abi: GET_MARKET_ABI,
      functionName: "getMarket",
      data: bytesToHex(readResult.data),
    }) as Market;

    runtime.log("[Step 2] ✓ Market data retrieved:");
    runtime.log(`  Creator: ${market.creator}`);
    runtime.log(`  Created At: ${market.createdAt}`);
    runtime.log(`  Settled: ${market.settled}`);
    runtime.log(
      `  Yes Pool: ${(Number(market.totalYesPool) / 1e18).toFixed(4)} ETH`,
    );
    runtime.log(
      `  No Pool: ${(Number(market.totalNoPool) / 1e18).toFixed(4)} ETH`,
    );

    // ─────────────────────────────────────────────────────────────
    // Step 3: Check if market is already settled
    // ─────────────────────────────────────────────────────────────
    if (market.settled) {
      runtime.log("[Step 3] Market is already settled, exiting");
      return "Market already settled";
    }

    runtime.log("[Step 3] ✓ Market is active and ready for settlement");

    // ─────────────────────────────────────────────────────────────
    // Step 4: Query Gemini AI for market outcome (HTTP Call)
    // ─────────────────────────────────────────────────────────────
    runtime.log("[Step 4] Calling Gemini AI to determine outcome...");

    const geminiResult = askGemini(runtime, question);

    // Parse Gemini response - extract JSON if wrapped in text
    let aiResponse;
    try {
      aiResponse = JSON.parse(geminiResult.geminiResponse);
    } catch (parseError) {
      // Try to extract JSON from text response
      const jsonMatch = geminiResult.geminiResponse.match(
        /\{[\s\S]*"result"[\s\S]*"confidence"[\s\S]*\}/,
      );
      if (jsonMatch) {
        aiResponse = JSON.parse(jsonMatch[0]);
        runtime.log(`[Step 4] Extracted JSON from text response`);
      } else {
        // Fallback: default to NO if we can't parse
        runtime.log(
          `[Step 4] Warning: Could not parse Gemini JSON, defaulting to NO`,
        );
        aiResponse = { result: "NO", confidence: 0 };
      }
    }

    // Validate result
    if (!["YES", "NO"].includes(aiResponse.result)) {
      throw new Error(
        `Invalid AI result: ${aiResponse.result}. Must be YES or NO.`,
      );
    }
    if (aiResponse.confidence < 0 || aiResponse.confidence > 10000) {
      throw new Error(
        `Invalid confidence: ${aiResponse.confidence}. Must be 0-10000.`,
      );
    }

    // Convert YES/NO to outcome uint8 (0=YES, 1=NO)
    const outcomeValue = aiResponse.result === "YES" ? 0 : 1;
    const confidence = aiResponse.confidence;

    runtime.log(
      `[Step 4] ✓ AI Response: ${aiResponse.result} (confidence: ${confidence}/10000)`,
    );

    // ─────────────────────────────────────────────────────────────
    // Step 5: Write settlement report to contract (EVM Write)
    // ─────────────────────────────────────────────────────────────
    runtime.log("[Step 5] Generating and submitting settlement report...");

    // Encode settlement data (marketId, outcome, confidence)
    const settlementData = encodeAbiParameters(SETTLEMENT_PARAMS, [
      marketId,
      outcomeValue,
      confidence,
    ]);

    // Prepend 0x01 prefix so contract routes to _settleMarket
    const reportData = ("0x01" + settlementData.slice(2)) as `0x${string}`;

    // Generate signed CRE report
    const reportResponse = runtime
      .report({
        encodedPayload: hexToBase64(reportData),
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();

    // Submit to contract via EVM Write
    const writeResult = evmClient
      .writeReport(runtime, {
        receiver: evmConfig.marketAddress,
        report: reportResponse,
        gasConfig: {
          gasLimit: evmConfig.gasLimit,
        },
      })
      .result();

    if (writeResult.txStatus === TxStatus.SUCCESS) {
      const txHash = bytesToHex(writeResult.txHash || new Uint8Array(32));
      runtime.log(`[Step 5] ✓ Transaction successful: ${txHash}`);
      runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      runtime.log("✓ SETTLEMENT COMPLETE");
      runtime.log(`  Market #${marketId}: "${question}"`);
      runtime.log(`  Outcome: ${aiResponse.result} (${outcomeValue})`);
      runtime.log(`  Confidence: ${confidence}/10000`);
      runtime.log(`  Transaction: ${txHash}`);
      runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return txHash;
    }

    throw new Error(`Settlement transaction failed: ${writeResult.txStatus}`);
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    runtime.log(`[ERROR] ${msg}`);
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    throw error;
  }
}
