# Security Reviewer Profile

Security-dedicated review profile activated by `harness-review --security`.
Comprehensively checks authentication, authorization, secrets, and dependency vulnerabilities based on OWASP Top 10.

> **Read-only constraint**: The reviewer operating under this profile
> uses only Read / Grep / Glob / Bash (read-only commands only).
> Write / Edit / write-capable Bash are never executed.

---

## Security Review Flow

### Step 1: Identify scope

```bash
# Collect changed files (BASE_REF inherited from caller)
CHANGED_FILES="$(git diff --name-only --diff-filter=ACMR "${BASE_REF:-HEAD~1}")"
git diff "${BASE_REF:-HEAD~1}" -- ${CHANGED_FILES}
```

### Step 2: OWASP Top 10 checks

Check each item below against **the changed diff** and **related files**.

#### A01: Broken Access Control

| Check item | Verification |
|------------|-------------|
| Missing authorization check | Is auth middleware applied to route/endpoint definitions? |
| Horizontal privilege escalation | Is filtering by `userId` etc. applied when fetching user-owned resources? |
| Vertical privilege escalation | Are role checks (admin/user/guest etc.) properly implemented? |
| IDOR | Are IDs in URL parameters or request bodies accepted without authorization? |
| Directory traversal | Are path operations containing `../` sanitized? |

**Detection patterns (verify with Grep)**:
```bash
# Routes without authentication candidates
grep -rn "app\.\(get\|post\|put\|delete\|patch\)" --include="*.ts" --include="*.js"
# DB lookups without userId
grep -rn "findById\|findOne\|select.*where" --include="*.ts"
```

#### A02: Cryptographic Failures

| Check item | Verification |
|------------|-------------|
| Sensitive data stored in plaintext | Are passwords, tokens, PII stored in plaintext in DB/logs? |
| Weak hash algorithm | Is MD5/SHA1 used for password hashing? |
| Insecure random number | Is `Math.random()` used for auth token generation? |
| TLS strength | Is sensitive data sent/received over HTTP (non-HTTPS)? |
| Hardcoded keys | Are crypto keys/IVs embedded as constants? |

**Detection patterns**:
```bash
grep -rn "md5\|sha1\|Math\.random\(\)" --include="*.ts" --include="*.js"
grep -rn "createHash.*md5\|createHash.*sha1" --include="*.ts"
grep -rn "http://" --include="*.ts" --include="*.js" --include="*.env*"
```

#### A03: Injection

| Check item | Verification |
|------------|-------------|
| SQL injection | Is user input concatenated into SQL strings? |
| NoSQL injection | Is `$where` or input values used as operators in MongoDB etc.? |
| Command injection | Is user input passed to `exec()` / `spawn()`? |
| LDAP injection | Is unsanitized input used in LDAP queries? |
| Template injection | Is user input passed directly to template engines? |

**Detection patterns**:
```bash
grep -rn "exec\|execSync\|spawn" --include="*.ts" --include="*.js"
grep -rn "\`SELECT\|\"SELECT\|'SELECT" --include="*.ts" --include="*.js"
grep -rn "\$where\|\$\[" --include="*.ts" --include="*.js"
```

#### A04: Insecure Design

| Check item | Verification |
|------------|-------------|
| Missing rate limiting | Is rate limiting implemented on auth endpoints? |
| TOCTOU race condition | Can state changes after check be exploited before use? |
| Business logic flaws | Can state transitions be executed in invalid order? |

#### A05: Security Misconfiguration

| Check item | Verification |
|------------|-------------|
| Default credentials | Are default passwords/usernames still in use? |
| Verbose error messages | Are stack traces or internal info returned to clients in production? |
| Unnecessary features enabled | Are debug endpoints/admin panels active in production? |
| HTTP security headers | Are HSTS, CSP, X-Frame-Options etc. configured? |
| CORS configuration | Is `Access-Control-Allow-Origin: *` set in production? |

