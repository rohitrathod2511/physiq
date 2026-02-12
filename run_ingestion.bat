@echo off
echo Starting Ingestion Wrapper... > ingestion_status.txt
cd functions\scripts
if %errorlevel% neq 0 (
    echo Failed to cd to functions\scripts >> ..\..\ingestion_status.txt
    exit /b %errorlevel%
)

echo Running ingest_indian.js... >> ..\..\ingestion_status.txt
node ingest_indian.js > ..\..\indian_log.txt 2>&1
if %errorlevel% neq 0 (
    echo ingest_indian.js FAILED >> ..\..\ingestion_status.txt
) else (
    echo ingest_indian.js SUCCESS >> ..\..\ingestion_status.txt
)

echo Running ingest_usda.js... >> ..\..\ingestion_status.txt
node ingest_usda.js > ..\..\usda_log.txt 2>&1
if %errorlevel% neq 0 (
    echo ingest_usda.js FAILED >> ..\..\ingestion_status.txt
) else (
    echo ingest_usda.js SUCCESS >> ..\..\ingestion_status.txt
)

echo DONE >> ..\..\ingestion_status.txt
