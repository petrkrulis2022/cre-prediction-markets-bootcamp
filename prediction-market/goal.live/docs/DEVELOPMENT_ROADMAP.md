# goal.live Development Roadmap

**Last Updated:** February 20, 2026  
**Status:** MVP Planning Phase  
**Strategy:** Phased Build with Progressive Integration

---

## 🎯 Read This FIRST

**For Copilot Sessions:**

1. ✅ Understand the **FULL PRODUCT VISION** (Sections 1-3 below)
2. ✅ Build in **PHASES** (Section 4 below)
3. ✅ Phase 1 = Frontend ONLY with ALL mocks (no backend, no contracts, no CRE)
4. ✅ Phases 2-4 = Gradually add real integrations
5. ✅ Stay flexible on mock vs real CRE data (depends on availability)

**This document shows:**

- ✨ What we're building (complete architecture)
- 🔧 How we're building it (phased approach)
- 🎭 What's mocked vs real in each phase

---

# Part 1: FULL PRODUCT VISION

> This is what the complete MVP looks like when finished. We build this incrementally in phases.

## 1.1 Complete Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (React + Vite)                      │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │  Livestream    │  │  Bet Panel   │  │  Static Player List     │ │
│  │  (OBS/force    │  │  (Sepolia    │  │  (11 left, 11 right)    │ │
│  │   unmute)      │  │   USDC)      │  │  Click to bet/change    │ │
│  └────────────────┘  └──────────────┘  └─────────────────────────┘ │
│                                                                       │
│  Services Layer (Mock in Phase 1 → Real in Later Phases):           │
│  - IWalletService (MetaMask)                                         │
│  - IBettingService (Smart Contract or Mock)                          │
│  - IMatchService (CRE or Mock)                                       │
│  - IAudioService (ACR game sync)                                     │
│  - IWorldIDService (Authentication)                                  │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐    ┌──────────────────┐    ┌────────────────────┐
│  BLOCKCHAIN   │    │     BACKEND      │    │   CHAINLINK CRE    │
│  (Sepolia)    │    │   (Supabase)     │    │  (Sports Oracle)   │
├───────────────┤    ├──────────────────┤    ├────────────────────┤
│ • USDC        │    │ • Bet tracking   │    │ • Match data       │
│ • Bonding     │    │ • Match history  │    │ • Player lineups   │
│   Curve       │    │ • Realtime sync  │    │ • Live events      │
│ • Betting     │    │ • AI dashboard   │    │ • Goal confirmations│
│   Contract    │    │ • World ID logs  │    │ • Official results │
│ • Penalty     │    │ • Bookies polls  │    │                    │
│   Logic       │    │                  │    │ (May be mocked)    │
└───────────────┘    └──────────────────┘    └────────────────────┘
```

## 1.2 Complete Tech Stack

| Layer               | Technology            | Purpose                            | Phase Introduced                  |
| ------------------- | --------------------- | ---------------------------------- | --------------------------------- |
| **Frontend**        | React 18 + TypeScript | UI framework                       | Phase 1                           |
|                     | Vite                  | Build tool                         | Phase 1                           |
|                     | ethers.js v6          | Blockchain interactions            | Phase 1 (mocked) / Phase 2 (real) |
|                     | Radix UI / shadcn/ui  | Component library                  | Phase 1                           |
|                     | TailwindCSS           | Styling                            | Phase 1                           |
|                     | ACR Cloud             | Audio fingerprinting for game sync | Phase 1 (mocked) / Phase 3 (real) |
|                     | @worldcoin/idkit      | World ID authentication SDK        | Phase 4                           |
| **Smart Contracts** | Solidity 0.8.x        | Contract language                  | Phase 2                           |
|                     | Hardhat               | Development framework              | Phase 2                           |
|                     | OpenZeppelin          | Security libraries                 | Phase 2                           |
|                     | Sepolia Testnet       | Ethereum test network              | Phase 2                           |
|                     | USDC (testnet)        | Betting currency                   | Phase 2                           |
| **Backend**         | Supabase              | Database + realtime + auth         | Phase 2                           |
|                     | PostgreSQL            | Database engine                    | Phase 2                           |
|                     | Edge Functions        | Serverless API endpoints           | Phase 3                           |
|                     | Row Level Security    | Data access control                | Phase 2                           |
| **Oracle**          | Chainlink CRE         | Sports data oracle                 | Phase 3                           |
|                     | Custom Feed           | Match events delivery              | Phase 3 (mock or real)            |
| **AI/ML**           | PostgreSQL            | Observation data store             | Phase 4                           |
|                     | (Future) Python/TF    | Predictive model training          | Post-MVP                          |
| **DevOps**          | Git                   | Version control                    | All phases                        |
|                     | Vercel / Netlify      | Frontend hosting                   | Phase 1+                          |
|                     | GitHub Actions        | CI/CD                              | Phase 2+                          |

## 1.3 Complete Feature List

### Core Features (MVP)

- ✅ **Live betting on next goal scorer** (USDC on Sepolia)
- ✅ **Unlimited bet changes** with hybrid penalty
- ✅ **Static player list UI** (11 left side, 11 right side)
- ✅ **Force unmute** for ACR audio sync
- ✅ **Provisional balance** during match
- ✅ **Final settlement** post-match
- ✅ **World ID authentication** (3 checkpoints: start, finish, withdrawal)
- ✅ **Historical demo mode** (replay finished match at 10x speed)
- ✅ **AI observational dashboard** (bookies behavior tracking)
- ✅ **Zero balance alerts** (force top-up)

### Penalty System

**Hybrid Formula:** `penalty = base[change_count] × time_decay_multiplier`

| Change # | Base Rate | Example (20' into match) |
| -------- | --------- | ------------------------ |
| 1st      | 3%        | 3% × 0.78 = 2.34%        |
| 2nd      | 5%        | 5% × 0.78 = 3.90%        |
| 3rd      | 8%        | 8% × 0.78 = 6.24%        |
| 4th      | 12%       | 12% × 0.78 = 9.36%       |
| 5th+     | 15%       | 15% × 0.78 = 11.70%      |

**Time Decay:** `1 - (current_minute / 90)`

### Removed Features (Not in MVP)

- ❌ Memecoins (air.fun tokens)
- ❌ Solana blockchain
- ❌ Base L2
- ❌ Match Winner bets
- ❌ Cards/Corners bets
- ❌ Tracking overlay UI
- ❌ Bookies-style odds changes

---

# Part 2: PHASED BUILD STRATEGY

> We build incrementally, starting with mocked frontend to test gameplay.

## Overview Table

| Phase | Duration | Focus           | Backend   | Contracts | CRE             | Output           |
| ----- | -------- | --------------- | --------- | --------- | --------------- | ---------------- |
| **1** | Week 1-2 | Frontend only   | ❌ Mocked | ❌ Mocked | ❌ Mocked       | Playable UI demo |
| **2** | Week 3   | Smart contracts | ✅ Basic  | ✅ Real   | ❌ Mocked       | On-chain betting |
| **3** | Week 4   | Backend + CRE   | ✅ Full   | ✅ Real   | 🎭 Mock or Real | Historical demo  |
| **4** | Week 5   | AI + World ID   | ✅ Full   | ✅ Real   | 🎭 Mock or Real | Full MVP         |

**Legend:**

- ❌ Mocked = Entirely simulated in frontend
- ✅ Real = Fully integrated
- 🎭 Mock or Real = Depends on CRE data availability

---

## Phase 1: Frontend Only (ALL MOCKED)

**Goal:** Build playable frontend to test game experience

**Build Prompt:** [FRONTEND_BUILD_PROMPT.md](./FRONTEND_BUILD_PROMPT.md)

### What to Build

```
✅ React app with all UI components
✅ Static player list (11 left, 11 right)
✅ Bet placement flow
✅ Bet change flow with penalty preview
✅ Mock wallet connection (hardcoded address)
✅ Mock match data (fake players, odds)
✅ Mock bet submission (console.log only)
✅ Mock penalty calculation (frontend-only)
✅ Mock livestream (static video or iframe)
✅ Mock audio sync (simulated game minute)
```

### Mock Service Implementations

**All services return fake data:**

```typescript
// Mock Wallet Service
export class MockWalletService implements IWalletService {
  async connect() {
    return { address: "0xMOCK123...", balance: 1000000000n }; // 1000 USDC
  }
  async getBalance() {
    return 1000000000n;
  }
}

