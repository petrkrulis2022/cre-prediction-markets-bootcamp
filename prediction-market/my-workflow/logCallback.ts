// prediction-market/my-workflow/logCallback.ts

import { type Runtime, type EVMLog, bytesToHex } from "@chainlink/cre-sdk";
import { decodeEventLog, parseAbi } from "viem";

type Config = {
  geminiModel: string;
  evms: Array<{
    marketAddress: string;
    chainSelectorName: string;
    gasLimit: string;
  }>;
};

// Define the SettlementRequested event ABI
// This matches: event SettlementRequested(uint256 indexed marketId, string question);
const EVENT_ABI = parseAbi([
  "event SettlementRequested(uint256 indexed marketId, string question)",
]);

export function onLogTrigger(runtime: Runtime<Config>, log: EVMLog): string {
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  runtime.log("CRE Workflow: Log Trigger - Settlement Requested");
  runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // ─────────────────────────────────────────────────────────────
    // Step 1: Convert the EVMLog data to hex format for viem
    // ─────────────────────────────────────────────────────────────
    const topics = log.topics.map((t: Uint8Array) => bytesToHex(t)) as [
      `0x${string}`,
      ...`0x${string}`[],
    ];
    const data = bytesToHex(log.data);

    runtime.log("[Step 1] Received event log from blockchain");
    runtime.log(
      `[Step 1] Topics: ${topics.length} (topic[0] is event signature)`,
    );
    runtime.log(`[Step 1] Data length: ${data.length} characters`);

    // ─────────────────────────────────────────────────────────────
    // Step 2: Decode the event using viem
    // ─────────────────────────────────────────────────────────────
    const decodedLog = decodeEventLog({
      abi: EVENT_ABI,
      data,
      topics,
    });

    runtime.log("[Step 2] Event decoded successfully!");

    // ─────────────────────────────────────────────────────────────
    // Step 3: Extract the event arguments
    // ─────────────────────────────────────────────────────────────
    const marketId = decodedLog.args.marketId as bigint;
    const question = decodedLog.args.question as string;

    runtime.log(`[Step 3] Settlement requested for Market #${marketId}`);
    runtime.log(`[Step 3] Market question: "${question}"`);

    // ─────────────────────────────────────────────────────────────
    // Step 4: Log additional event metadata
    // ─────────────────────────────────────────────────────────────
    const contractAddress = bytesToHex(log.address);
    const blockNumber = log.blockNumber;
    const txHash = bytesToHex(log.txHash);

    runtime.log(`[Step 4] Event emitted from: ${contractAddress}`);
    runtime.log(`[Step 4] Block number: ${blockNumber}`);
    runtime.log(`[Step 4] Transaction hash: ${txHash}`);

    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    runtime.log("✓ Ready for settlement workflow!");
    runtime.log("  Next: EVM Read → Gemini AI → EVM Write");
    runtime.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    return `Processed settlement request for Market #${marketId}`;
  } catch (error) {
    runtime.log(`[ERROR] Failed to decode event: ${error}`);
    return "Error processing event";
  }
}
