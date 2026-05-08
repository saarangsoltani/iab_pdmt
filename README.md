# CoHost Download Measurement Pipeline

IAB 2.2-compliant podcast download measurement pipeline built in plain Ruby.

## Overview

I built this as a standalone CLI tool that processes raw CDN logs and outputs podcast download counts that comply with the IAB Podcast Measurement Technical Guidelines v2.2. I focused on keeping the code clean and modular — each part of the pipeline (parsing, filtering, deduplication, compliance, output) is in its own directory with a single responsibility. The filtering logic uses a Chain of Responsibility pattern so filters are easy to add, remove, or reorder. I added sufficient tests covering the core filtering, deduplication, parser, compliance engine, and output formatters. The only dependency is Ruby's standard library — no gems required.

Below are the assumptions I made while implementing the spec, followed by a summary of implemented features.

### Assumptions

1. **Bitrate**: 128 kbps assumed for byte threshold calculation. 1 minute = 128,000 bits/sec × 60 sec ÷ 8 = 960,000 bytes. Configurable via CLI.
2. **Episode URL**: Query parameters are stripped for episode identification.
3. **Deduplication Key**: IP Address + User Agent + Episode URL. IPv6 uses first 64 bits (prefix); IPv4-mapped IPv6 addresses are treated as IPv4. It refers to addresses like ::ffff:192.168.1.1 — an IPv4 address wrapped inside an IPv6 format. This happens when a client connects over IPv4 to a server listening on IPv6 (dual-stack). Without this handling, the code would see ::ffff:192.168.1.1 as IPv6 and extract its /64 prefix, which would be 0000:0000:0000:0000. That would mean every IPv4 user connecting through the same server gets the same dedup key — treating them all as one listener. By mapping it back to 192.168.1.1, each real IPv4 address gets proper dedup isolation.
4. **206 Request Reassembly**: Within a 24-hour window, bytes from multiple 206 requests from the same listener are summed to check the 1-minute threshold.
5. **Bot Detection**: Pattern matching on user-agent strings for common patterns (bot, spider, crawler, curl, python, wget). This is not a comprehensive list and may not match official IAB bot list.
6. **HTTP Method**: The CDN log format does not include an HTTP method field. All entries are assumed to be GET requests.
7. **Pre-load/Prefetch**: Handled by the 1-minute byte threshold — any request that transfers fewer bytes than 1 minute of audio is filtered as a pre-load or partial playback.

### Implemented Features

- Filter out non-audio requests (only .mp3, .m4a, .aac)
- Filter known bots and spiders via user-agent patterns
- Filter non-200/206 HTTP status codes
- 206 byte threshold (1-minute rule) with configurable bitrate
- 24-hour rolling window deduplication (IP + User Agent + Episode URL)
- Multiple 206 request reassembly within window
- Apple WatchOS user-agent filtering
- IPv6 /64 prefix extraction for dedup
- IPv4-mapped IPv6 address handling
- Multiple output formats (JSON, CSV, Table, human-readable)
- Sample fixture log file (1000 entries)
- Interactive and non-interactive CLI modes

### Not Implemented due to time constraints

- Performance optimizations for large log files (streaming parser)
- Country breakdown
- App/user-agent breakdown
- Time-series breakdown (downloads over time)

## Usage

You can run the pipeline in two modes:

### Interactive mode
```bash
ruby pipeline.rb
```

Prompts will ask:
1. Log file path (default: `fixtures/sample_logs.txt`)
2. Output format (human-readable, table, CSV, JSON)
3. Bitrate for 1-minute rule (default: 128 kbps)

### Command-line arguments (non-interactive mode)
```bash
ruby pipeline.rb fixtures/sample_logs.txt
ruby pipeline.rb path/to/logs.txt json 128
ruby pipeline.rb path/to/logs.csv csv 64
```

Arguments: `ruby pipeline.rb <log_file> [format] [bitrate]`
- `log_file`: path to a pipe-delimited CDN log file
- `format`: `human-readable` (or `human`), `table`, `csv`, `json` (default: human-readable)
- `bitrate`: bitrate in kbps for the 1-minute rule (default: 128)

There are sample logs in `fixtures/sample_logs.txt` (1000 entries with realistic duplicates) that you can use to test the pipeline.