// Mock Betting Service
export class MockBettingService implements IBettingService {
  async placeBet(playerId: string, amount: bigint) {
    console.log("Mock bet placed:", { playerId, amount });
    return { success: true, txHash: "0xMOCK_TX" };
  }
  async getBets(wallet: string) {
    return [
      {
        id: 1,
        playerId: "p1",
        amount: 100000000n,
        odds: 45000,
        changeCount: 0,
      },
    ];
  }
}

// Mock Match Service
export class MockMatchService implements IMatchService {
  async getMatch(id: string) {
    return {
      id,
      homeTeam: "Real Madrid",
      awayTeam: "Barcelona",
      status: "live",
      minute: 23,
      score: { home: 0, away: 0 },
      players: MOCK_PLAYERS, // Hardcoded array
    };
  }
}
```

**No Backend Calls:** Everything runs in browser memory.

**Deliverable:** Playable demo where you can:

- See match and players
- Place bet
- Change bet and see penalty preview
- See balance update (in-memory only)

---

## Phase 2: Smart Contracts + Basic Backend

**Goal:** Real on-chain betting with Sepolia USDC

**Build Prompts:**

- [CONTRACTS_BUILD_PROMPT.md](./CONTRACTS_BUILD_PROMPT.md)
- [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md) (Supabase setup only)

### What to Build

```
✅ GoalLiveBetting.sol smart contract
✅ Hybrid penalty calculation in Solidity
✅ Deploy to Sepolia testnet
✅ Hardhat scripts and tests
✅ Supabase database setup
✅ Basic bet tracking tables
✅ Frontend integration (replace MockBettingService)
```

### Mock vs Real

| Component        | Status    | Details                   |
| ---------------- | --------- | ------------------------- |
| Wallet           | ✅ Real   | MetaMask on Sepolia       |
| USDC             | ✅ Real   | Sepolia testnet USDC      |
| Betting Contract | ✅ Real   | Deployed on Sepolia       |
| Penalty Calc     | ✅ Real   | On-chain calculation      |
| Match Data       | ❌ Mocked | Still hardcoded players   |
| Goal Events      | ❌ Mocked | Manual trigger in UI      |
| CRE Oracle       | ❌ Mocked | Frontend simulates events |

### Supabase Tables Created

- `matches`
- `players`
- `bets`
- `bet_changes`
- `goal_events` (manually inserted for now)

**Deliverable:** Real bets on Sepolia with penalty enforcement

---

## Phase 3: CRE Integration (Mock or Real)

**Goal:** Automated match data and events

**Build Prompt:** [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md) (CRE sections)

### What to Build

```
✅ Chainlink CRE subscription (if available)
✅ Webhook endpoint (Supabase Edge Function)
✅ OR: Mock CRE service with historical data
✅ Historical demo playback system (10x speed)
✅ Realtime event broadcasting to frontend
✅ Provisional balance calculation on goal
```

### Decision Point: Mock vs Real CRE

**Option A: Real CRE Available**

```
✅ Subscribe to live match via CRE API
✅ Receive goal events via webhook
✅ Populate players from CRE lineup data
✅ Get official result from CRE
```

**Option B: CRE Data Limited → Use Mock**

```
🎭 Create MockCREService class
🎭 Load historical match JSON file
🎭 Replay events at 10x speed
🎭 Simulate webhook calls to Supabase
🎭 Frontend receives events via Supabase Realtime
```

**Implementation:**

```typescript
// Service abstraction allows switching
const creService =
  process.env.USE_MOCK_CRE === "true"
    ? new MockCREService()
    : new ChainlinkCREService(creApiKey);