**Detection patterns**:
```bash
grep -rn "cors.*origin.*\*\|allowedOrigins.*\*" --include="*.ts" --include="*.js"
grep -rn "debug.*true\|NODE_ENV.*development" --include="*.ts"
grep -rn "console\.log.*password\|console\.log.*token\|console\.log.*secret" --include="*.ts"
```

#### A06: Vulnerable and Outdated Components

| Check item | Verification |
|------------|-------------|
| Packages with known vulnerabilities | Are there versions with CVEs in `package.json` dependencies? |
| `npm audit` results | Are high/critical vulnerabilities left unresolved? |
| Lock file consistency | Is `package-lock.json` / `yarn.lock` up to date? |

**Verification commands**:
```bash
# Check package.json dependencies (read-only)
cat package.json | grep -E '"dependencies"|"devDependencies"' -A 50 | head -60
# Verify lock file exists
ls -la package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null
```

#### A07: Identification and Authentication Failures

| Check item | Verification |
|------------|-------------|
| Brute force protection | Is login attempt limiting/account lockout implemented? |
| Weak password policy | Are minimum length/complexity requirements set? |
| Session fixation attack | Is session ID regenerated after login? |
| Session expiration | Do long-lived sessions/tokens expire appropriately? |
| JWT validation | Is signing with `alg: none` or weak keys accepted? |

**Detection patterns**:
```bash
grep -rn "jwt\.verify\|jwt\.sign" --include="*.ts" --include="*.js"
grep -rn "expiresIn.*\|expire.*" --include="*.ts"
grep -rn "algorithm.*none\|alg.*none" --include="*.ts" --include="*.js"
```

#### A08: Software and Data Integrity Failures

| Check item | Verification |
|------------|-------------|
| Code execution from untrusted sources | Is JavaScript loaded dynamically from external CDN/URL? |
| Deserialization | Is untrusted data passed directly to `eval()` / `Function()`? |
| CI/CD pipeline protection | Do build scripts execute external input without validation? |

**Detection patterns**:
```bash
grep -rn "eval(\|new Function(" --include="*.ts" --include="*.js"
grep -rn "require(.*\$\|import(.*\$" --include="*.ts" --include="*.js"
```

#### A09: Security Logging and Monitoring Failures

| Check item | Verification |
|------------|-------------|
| Auth failure logging | Are login failures/permission errors recorded? |
| Sensitive data in logs | Do logs contain passwords/tokens/PII? |
| Log injection | Is user input written directly to logs (CRLF injection)? |

#### A10: Server-Side Request Forgery (SSRF)

| Check item | Verification |
|------------|-------------|
| Requests to user-specified URLs | Can user-supplied URLs access internal networks? |
| URL validation | Is an allowlist of permitted domains or IP filtering implemented? |
| Redirect following | Do request libraries follow redirects to internal addresses? |

**Detection patterns**:
```bash
grep -rn "fetch(\|axios\.\|got(\|request(" --include="*.ts" --include="*.js"
```

---

## Authentication / Authorization Review Points

### Authentication flow

```
1. Input validation → Are type/length/format checks present?
2. Authentication processing → Is timing attack protection (constantTimeCompare etc.) present?
3. Token issuance → Is sufficient entropy (crypto.randomBytes etc.) used?
4. Token storage → Is it httpOnly + Secure + SameSite Cookie, or LocalStorage?
5. Token validation → Are signature/expiration/revocation checks complete?
6. Logout → Is server-side token invalidation implemented?
```

### Authorization flow

```
1. Is the required role explicitly stated per endpoint?
2. Is it checked in both middleware and route handler (defense in depth)?
3. Does it not rely solely on frontend hiding (backend required)?
4. Is resource ownership verification present?
```

---

## Handling Secrets

### Hardcode detection

