# Contest Scoring System

A decentralized coding contest platform built with **Solidity**, **MetaMask**, and **Ganache** for secure, transparent, and tamper-proof evaluation.

This project allows an organizer to register participants and judges, assign judges to participants, collect weighted scores, finalize the contest only after all required evaluations are completed, and view an on-chain leaderboard. The repository currently contains a frontend in `index.html` and the Solidity smart contract in `judging_system.sol`. 

---

## Features

- Organizer-controlled contest setup
- Participant registration
- Judge registration
- Judge-to-participant assignment
- Weighted score submission based on:
  - Problem Solving: **40%**
  - Code Quality: **30%**
  - Efficiency: **30%**
- Progress tracking for judges
- Contest finalization only after all assigned scores are submitted
- On-chain leaderboard sorted by average weighted score
- MetaMask wallet integration through the frontend
- Local blockchain testing using Ganache

---

## Tech Stack

- **Solidity** for the smart contract
- **HTML / JavaScript** for the frontend
- **MetaMask** for wallet interaction
- **Ganache** for local Ethereum blockchain testing
- **Remix IDE** for compiling and deploying the contract

---

## Project Structure

```bash
Contest-Scoring-System/
├── index.html           # Frontend dashboard
└── judging_system.sol   # Solidity smart contract
