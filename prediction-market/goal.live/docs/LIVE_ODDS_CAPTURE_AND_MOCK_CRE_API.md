# Live Odds Capture & Mock CRE API Strategy for MVP
**Date:** February 2026  
**Purpose:** Building realistic MVP demo by capturing real match odds from The Odds API, storing in Google Sheets/Excel during live match, then creating mock Bookies API with real stats and odds evolution

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [The Odds API Integration](#the-odds-api-integration)
3. [Real-Time Odds Capture Architecture](#real-time-odds-capture-architecture)
4. [Google Sheets Integration](#google-sheets-integration)
5. [Post-Match Data Consolidation](#post-match-data-consolidation)
6. [Mock CRE API Service (using Real Data)](#mock-cre-api-service-using-real-data)
7. [CRE Integration for MVP](#cre-integration-for-mvp)
8. [Implementation Guide](#implementation-guide)
9. [Data Flow Diagrams](#data-flow-diagrams)

---

## Executive Summary

This approach revolutionizes the MVP strategy:

**Traditional Approach (Previous):**
- Use historical match data from ESPN/FBRef
- Manually create odds scenarios
- Limited realism

**New Approach (Live Capture):**
- Run odds capture service during a REAL match
- Store every odds update in Google Sheets
- Capture actual player prop odds evolution
- After match: Consolidate all real data (goals, stats, odds progression)
- Build mock API with REAL DATA - infinitely replayable
- Demo shows how odds actually changed in real market conditions

**Key Advantages:**
✅ Uses actual bookmaker odds (not synthesized)  
✅ Realistic odds evolution patterns  
✅ Shows real market dynamics  
✅ Judges see "this really happened in a real match"  
✅ Perfect for replay-based MVP (judges can run it multiple times)  
✅ Easy to extend for multiple matches

---

## The Odds API Integration

### API Key & Access
```
API Key: 284c2661be564a872e91d8a4bb885ac9
Base URL: https://api.the-odds-api.com/v4
Quota: Paid plan (to be confirmed)
```

### Relevant Endpoints for Live Capture

#### 1. **GET /v4/sports/upcoming**
Get all upcoming matches
```bash
curl "https://api.the-odds-api.com/v4/sports/upcoming/odds/?apiKey=284c2661be564a872e91d8a4bb885ac9&regions=uk&markets=h2h"
```

**Response includes:**
- Event ID (essential!)
- Home & Away teams
- Commence time (kickoff)
- Current bookmaker odds for moneyline (h2h)

#### 2. **GET /v4/sports/{sport}/events/{eventId}/odds**
Get DETAILED odds for a specific match (player props!)
```bash
# Get goalscorer odds for specific match
curl "https://api.the-odds-api.com/v4/sports/soccer_epl/events/{eventId}/odds?\
  apiKey=284c2661be564a872e91d8a4bb885ac9\
  &regions=uk,us\
  &markets=player_goal_scorer,player_assists\
  &oddsFormat=decimal"
```

**Response includes:**
- `bookmakers[]` - array of bookmakers (Betfair, DraftKings, FanDuel, etc.)
- `bookmakers[].markets[]` - array of markets (player_goal_scorer, etc.)
- `bookmakers[].markets[].outcomes[]` - array of players with their odds
- `last_update` - timestamp of odds update

**Example Player Goalscorer Response:**
```json
{
  "id": "abc123def456",
  "sport_key": "soccer_epl",
  "commence_time": "2026-02-21T15:00:00Z",
  "home_team": "Manchester City",
  "away_team": "Newcastle United",
  "bookmakers": [
    {
      "key": "betfair",
      "title": "Betfair",
      "last_update": "2026-02-21T14:55:32Z",
      "markets": [
        {
          "key": "player_goal_scorer",
          "last_update": "2026-02-21T14:55:32Z",
          "outcomes": [
            {
              "name": "Erling Haaland",
              "description": "Manchester City",
              "price": 2.10  // decimal odds (1.10x profit on £1)
            },
            {
              "name": "Julian Alvarez",
              "description": "Manchester City",
              "price": 2.40
            },
            {
              "name": "Bruno Guimaraes",
              "description": "Newcastle United",
              "price": 5.50
            },
            {
              "name": "Alexander Isak",
              "description": "Newcastle United",
              "price": 2.30
            }
          ]
        }
      ]
    }
  ]
}
```

#### 3. **GET /v4/sports/{sport}/scores**
Get LIVE scores as match progresses
```bash
curl "https://api.the-odds-api.com/v4/sports/soccer_epl/scores/?\
  apiKey=284c2661be564a872e91d8a4bb885ac9\
  &daysFrom=0"
```

**Live Response While Match Is In Progress:**
```json
{
  "id": "abc123def456",
  "sport_key": "soccer_epl",
  "sport_title": "EPL",
  "commence_time": "2026-02-21T15:00:00Z",
  "completed": false,
  "home_team": "Manchester City",
  "away_team": "Newcastle United",
  "scores": [
    {
      "name": "Manchester City",
      "score": "2"  // Goals scored
    },
    {
      "name": "Newcastle United",
      "score": "1"
    }
  ],
  "last_update": "2026-02-21T15:34:27Z"
}
```

**After Match Complete:**
```json
{
  "id": "abc123def456",
  "completed": true,
  "home_team": "Manchester City",
  "away_team": "Newcastle United",
  "scores": [
    {
      "name": "Manchester City",
      "score": "3"
    },
    {
      "name": "Newcastle United",
      "score": "1"
    }
  ],
  "last_update": "2026-02-21T17:47:12Z"
}
```

---

## Real-Time Odds Capture Architecture

### Polling Strategy

Run a **polling service** that queries The Odds API at intervals during a live match.

```typescript
// NodJS polling service
import fetch from 'node-fetch';

const ODDS_API_KEY = '284c2661be564a872e91d8a4bb885ac9';
const EVENT_ID = 'abc123def456'; // Manchester City vs Newcastle
const SPORT = 'soccer_epl';
const POLL_INTERVAL = 30000; // 30 seconds - safe interval to avoid rate limits

interface OddsSnapshot {
  timestamp: string;
  eventId: string;
  homeTeam: string;
  awayTeam: string;
  scores: {
    home: number;
    away: number;
  };
  playerOdds: {
    [playerName: string]: {
      team: string;
      odds: number;
      bookmaker: string;
      bookmakerId: string;
    }[];
  };
}

async function captureOddsSnapshot(): Promise<OddsSnapshot> {
  const timestamp = new Date().toISOString();
  
  // 1. Get current scores
  const scoresResponse = await fetch(
    `https://api.the-odds-api.com/v4/sports/${SPORT}/scores?apiKey=${ODDS_API_KEY}`
  );
  const scoresData = await scoresResponse.json();
  const matchData = scoresData.find(m => m.id === EVENT_ID);
  
  // 2. Get current odds from multiple bookmakers
  const oddsResponse = await fetch(
    `https://api.the-odds-api.com/v4/sports/${SPORT}/events/${EVENT_ID}/odds?` +
    `apiKey=${ODDS_API_KEY}` +
    `&regions=uk,us` + // Multiple regions = more bookmakers
    `&markets=player_goal_scorer,player_assists` + // Multiple markets
    `&oddsFormat=decimal`
  );
  const oddsData = await oddsResponse.json();
  
  // 3. Parse and consolidate odds from all bookmakers
  const playerOdds: OddsSnapshot['playerOdds'] = {};
  
  oddsData.bookmakers?.forEach(bookmaker => {
    bookmaker.markets?.forEach(market => {
      if (market.key === 'player_goal_scorer') {
        market.outcomes?.forEach(outcome => {
          const playerName = outcome.name;
          if (!playerOdds[playerName]) {
            playerOdds[playerName] = [];
          }
          
          playerOdds[playerName].push({
            team: outcome.description || 'Unknown',
            odds: outcome.price,
            bookmaker: bookmaker.title,
            bookmakerId: bookmaker.key
          });
        });
      }
    });
  });
  
  return {
    timestamp,
    eventId: EVENT_ID,
    homeTeam: matchData.home_team,
    awayTeam: matchData.away_team,
    scores: {
      home: parseInt(matchData.scores?.[0]?.score || '0'),
      away: parseInt(matchData.scores?.[1]?.score || '0')
    },
    playerOdds
  };
}

// Run polling during match
async function startLiveCapture() {
  console.log(`Starting odds capture for event ${EVENT_ID}`);
  console.log(`Next snapshot every ${POLL_INTERVAL / 1000} seconds`);
  
  const captureInterval = setInterval(async () => {
    try {
      const snapshot = await captureOddsSnapshot();
      console.log(`[${snapshot.timestamp}] Captured odds for ${Object.keys(snapshot.playerOdds).length} players`);
      
      // Send to Google Sheets (see section below)
      await sendToGoogleSheets(snapshot);
      
      // Check if match is complete
      if (snapshot.scores.home > 0 || snapshot.scores.away > 0) {
        // Match is in progress
      } else if (timestamp > kickoffTime + 110 * 60000) {
        // Match likely ended (90+ mins + stoppage time)
        console.log('Match appears to be complete. Stopping capture.');
        clearInterval(captureInterval);
      }
    } catch (error) {
      console.error('Capture error:', error);
    }
  }, POLL_INTERVAL);
}
```

### Rate Limiting Considerations

**The Odds API Rate Limits:**
- Cost: 1 credit per region per market
- Each call: 2 regions × 2 markets = 4 credits
- 30-second poll = 120 calls/hour = 480 credits/hour
- Safe plan: Premium plan (5000+ credits/month)

**Optimization:**
```typescript
// Reduce overhead: rotate which bookmakers you query
const bookmakerSample = ['betfair', 'draftkings', 'fanduel']; // 3 instead of all 15

// Use single market per poll, rotate
const markets = ['player_goal_scorer', 'player_assists'];
let currentMarketIndex = 0;

const market = markets[currentMarketIndex % markets.length];
currentMarketIndex++;

// Cost: 1 region × 1 market = 1 credit per poll
// 30-second poll = 120 credits/hour = much more sustainable
```

---

## Google Sheets Integration

### Why Google Sheets?
- Real-time collaboration (you can watch odds update live)
- Built-in charts (visualize odds movements)
- Easy export to JSON for mock API
- No database setup needed for MVP

### Setup Steps

#### 1. **Create Google Sheet**
Name: `goal-live-match-odds-{date}`

Columns:
```
| Timestamp | Event_ID | Home_Team | Away_Team | Home_
Score | Away_Score | Player_Name | Team | Odds | Bookmaker | Bookmaker_ID |
|-----------|----------|-----------|-----------|-------|-----------|------------|------|------|----------|-------------------|
```

#### 2. **Google Sheets API with TypeScript**

```typescript
import { google } from 'googleapis';
import * as fs from 'fs';

const sheets = google.sheets('v4');
const SHEET_ID = 'YOUR_GOOGLE_SHEET_ID'; // From URL: docs.google.com/spreadsheets/d/{SHEET_ID}/edit

// Authenticate (one-time setup)
async function authenticateSheets() {
  const auth = new google.auth.GoogleAuth({
    keyFile: './credentials.json', // Service account JSON from Google Cloud
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  return auth;
}

async function appendOddsSnapshot(snapshot: OddsSnapshot) {
  const auth = await authenticateSheets();
  
  // Flatten the hierarchical odds data into rows
  const rows: any[] = [];
  
  Object.entries(snapshot.playerOdds).forEach(([playerName, oddsArray]) => {
    oddsArray.forEach(oddData => {
      rows.push([
        snapshot.timestamp,
        snapshot.eventId,
        snapshot.homeTeam,
        snapshot.awayTeam,
        snapshot.scores.home,
        snapshot.scores.away,
        playerName,
        oddData.team,
        oddData.odds,
        oddData.bookmaker,
        oddData.bookmakerId
      ]);
    });
  });
  
  // Append rows (A1:K notation means columns A through K)
  await sheets.spreadsheets.values.append({
    auth,
    spreadsheetId: SHEET_ID,
    range: 'Sheet1!A:K',
    valueInputOption: 'RAW',
    requestBody: {
      values: rows
    }
  });
  
  console.log(`Appended ${rows.length} rows to Google Sheet`);
}
```

#### 3. **Alternative: Excel with Python**

```python
import openpyxl
from openpyxl.utils import get_column_letter
from datetime import datetime
import requests

EXCEL_FILE = './goal_live_match_odds.xlsx'
API_KEY = '284c2661be564a872e91d8a4bb885ac9'

def append_odds_to_excel(snapshot: dict):
    """Append odds snapshot to Excel file"""
    
    # Load or create workbook
    try:
        wb = openpyxl.load_workbook(EXCEL_FILE)
        ws = wb.active
        next_row = ws.max_row + 1
    except FileNotFoundError:
        wb = openpyxl.Workbook()
        ws = wb.active
        next_row = 1
        
        # Add headers
        headers = [
            'Timestamp', 'Event_ID', 'Home_Team', 'Away_Team', 
            'Home_Score', 'Away_Score', 'Player_Name', 'Team', 
            'Odds', 'Bookmaker', 'Bookmaker_ID'
        ]
        for col, header in enumerate(headers, 1):
            ws.cell(row=1, column=col, value=header)
        next_row = 2
    
    # Append odds rows
    for player_name, odds_array in snapshot['playerOdds'].items():
        for odds_data in odds_array:
            row_data = [
                snapshot['timestamp'],
                snapshot['eventId'],
                snapshot['homeTeam'],
                snapshot['awayTeam'],
                snapshot['scores']['home'],
                snapshot['scores']['away'],
                player_name,
                odds_data['team'],
                odds_data['odds'],
                odds_data['bookmaker'],
                odds_data['bookmakerId']
            ]
            
            for col, value in enumerate(row_data, 1):
                ws.cell(row=next_row, column=col, value=value)
            
            next_row += 1
    
    wb.save(EXCEL_FILE)
    print(f"Appended {len(odds_array)} rows to {EXCEL_FILE}")
```

### Expected Data Structure After Match

**Google Sheets will contain:**
```
Timestamp                | Event_ID | Home_Team        | Away_Team         | Home_Score | Away_Score | Player_Name      | Team             | Odds | Bookmaker | Bookmaker_ID
2026-02-21T14:55:00Z    | abc123   | Manchester City  | Newcastle United  | 0          | 0          | Erling Haaland   | Manchester City  | 2.10 | Betfair   | betfair
2026-02-21T14:55:00Z    | abc123   | Manchester City  | Newcastle United  | 0          | 0          | Julian Alvarez   | Manchester City  | 2.40 | Betfair   | betfair
2026-02-21T14:55:00Z    | abc123   | Manchester City  | Newcastle United  | 0          | 0          | Alexander Isak   | Newcastle         | 2.30 | Betfair   | betfair
...
2026-02-21T15:10:00Z    | abc123   | Manchester City  | Newcastle United  | 1          | 0          | Erling Haaland   | Manchester City  | 1.20 | Betfair   | betfair  <- odds dropped after he scored!
2026-02-21T15:10:00Z    | abc123   | Manchester City  | Newcastle United  | 1          | 0          | Julian Alvarez   | Manchester City  | 2.30 | Betfair   | betfair
...
```

---

## Post-Match Data Consolidation

After the match is complete (final whistle), consolidate all captured data into a **match profile**.

### Step 1: Export Google Sheets → JSON

```typescript
// Export Google Sheet to structured JSON
async function exportMatchProfile(): Promise<MatchProfile> {
  const auth = await authenticateSheets();
  
  const result = await sheets.spreadsheets.values.get({
    auth,
    spreadsheetId: SHEET_ID,
    range: 'Sheet1!A:K'
  });
  
  const [headers, ...rows] = result.data.values;
  
  // Parse into structured format
  const matchProfile: MatchProfile = {
    metadata: {
      eventId: rows[0][1],
      homeTeam: rows[0][2],
      awayTeam: rows[0][3],
      kickoffTime: rows[0][0],
      finalScore: {
        home: rows[rows.length - 1][4],
        away: rows[rows.length - 1][5]
      }
    },
    oddsTimeseries: [],
    goalscorers: [],
    playersOnPitch: {}
  };
  
  // Group by timestamp (each snapshot in time)
  const snapshotsByTime = new Map();
  
  rows.forEach(row => {
    const timestamp = row[0];
    if (!snapshotsByTime.has(timestamp)) {
      snapshotsByTime.set(timestamp, []);
    }
    snapshotsByTime.get(timestamp).push({
      homeScore: parseInt(row[4]),
      awayScore: parseInt(row[5]),
      playerName: row[6],
      team: row[7],
      odds: parseFloat(row[8]),
      bookmaker: row[9]
    });
  });
  
  // Convert to timeseries
  snapshotsByTime.forEach((odds, timestamp) => {
    matchProfile.oddsTimeseries.push({
      timestamp,
      playerOdds: odds.reduce((acc, o) => {
        acc[o.playerName] = {
          team: o.team,
          odds: o.odds,
          bookmaker: o.bookmaker
        };
        return acc;
      }, {})
    });
  });
  
  return matchProfile;
}

interface MatchProfile {
  metadata: {
    eventId: string;
    homeTeam: string;
    awayTeam: string;
    kickoffTime: string;
    finalScore: { home: number; away: number };
  };
  oddsTimeseries: Array<{
    timestamp: string;
    playerOdds: Record<string, { team: string; odds: number; bookmaker: string }>;
  }>;
  goalscorers: Array<{ minute: number; player: string; team: string }>;
  playersOnPitch: Record<string, { team: string; subOffMinute?: number }>;
}
```

### Step 2: Enrich with Match Stats

You'll need to manually (or via API) add:
- **Goalscorers** - which players scored and at which minute
- **Lineups** - starting 11 and all substitutes
- **Substitutions** - who came off/on at which minute
- **Cards** - yellow/red cards if tracking player prop odds

```typescript
// Enriched match profile
const enrichedProfile: MatchProfile = {
  ...exportedProfile,
  
  goalscorers: [
    { minute: 12, player: 'Erling Haaland', team: 'Manchester City' },
    { minute: 34, player: 'Julian Alvarez', team: 'Manchester City' },
    { minute: 67, player: 'Erling Haaland', team: 'Manchester City' },
    { minute: 55, player: 'Alexander Isak', team: 'Newcastle United' }
  ],
  
  playersOnPitch: {
    'Erling Haaland': { team: 'Manchester City', subOffMinute: 75 },
    'Julian Alvarez': { team: 'Manchester City', subOffMinute: undefined },
    'Bruno Guimaraes': { team: 'Newcastle United', subOffMinute: 68 },
    'Alexander Isak': { team: 'Newcastle United', subOffMinute: undefined },
    // ... all 22 starting players
  }
};
```

### Step 3: Save as JSON

```bash
# Save for use in mock API
cat > /home/petrunix/cre-ai-predicition-markets/prediction-market/goal.live/data/match-profiles/man-city-vs-newcastle-2026-02-21.json << 'EOF'
{
  "metadata": {
    "eventId": "abc123def456",
    "homeTeam": "Manchester City",
    "awayTeam": "Newcastle United",
    "kickoffTime": "2026-02-21T15:00:00Z",
    "finalScore": { "home": 3, "away": 1 }
  },
  "oddsTimeseries": [
    {
      "timestamp": "2026-02-21T14:55:00Z",
      "score": { "home": 0, "away": 0 },
      "playerOdds": {
        "Erling Haaland": { "odds": 2.10, "team": "Manchester City" },
        "Julian Alvarez": { "odds": 2.40, "team": "Manchester City" },
        "Alexander Isak": { "odds": 2.30, "team": "Newcastle United" }
      }
    },
    {
      "timestamp": "2026-02-21T15:10:00Z",
      "score": { "home": 1, "away": 0 },
      "playerOdds": {
        "Erling Haaland": { "odds": 1.20, "team": "Manchester City" },
        "Julian Alvarez": { "odds": 2.30, "team": "Manchester City" },
        "Alexander Isak": { "odds": 2.30, "team": "Newcastle United" }
      }
    }
  ],
  "goalscorers": [
    { "minute": 12, "player": "Erling Haaland", "team": "Manchester City" },
    { "minute": 34, "player": "Julian Alvarez", "team": "Manchester City" },
    { "minute": 55, "player": "Alexander Isak", "team": "Newcastle United" },
    { "minute": 67, "player": "Erling Haaland", "team": "Manchester City" }
  ]
}
EOF
```

---

## Mock CRE API Service (using Real Data)

Now that you have real match data with actual odds evolution, build the mock API.

### Architecture

```
┌─────────────────────────────────────────────┐
│        Frontend (React)                      │
│  - "Place Bet" button                        │
│  - Odds display (updates as match progresses)│
└────────────────┬────────────────────────────┘
                 │
                 ▼ HTTP GET /api/odds
┌─────────────────────────────────────────────┐
│   MockCREService (Uses Real Data)            │
│  - Loads match profile JSON                  │
│  - Simulates time progression                │
│  - Returns historical odds at any minute     │
│  - Tracks goal events (when they happened)   │
└────────────────┬────────────────────────────┘
                 │
                 ▼
        Match Profile JSON
         (real match data)
```

### Mock CRE API Implementation

```typescript
// mockCREService.ts
import matchProfile from './data/match-profiles/man-city-vs-newcastle-2026-02-21.json';

interface MockCREService {
  setupMatch(): void;
  getCurrentOdds(atMinute: number): Record<string, number>;
  getMatchState(atMinute: number): { score: { home: number; away: number }; minute: number };
  getGoalEvents(beforeMinute: number): Array<{ minute: number; player: string; team: string }>;
  progressTime(newMinute: number): void;
  resetMatch(): void;
}

class LiveOddsMockCREService implements MockCREService {
  private currentMinute: number = 0;
  private matchData = matchProfile;
  
  setupMatch(): void {
    this.currentMinute = 0;
    console.log(`Match set up: ${this.matchData.metadata.homeTeam} vs ${this.matchData.metadata.awayTeam}`);
  }
  
  progressTime(newMinute: number): void {
    if (newMinute < 0 || newMinute > 90) {
      throw new Error('Invalid minute: must be 0-90');
    }
    this.currentMinute = newMinute;
  }
  
  /**
   * Get odds at specific minute from historical timeseries
   * Interpolates if exact minute not captured
   */
  getCurrentOdds(atMinute: number): Record<string, number> {
    // Find closest timestamp at or before requested minute
    const relevantSnapshots = this.matchData.oddsTimeseries.filter(snapshot => {
      const minuteInSnapshot = this.timestampToMinute(snapshot.timestamp);
      return minuteInSnapshot <= atMinute;
    });
    
    if (relevantSnapshots.length === 0) {
      throw new Error(`No odds data available at minute ${atMinute}`);
    }
    
    const closestSnapshot = relevantSnapshots[relevantSnapshots.length - 1];
    const odds: Record<string, number> = {};
    
    // Build odds object, adjusting for goals that happened AFTER this snapshot
    Object.entries(closestSnapshot.playerOdds).forEach(([playerName, oddsData]) => {
      let adjustedOdds = oddsData.odds;
      
      // Check if this player scored before the requested minute
      const goals = this.getGoalEvents(atMinute);
      const playerScored = goals.some(g => g.player === playerName);
      
      if (playerScored) {
        // Player who already scored: odds drop dramatically (15% of original)
        adjustedOdds = oddsData.odds * 0.15;
      }
      
      // Check if player is still on pitch at this minute
      const isOnPitch = this.isPlayerOnPitch(playerName, atMinute);
      
      if (isOnPitch) {
        odds[playerName] = adjustedOdds;
      }
    });
    
    return odds;
  }
  
  getMatchState(atMinute: number): { score: { home: number; away: number }; minute: number } {
    // Find score at this minute by counting goals before it
    const goalsBeforeMinute = this.getGoalEvents(atMinute);
    
    const score = { home: 0, away: 0 };
    goalsBeforeMinute.forEach(goal => {
      if (goal.team === this.matchData.metadata.homeTeam) {
        score.home++;
      } else {
        score.away++;
      }
    });
    
    return { score, minute: atMinute };
  }
  
  getGoalEvents(beforeMinute: number): Array<{ minute: number; player: string; team: string }> {
    return this.matchData.goalscorers.filter(goal => goal.minute <= beforeMinute);
  }
  
  resetMatch(): void {
    this.currentMinute = 0;
  }
  
  private timestampToMinute(timestamp: string): number {
    // Convert ISO timestamp to minutes from kickoff
    const kickoffTime = new Date(this.matchData.metadata.kickoffTime);
    const snapshotTime = new Date(timestamp);
    const elapsedMs = snapshotTime.getTime() - kickoffTime.getTime();
    return Math.floor(elapsedMs / 60000); // Convert to minutes
  }
  
  private isPlayerOnPitch(playerName: string, atMinute: number): boolean {
    // Check if player was subbed off before this minute
    const substitutions = this.matchData.substitutions || [];
    const subOffAtMinute = substitutions.find(s => s.playerOff === playerName)?.minute;
    
    return !subOffAtMinute || subOffAtMinute > atMinute;
  }
}

export default new LiveOddsMockCREService();
```

### Express Server Endpoints

```typescript
// mockCREServer.ts
import express from 'express';
import mockCRE from './mockCREService';

const app = express();

// Initialize match on server start
mockCRE.setupMatch();

/**
 * GET /api/cre/match/state
 * Returns current match state at a specific minute
 * ?minute=15 -> returns score and minute at 15 mins into match
 */
app.get('/api/cre/match/state', (req, res) => {
  const minute = parseInt(req.query.minute as string) || mockCRE.getCurrentMinute();
  
  try {
    const state = mockCRE.getMatchState(minute);
    res.json({
      success: true,
      data: state
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/cre/odds
 * Returns live odds at specific minute
 * ?minute=25 -> returns odds after 25 mins, with adjustments for any goals already scored
 */
app.get('/api/cre/odds', (req, res) => {
  const minute = parseInt(req.query.minute as string) || 0;
  
  try {
    const odds = mockCRE.getCurrentOdds(minute);
    const state = mockCRE.getMatchState(minute);
    
    res.json({
      success: true,
      data: {
        minute: state.minute,
        score: state.score,
        playerOdds: odds,
        sourcedFrom: 'The Odds API (real bookmaker data)',
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/cre/goals
 * Returns all goals that happened up to minute N
 * ?beforeMinute=60 -> all goals in first 60 minutes
 */
app.get('/api/cre/goals', (req, res) => {
  const beforeMinute = parseInt(req.query.beforeMinute as string) || 90;
  const goals = mockCRE.getGoalEvents(beforeMinute);
  
  res.json({
    success: true,
    data: {
      goals,
      totalCount: goals.length
    }
  });
});

/**
 * POST /api/cre/match/reset
 * Reset match to kickoff (minute 0)
 * Used for infinite replay capability
 */
app.post('/api/cre/match/reset', (req, res) => {
  mockCRE.resetMatch();
  res.json({
    success: true,
    message: 'Match reset to kickoff (minute 0)'
  });
});

/**
 * POST /api/cre/match/progress
 * Move match forward in time simulation
 * Body: { "toMinute": 45 } -> fast-forward to 45 mins
 */
app.post('/api/cre/match/progress', express.json(), (req, res) => {
  const { toMinute } = req.body;
  
  if (toMinute === undefined || toMinute < 0 || toMinute > 90) {
    return res.status(400).json({
      success: false,
      error: 'toMinute must be between 0 and 90'
    });
  }
  
  mockCRE.progressTime(toMinute);
  res.json({
    success: true,
    message: `Match progressed to minute ${toMinute}`,
    state: mockCRE.getMatchState(toMinute)
  });
});

export default app;
```

### Frontend Integration

```typescript
// React component showing live odds with real data
import { useState, useEffect } from 'react';

export function LiveOddsDisplay() {
  const [currentMinute, setCurrentMinute] = useState(0);
  const [odds, setOdds] = useState<Record<string, number>>({});
  const [score, setScore] = useState({ home: 0, away: 0 });
  
  useEffect(() => {
    // Fetch odds for current minute from mock CRE API
    fetch(`/api/cre/odds?minute=${currentMinute}`)
      .then(res => res.json())
      .then(data => {
        setOdds(data.data.playerOdds);
        setScore(data.data.score);
      });
  }, [currentMinute]);
  
  return (
    <div className="flex gap-4">
      {/* Time Slider */}
      <input
        type="range"
        min="0"
        max="90"
        value={currentMinute}
        onChange={(e) => setCurrentMinute(parseInt(e.target.value))}
        className="w-64"
      />
      <span className="text-lg font-bold">{currentMinute}\'</span>
      
      {/* Score Display */}
      <div className="text-2xl font-bold">
        {score.home} - {score.away}
      </div>
      
      {/* Player Odds (Real Data from The Odds API) */}
      <div className="grid grid-cols-2 gap-4">
        {Object.entries(odds).map(([player, oddValue]) => (
          <button
            key={player}
            className="p-3 bg-blue-500 text-white rounded hover:bg-blue-600"
            onClick={() => placeBet(player, oddValue)}
          >
            <div className="font-bold">{player}</div>
            <div className="text-sm opacity-80">{oddValue.toFixed(2)}x</div>
          </button>
        ))}
      </div>
      
      {/* Replay Controls */}
      <button
        onClick={() => setCurrentMinute(0)}
        className="px-4 py-2 bg-gray-500 text-white rounded"
      >
        Reset to Kickoff (Infinite Replay!)
      </button>
    </div>
  );
}
```

---

## CRE Integration for MVP

### Service Abstraction with Real Odds

Even though you're using mock data, the service layer abstracts it for future CRE upgrade.

```typescript
// services/cre/iCREService.ts
export interface ICREService {
  setupMatch(): Promise<void>;
  getOdds(atMinute: number): Promise<Record<string, number>>;
  getMatchState(atMinute: number): Promise<MatchState>;
  getGoalEvents(beforeMinute: number): Promise<GoalEvent[]>;
  getPlayers(forTeam?: string): Promise<Player[]>;
}

// services/cre/mockCREService.ts (MVP - Real Data)
export class MockLiveOddsCREService implements ICREService {
  constructor(private matchProfile: MatchProfile) {}
  
  async setupMatch(): Promise<void> {
    // Load real match profile from JSON
  }
  
  async getOdds(atMinute: number): Promise<Record<string, number>> {
    // Return odds from real timeseries with adjustments
  }
}

// services/cre/realCREService.ts (Phase 4 - Actual Chainlink CRE)
export class RealCREService implements ICREService {
  async setupMatch(): Promise<void> {
    // Call actual CRE endpoints
  }
  
  async getOdds(atMinute: number): Promise<Record<string, number>> {
    // Call CRE Capability DON for real-time odds
  }
}

// Factory
export function getCREService(environment: 'mock' | 'real'): ICREService {
  if (environment === 'mock') {
    return new MockLiveOddsCREService(matchProfile);
  } else {
    return new RealCREService();
  }
}
```

### Environment Variable

```bash
# .env.development
REACT_APP_CRE_MODE=mock
REACT_APP_MOCK_MATCH=man-city-vs-newcastle-2026-02-21

# .env.production (after CRE available)
REACT_APP_CRE_MODE=real
REACT_APP_CRE_ENDPOINT=https://cre.chainlink.example.com
```

---

## Implementation Guide

### Timeline

**Day 1-2: Real Match Capture**
1. Select upcoming match (EPL, any league with heavy betting)
2. Set up polling service pointing to The Odds API
3. Run service during live match (90 minutes)
4. Let data accumulate in Google Sheets/Excel

**Day 3: Post-Match Data Processing**
1. Export Google Sheet to JSON
2. Manually add goalscorers, lineups, substitutions
3. Save consolidated match profile

**Day 4-5: Mock API Development**
1. Build Express service with mock CRE
2. Implement time-based odds lookup
3. Test with frontend

**Day 6-7: Integration & Polish**
1. Connect frontend to mock API
2. Test infinite replay capability
3. Show judges real-market odds evolution

### Code Checklist

```
✓ Polling service (TypeScript)
  - getCAPICallOdds()
  - getScores()
  - appendToSheet()

✓ Google Sheets integration
  - authenticate()
  - appendSnapshot()

✓ Data export
  - exportToJSON()
  - enrichWithStats()

✓ Mock CRE service
  - getCurrentOdds()
  - getMatchState()
  - getGoalEvents()

✓ Express server
  - GET /api/cre/odds
  - GET /api/cre/match/state
  - POST /api/cre/match/reset

✓ Frontend integration
  - Fetch from mock API
  - Display odds
  - Show time slider
  - Infinite replay buttons
```

---

## Data Flow Diagrams

### Live Capture Phase

```
┌──────────────────────────────────────────────────────────────┐
│                  MATCH DAY (90 minutes)                      │
└──────────────────────────────────────────────────────────────┘

Every 30 seconds:

┌─────────────────────┐
│  The Odds API       │  <- Fetch latest odds for all players
│  /v4/sports/.../    │     from 5+ bookmakers (Betfair, etc)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Polling Service    │
│  (Node.js)          │ <- Aggregate odds snapshots
└──────────┬──────────┘
           │
           ▼
┌──────────────────────┐
│  Google Sheets       │
│  (Real-time sync)    │ <- View odds updates live in sheet
└──────────────────────┘
           
After 90 minutes:
→ Snapshot history complete with 180+ data points (1 every 30 secs)
```

### Post-Match Processing

```
┌──────────────────────────────────┐
│   Google Sheets (raw data)        │
│   - 180+ rows of odds snapshots   │
└──────────┬───────────────────────┘
           │
           ▼ Export to JSON
┌──────────────────────────────────┐
│   Odds Timeseries JSON            │ <- Odds at each point in time
├──────────────────────────────────┤
│   {                               │
│     "timestamp": "2026-02...",    │
│     "playerOdds": {               │
│       "Haaland": 2.10,            │
│       "Alvarez": 2.40             │
│     }                             │
│   }                               │
└─────────────┬────────────────────┘
              │
              ▼
┌──────────────────────────────────┐
│   Manual Enrichment               │
│   - Add goalscorers (minute, name)│
│   - Add lineups (all 22 players)  │
│   - Add substitutions             │
└─────────────┬────────────────────┘
              │
              ▼
┌──────────────────────────────────┐
│   Match Profile JSON (FINAL)      │ <- Ready for mock API
│   - Metadata                      │
│   - Complete odds evolution       │
│   - All match events              │
└──────────────────────────────────┘
```

### Runtime - Frontend Request Flow

```
User clicks "Progress to minute 45"
          │
          ▼
┌────────────────────────────────┐
│  Frontend (React)              │
│  fetch('/api/cre/odds?...') │ <- sends: ?minute=45
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Mock CRE Server (Express)     │
│  GET /api/cre/odds             │
└────────────┬───────────────────┘
             │
             ▼ (uses real match data)
┌────────────────────────────────┐
│  LiveOddsMockCREService        │
│  - Load odds timeseries at min 45
│  - Apply goal adjustments      │ <- "Haaland scored at min 12"
│  - Apply sub adjustments       │ <- "Player X off at min 68"
│  - Return: { Haaland: 1.20x }  │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Match Profile JSON (real data)│
│  - oddsTimeseries[45]          │
│  - goalscorers[goals < 45]     │
└──────────────────────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Response JSON to Frontend      │
│  {                             │
│    "playerOdds": {             │
│      "Haaland": 1.20,          │
│      "Alvarez": 2.20,          │
│      ... all players           │
│    },                          │
│    "score": { home: 1, away: 0}│
│  }                             │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Frontend updates UI            │
│  - Show "Min 45"               │
│  - Display updated odds         │
│  - Highlight fallen odds        │
│  (because player already scored)│
└──────────────────────────────────┘
```

---

## Summary: Why This Approach Wins

| Aspect | Old Approach | New Approach |
|--------|-------------|-------------|
| **Data Source** | Manual/ESPN | The Odds API (real bookmakers) |
| **Odds Realism** | Synthetic | 100% Real (Betfair, DraftKings, FanDuel) |
| **Verification** | Hard to verify | Can show judges: "These odds were live on Feb 21, 2026" |
| **Demo Capability** | Single run | Infinite replay at any speed (10x faster) |
| **Odds Evolution** | Static | Dynamic (shows how market reacts to goals) |
| **CRE Readiness** | Manual conversion | Service abstraction → Zero code changes for upgrade |
| **Data Collection** | 4-6 hours work | Automatic (polling service + Google Sheets) |
| **Scalability** | Single match | Capture multiple matches for library |

---

## Next Steps

1. **Select Match**: Choose an upcoming EPL/international match (this week ideally)
2. **Setup Polling**: Deploy Node.js polling service to AWS Lambda or local machine
3. **Monitor Capture**: Watch Google Sheet fill with real odds data during match
4. **Post-Match**: Consolidate into match profile JSON within 2 hours of final whistle
5. **Build API**: Create Express mock CRE server
6. **Integrate**: Connect frontend to real odds data
7. **Demo**: Show judges infinite replay with real market data

---

**Questions?**

1. Which EPL match this week would you like to capture?
2. Do you want to use Google Sheets or Excel?
3. Should we capture multiple matches or focus on one for MVP?