```bash
# API key/secret-like patterns
grep -rn "api[_-]key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]" \
  --include="*.ts" --include="*.js" --include="*.sh"

# AWS / GCP / Azure credentials
grep -rn "AKIA\|sk-[a-zA-Z0-9]\{20\}\|AIza" --include="*.ts" --include="*.js"

# Hardcoded JWT signing keys
grep -rn "jwt.*secret.*=\s*['\"][^'\"]\{8,\}" --include="*.ts" --include="*.js"

# .env file committed
git diff "${BASE_REF:-HEAD~1}" -- .env .env.local .env.production
```

### Proper use of environment variables

| Good pattern | Bad pattern |
|-------------|------------|
| `process.env.DATABASE_URL` | `"postgresql://user:pass@localhost/db"` |
| `process.env.JWT_SECRET` | `const JWT_SECRET = "my-super-secret"` |
| `process.env.API_KEY` | `const API_KEY = "sk-abc123..."` |

### .env file management

- Is `.env.example` populated with dummy values?
- Are `.env` / `.env.local` in `.gitignore`?
- Are production secrets not committed in `.env.production`?

```bash
# Check .gitignore
grep -n "\.env" .gitignore 2>/dev/null
# Verify no .env files in repository
git diff "${BASE_REF:-HEAD~1}" --name-only | grep "\.env"
```

---

## Dependency Known Vulnerability Check

### package.json verification procedure

1. Read the changed `package.json`
2. Identify newly added / version-bumped packages
3. Recommend cross-referencing with known CVE databases (NVD, Snyk, GitHub Advisory)

```bash
# Check changed packages
git diff "${BASE_REF:-HEAD~1}" -- package.json package-lock.json

# Check current dependency versions
cat package.json | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k,v) for d2 in [d.get('dependencies',{}),d.get('devDependencies',{})] for k,v in d2.items()]" 2>/dev/null
```

### High-risk package categories

| Category | Notes |
|---------|-------|
| Auth libraries | passport, jsonwebtoken, bcrypt — many version-specific vulnerabilities |
| HTTP clients | axios, node-fetch, got — verify SSRF protection defaults |
| Template engines | handlebars, ejs, pug — past RCE vulnerability cases |
| XML parsers | xml2js, fast-xml-parser — watch for XXE attacks |
| Serialization | serialize-javascript, node-serialize — RCE risk |
| Image processing | sharp, imagemagick — buffer overflow type vulnerabilities |

---

## Security Review Output Format

Uses the same JSON schema as normal Code Review but sets `reviewer_profile: "security"`.

```json
{
  "schema_version": "review-result.v1",
  "verdict": "APPROVE | REQUEST_CHANGES",
  "reviewer_profile": "security",
  "critical_issues": [
    {
      "severity": "critical",
      "category": "Security",
      "owasp": "A03:2021 - Injection",
      "location": "src/api/users.ts:42",
      "issue": "User input is concatenated directly into SQL string",
      "suggestion": "Use prepared statements or ORM",
      "cwe": "CWE-89"
    }
  ],
  "major_issues": [],
  "observations": [],
  "recommendations": []
}
```

### Security-specific fields

| Field | Description |
|-------|-------------|
| `owasp` | Applicable OWASP Top 10 category (e.g., `A01:2021 - Broken Access Control`) |
| `cwe` | Applicable CWE number (e.g., `CWE-89`) |
| `cvss_estimate` | Estimated CVSS score (Critical: 9.0+, High: 7.0-8.9, Medium: 4.0-6.9) |

### Verdict criteria (Security mode)

Security mode applies stricter criteria than normal:

| Severity | Definition | Verdict |
|----------|-----------|---------|
| **critical** | RCE, auth bypass, direct secret exposure, SQLi/CMDi | REQUEST_CHANGES on 1+ |
| **major** | Insufficient authorization check, hardcoded secrets, weak cryptography | REQUEST_CHANGES on 1+ |
| **minor** | Missing security headers, excessive error info, minor misconfiguration | APPROVE (include fix recommendation) |
| **recommendation** | Security best practice suggestion | APPROVE |