```

**Deliverable:** Automated match playback (real or historical)

---

## Phase 4: AI Dashboard + World ID

**Goal:** Complete MVP with anti-bot and ML foundation

**Build Prompt:** [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md) (AI sections)

### What to Build

```
✅ World ID integration (@worldcoin/idkit)
✅ World ID verification at 3 checkpoints
✅ AI observational dashboard
✅ Bookies API polling service (or mock)
✅ ai_event_observations table
✅ Admin UI for ML insights
✅ CSV export for training data
```

### Mock vs Real

| Component       | Status          | Details                             |
| --------------- | --------------- | ----------------------------------- |
| World ID        | 🎭 Real or Mock | Depends on Sepolia support          |
| Bookies Polling | 🎭 Mock likely  | Most bookies don't have public APIs |
| AI Dashboard    | ✅ Real         | PostgreSQL + basic analytics        |

**Deliverable:** Full MVP with authentication and ML data collection

---

# Part 3: MOCK VS REAL DECISION MATRIX

## 3.1 Always Real (No Mocking)

- ✅ Wallet connection (MetaMask)
- ✅ Blockchain transactions (Sepolia)
- ✅ USDC transfers
- ✅ Penalty calculations (smart contract)
- ✅ Supabase database
- ✅ Realtime subscriptions

## 3.2 Real if Available, Mock Otherwise

- 🎭 **Chainlink CRE** → Depends on API access and data availability
  - Real: Live match subscriptions, official results
  - Mock: Historical JSON replay, simulated events
- 🎭 **World ID** → Depends on Sepolia testnet support
  - Real: Full verification flow
  - Mock: Skip verification, log attempts
- 🎭 **Bookies APIs** → Most don't have public access
  - Real: Poll live odds if API available
  - Mock: Generate random odds fluctuations

## 3.3 Mocked in Phase 1, Real Later

- ⏳ Match data (Phase 1: hardcoded → Phase 3: CRE or mock)
- ⏳ Goal events (Phase 1: manual → Phase 3: CRE webhook)
- ⏳ Betting contract (Phase 1: console.log → Phase 2: Sepolia)
- ⏳ Audio sync (Phase 1: fake minute → Phase 3: ACR integration)

---

# Part 4: INTEGRATION STRATEGY

## 4.1 Service Abstraction Pattern

**All external integrations use interfaces:**

```typescript
// Define interface
export interface IMatchService {
  getMatch(id: string): Promise<Match>;
  subscribeToEvents(id: string, callback: (event: any) => void): () => void;
}