## IAB 2.2 Rules Implemented

1. **HTTP Status Filter**: Only 200 and 206 responses count
2. **Bot Filter**: Excludes known bot patterns (Googlebot, curl, Python requests, etc.)
3. **Apple Watch Filter**: Excludes WatchOS user agents (duplicates iPhone downloads)
4. **Audio Request Filter**: Only counts .mp3, .m4a, .aac requests
5. **Byte Threshold (1-Minute Rule)**:
   - 200 responses: Auto-pass (full file served)
   - 206 responses: Must send ≥960KB (at 128kbps) to count
6. **Deduplication**: 24-hour rolling window per IP+UserAgent+Episode
   - IPv6 addresses use first 64 bits (prefix) for dedup
   - Multiple 206 requests from same listener are reassembled
7. **Pre-load / Prefetch Handling**:
   - The 1-minute byte threshold doubles as the pre-load/prefetch filter
   - Per the IAB guidelines, a request is considered pre-loading if fewer than 1 minute of audio was transferred
   - Any 206 response with bytes below the threshold is categorized as `below_byte_threshold` in the filter breakdown, which at 128kbps means <960KB transferred
   - This catches: users who start playback but stop within 1 minute, podcast apps that pre-fetch a buffer, and premature terminations

## Project Structure

```
cohost-download-measurement/
├── pipeline.rb                # CLI entry point (interactive)
├── lib/
│   ├── parser.rb             # Log file parser
│   ├── models/
│   │   └── log_entry.rb     # Log entry data structure
│   ├── filters/
│   │   ├── base.rb
│   │   ├── http_status_filter.rb
│   │   ├── bot_filter.rb
│   │   ├── apple_watch_filter.rb
│   │   ├── audio_request_filter.rb
│   │   ├── byte_threshold_filter.rb
│   │   └── filter_chain.rb
│   ├── deduplication.rb       # 24-hour window dedup
│   ├── compliance/
│   │   └── iab_2_2.rb      # IAB 2.2 rules engine
│   └── output/               # Output formatters
│       ├── formatter.rb
│       ├── human_readable_formatter.rb
│       ├── json_formatter.rb
│       ├── csv_formatter.rb
│       └── table_formatter.rb
├── generate_logs.rb          # Log generator script
├── runtests                  # Test runner script
├── test/                     # Test suite
│   ├── test_helper.rb
│   ├── test_parser.rb
│   ├── test_filters.rb
│   ├── test_deduplication.rb
│   ├── test_compliance.rb
│   └── test_output.rb
├── fixtures/
│   └── sample_logs.txt     # Sample CDN logs (1000 entries)
├── plan.md                  # Implementation plan (todo list)
└── README.md               # This file
```

## Design Pattern: Chain of Responsibility

The filtering logic uses the **Chain of Responsibility** pattern, where:
- `BaseFilter` defines a common interface with an `apply(entries)` method
- Each specific filter inherits from `BaseFilter` and implements the `apply` method
- `FilterChain` orchestrates the sequential execution

**Benefits:**
- **Extensibility**: New filters can be added by creating a new class inheriting from `BaseFilter`
- **Single Responsibility**: Each filter handles one specific rule
- **Order Control**: Filter order matters (e.g., bot filtering before byte threshold checking)

## Running Tests

```bash
# Run all tests (verbose)
./runtests

# Run all tests (individual files)
ruby -Ilib -Itest -e 'Dir["test/test_*.rb"].each { |f| require f }'

# Run a specific test
ruby -Ilib -Itest test/test_filters.rb
```

## Sample Output

```
============================================================
IAB 2.2 COMPLIANT DOWNLOAD MEASUREMENT RESULTS
============================================================

SUMMARY:
  Total Raw Requests: 1000
  Total Filtered Out: 510
  Compliant Downloads: 306

FILTER BREAKDOWN:
  non_200_206_status: 57
  bot: 235
  apple_watch: 80
  non_audio_request: 0
  below_byte_threshold: 138

PER EPISODE:
  https://audio-delivery.cohostpodcasting.com/...: 18 downloads
  ...

OPTIONS USED:
  Bitrate: 128 kbps
  Byte Threshold: 960000 bytes
============================================================
```
