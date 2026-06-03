# CSMS - Documentation

Welcome to the internal documentation for the Church Servants Management System.

## Contents
1. [Architecture Overview](architecture.md)
   - Technology Stack
   - Clean Architecture Layers
   - Offline-First Sync Strategy
   - RBAC via Custom Claims
2. [Operations Flow](operations_flow.md)
   - Authentication Sequence
   - Sync Engine Sequence
   - Attendance Logic Flow
   - Admin Security Workflow

## Quick Summary
The app is built to be **Offline-First**, ensuring servants can mark attendance without a stable internet connection. Data is synced in the background using a Hive-to-Firestore "Write-Behind" mechanism. Security is enforced through Firebase Custom Claims and a 15-minute "Freshness" policy for sensitive writes.