// Mock implementation (Phase 1)
export class MockMatchService implements IMatchService {
  async getMatch(id: string) {
    return HARDCODED_MATCH_DATA;
  }
}

// Real implementation (Phase 3)
export class ChainlinkMatchService implements IMatchService {
  async getMatch(id: string) {
    const response = await fetch(`${CRE_API}/matches/${id}`);
    return response.json();
  }
}

// Switch via environment variable
const matchService: IMatchService =
  import.meta.env.VITE_USE_MOCK_MATCH === "true"
    ? new MockMatchService()
    : new ChainlinkMatchService(apiKey);
```

**Benefits:**

- ✅ Build frontend with mocks immediately
- ✅ Swap implementations without code changes
- ✅ Test both mock and real in parallel
- ✅ Easy rollback if real integration fails

## 4.2 CRE Data Flexibility

**As we build, we discover what CRE data is available:**

### Scenario A: Full CRE Access

```
✅ Use real match subscriptions
✅ Get live player lineups
✅ Receive goal events via webhook
✅ Get official results
```

### Scenario B: Limited CRE Data

```
🎭 Use historical JSON files
🎭 Manually populate player lists
🎭 Replay events from archived data
🎭 Simulate webhook calls
```

### Scenario C: Hybrid

```
✅ Use CRE for pre-match data (lineups, odds)
🎭 Mock live events with historical data
✅ Use CRE for final result verification
```

**Decision made during Phase 3 based on actual availability.**

---

# Part 5: PHASE COMPLETION CRITERIA

## Phase 1 Complete When:

- [ ] UI renders all components
- [ ] Can click player to place mock bet
- [ ] Can change bet and see penalty preview
- [ ] Mock balance updates in UI
- [ ] Livestream iframe displays
- [ ] No console errors

## Phase 2 Complete When:

- [ ] Smart contract deployed on Sepolia
- [ ] MetaMask connects and shows real balance
- [ ] Real USDC bet transaction succeeds
- [ ] On-chain penalty calculated correctly
- [ ] Supabase stores bet records
- [ ] Can query bets via Supabase API

## Phase 3 Complete When:

- [ ] Match data loads (CRE or mock)
- [ ] Goal event triggers (webhook or simulation)
- [ ] Provisional balance updates on goal
- [ ] Historical demo plays at 10x speed
- [ ] Frontend receives realtime events
- [ ] Final settlement processes correctly

## Phase 4 Complete When:

- [ ] World ID prompts at 3 checkpoints (or mocked)
- [ ] AI observations logged to database
- [ ] Admin dashboard displays insights
- [ ] Bookies data collected (real or mock)
- [ ] CSV export works
- [ ] Full user flow tested end-to-end

---

# Part 6: QUICK START FOR COPILOT

**New session? Read in this order:**

1. **This file** → Understand vision + phased approach
2. [MVP_FINAL_SPEC.md](./MVP_FINAL_SPEC.md) → All design decisions
3. **Phase-specific prompt:**
   - Phase 1: [FRONTEND_BUILD_PROMPT.md](./FRONTEND_BUILD_PROMPT.md)
   - Phase 2: [CONTRACTS_BUILD_PROMPT.md](./CONTRACTS_BUILD_PROMPT.md) + [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md)
   - Phase 3: [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md) (CRE sections)
   - Phase 4: [BACKEND_BUILD_PROMPT.md](./BACKEND_BUILD_PROMPT.md) (AI sections)

**Key Principles:**

- 🎯 Build for **complete MVP** (see Part 1)
- 🔧 But **start with Phase 1** (frontend mocks only)
- 🎭 Stay **flexible on mock vs real** (especially CRE)
- 📦 Use **service abstraction** pattern everywhere
- ✅ Complete **one phase fully** before moving to next

---

**Questions?** See [ARCHITECTURE.md](./ARCHITECTURE.md) for technical deep dives.
