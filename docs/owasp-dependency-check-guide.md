# OWASP Dependency-Check Guide

## What Is It?

[OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/) is a Software Composition Analysis (SCA) tool that scans your project's dependencies for **known security vulnerabilities (CVEs)**.

It works by:

1. Identifying all dependencies in your project (including transitive ones pulled in by your direct dependencies)
2. Matching each dependency against the **NVD (National Vulnerability Database)** — a public database maintained by NIST containing all publicly disclosed CVEs
3. Generating a report listing any vulnerable dependencies with their CVE IDs, CVSS scores, and descriptions
4. Optionally failing the build if any vulnerability exceeds a severity threshold

**Real-world example:** If your project depended on `log4j-core:2.14.1`, Dependency-Check would flag [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228) (Log4Shell, CVSS 10.0) and fail the build.

## Project Configuration

This project uses the `dependency-check-maven` plugin (version 12.1.1), configured in `pom.xml`:

```xml
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>${dependency-check-maven-plugin.version}</version>
    <configuration>
        <failBuildOnCVSS>7</failBuildOnCVSS>              <!-- Fail on High/Critical (7.0+) -->
        <ossindexAnalyzerEnabled>false</ossindexAnalyzerEnabled>  <!-- NVD only, no OSS Index -->
        <nvdValidForHours>4</nvdValidForHours>             <!-- Cache NVD data for 4 hours -->
    </configuration>
</plugin>
```

| Setting | Value | Meaning |
|---------|-------|---------|
| `failBuildOnCVSS` | 7 | Build fails if any CVE has CVSS score >= 7.0 (High or Critical) |
| `ossindexAnalyzerEnabled` | false | Disables Sonatype OSS Index (requires separate auth); NVD is sufficient |
| `nvdValidForHours` | 4 | Caches the NVD database locally for 4 hours to avoid redundant downloads |

## Setting Up the NVD API Key

The NVD API key is **required** for reliable operation. Without it, NVD rate-limits requests heavily and the scan will likely fail or take 10+ minutes.

### Step 1: Get a Free NVD API Key

1. Go to <https://nvd.nist.gov/developers/request-an-api-key>
2. Fill in your email and organization
3. You will receive an API key via email

### Step 2: Configure the Key Locally

Add the key to your Maven settings file (`~/.m2/settings.xml`). This lets Maven pick it up automatically without passing `-D` flags:

```xml
<settings>
  <profiles>
    <profile>
      <id>nvd</id>
      <properties>
        <nvdApiKey>your-api-key-here</nvdApiKey>
      </properties>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>nvd</activeProfile>
  </activeProfiles>
</settings>
```

> **Note:** If `~/.m2/settings.xml` already exists with other content, merge the `<profile>` and `<activeProfile>` entries into the existing file rather than replacing it.

### Step 3: Run Dependency-Check Locally

```bash
# With settings.xml configured (recommended) — no extra flags needed
./mvnw dependency-check:check

# Or pass the key explicitly via environment variable
export NVD_API_KEY="your-api-key-here"
./mvnw dependency-check:check -DnvdApiKey=$NVD_API_KEY
```

The first run downloads the full NVD database (~250MB) and takes a few minutes. Subsequent runs within the 4-hour cache window will be much faster.

### Step 4: Configure the Key for GitHub CI

#### Option A: GitHub CLI (recommended)

```bash
gh secret set NVD_API_KEY --repo tedwon/agentic-dev-playbook-with-harness
```

This prompts you to paste the key interactively.

#### Option B: GitHub Web UI

1. Go to your repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `NVD_API_KEY`
4. Value: your NVD API key
5. Click **Add secret**

The CI workflow (`.github/workflows/ci.yml`) automatically picks up this secret.

## Running the Check

```bash
# Run with NVD API key (recommended)
./mvnw dependency-check:check -DnvdApiKey=$NVD_API_KEY

# Run without key (slow, may fail due to rate limits)
./mvnw dependency-check:check
```

## Reading the Report

After a successful run, reports are generated at:

| File | Format |
|------|--------|
| `target/dependency-check-report.html` | Human-readable HTML report |
| `target/dependency-check-report.json` | Machine-readable JSON (if configured) |

Open the HTML report in a browser to see:

- **Summary** — total dependencies scanned, vulnerable count
- **Vulnerability details** — CVE ID, CVSS score, description, affected dependency, and upgrade recommendations

## CVSS Score Reference

| Score | Severity | Build Result |
|-------|----------|-------------|
| 0.0 | None | Pass |
| 0.1 - 3.9 | Low | Pass |
| 4.0 - 6.9 | Medium | Pass |
| 7.0 - 8.9 | **High** | **Fail** |
| 9.0 - 10.0 | **Critical** | **Fail** |

## Troubleshooting

### 401 Unauthorized / 429 Too Many Requests from OSS Index

The Sonatype OSS Index API requires authentication. This project disables it (`ossindexAnalyzerEnabled=false`) and relies solely on NVD.

### Slow or Failing Without API Key

The NVD enforces strict rate limits for unauthenticated requests. Set up the `NVD_API_KEY` as described above.

### False Positives

If a CVE does not actually affect your usage of a dependency, you can suppress it by creating a suppression file:

```bash
# Create suppression file
touch dependency-check-suppressions.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <suppress>
        <notes><![CDATA[Explain why this CVE does not apply]]></notes>
        <cve>CVE-2024-XXXXX</cve>
    </suppress>
</suppressions>
```

Then reference it in `pom.xml`:

```xml
<configuration>
    <suppressionFiles>
        <suppressionFile>dependency-check-suppressions.xml</suppressionFile>
    </suppressionFiles>
</configuration>
```

## References

- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)
- [NVD API Key Registration](https://nvd.nist.gov/developers/request-an-api-key)
- [dependency-check-maven Plugin Docs](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/)
- [CVSS Scoring System](https://www.first.org/cvss/)
