# Vision High-Res Flow (Opus 4.7)

Typical scenario-by-scenario flows for leveraging Opus 4.7's high-resolution vision capability (max short side 2576px) in harness-review.

> **Resolution limit**: 2576px on the short side is the operational safety limit. Images exceeding this should be resized in advance.
> See [`docs/opus-4-7-vision-usage.md`](../../../docs/opus-4-7-vision-usage.md) for detailed guidance.

---

## Scenario 1: PDF page review

When using a spec, design document, release notes, etc. as the review target.

### Flow

1. **Identify the page range**

   Passing an entire PDF at once increases token consumption, so first understand the page structure.

   ```
   Read tool: file_path="<path>.pdf", pages="1-5"
   ```

2. **Check effective DPI per page**

   When PDF DPI is high, the short side may exceed 2576px after rendering.
   If it does, request re-export at lower DPI (see usage guide for details).

3. **Load target pages with Read**

   ```
   Read tool: file_path="<path>.pdf", pages="<target page range>"
   ```

   The Read tool passes the pages specified in the pages parameter to the vision model.
   Up to 20 pages can be specified at once.

4. **Pass to Reviewer agent**

   Feed the loaded page content into the harness-review review flow (Step 2: 5 perspectives).
   The Reviewer evaluates including visual layouts, diagrams, and code snippets.

5. **Batch processing (when page count is large)**

   Split PDFs exceeding 20 pages into 20-page batches.

   ```
   pages="1-20"  → review → record findings
   pages="21-40" → review → record findings
   ...
   Integrate verdicts at the end
   ```

### Verdict criteria

PDF review treats reviewer_profile as `static` and evaluates:

| Perspective | Check content |
|-------------|--------------|
| **Quality** | Is the diagram description sufficient? Is the sequence of steps clear? |
| **Accessibility** | Are there pages with images only and no alt text? |
| **AI Residuals** | Incomplete markers such as "TODO", "TBD", "Draft" |

---

## Scenario 2: Architecture diagram review

When using system diagrams, ER diagrams, sequence diagrams, etc. as the review target.

### Flow

1. **Check image resolution**

   ```bash
   # macOS: check resolution with sips
   sips -g pixelWidth -g pixelHeight diagram.png

   # With ImageMagick
   identify diagram.png
   ```

   When short side is 2576px or less, pass directly with Read tool.
   When exceeding, resize in advance (see usage guide for details).

2. **Load image with Read tool**

   ```
   Read tool: file_path="diagram.png"
   ```

   Opus 4.7 can recognize up to 2576px, so even fine labels and arrows can be analyzed.

3. **Prepare context to pass to Reviewer agent**

   ```
   Please review the following architecture diagram.
   Target: <diagram type (configuration/ER/sequence etc.)> of <system name>
   Review perspective: <review purpose (consistency check/change diff check/security check etc.)>
   ```

4. **Evaluation items**

   | Perspective | Check content |
   |-------------|--------------|
   | **Security** | Are auth flow, authorization boundary, and encryption requirements reflected in the diagram? |
   | **Quality** | Are inter-component dependencies clear? Is single responsibility maintained? |
   | **Performance** | Are bottleneck-prone areas (sync processing / N+1 / no caching etc.) visualized? |

5. **Cross-reference with implementation code**

   After architecture diagram review, cross-reference with the corresponding implementation code using the Code Review flow to verify consistency.

---

## Scenario 3: UI screenshot review

When scoring screenshots of Web/Mobile UI with the `--ui-rubric` option.

### Flow

1. **Prepare screenshots**

   Take screenshots of target pages/components.
   In Retina/HiDPI environments, this is often twice the logical pixel size.

   ```bash
   # macOS: screencapture command
   screencapture -x screenshot.png

   # Check resolution
   sips -g pixelWidth -g pixelHeight screenshot.png
   ```

2. **Check resolution and resize (if needed)**

   Resize when short side exceeds 2576px (see usage guide for details).
   When 2576px or less, pass directly with Read tool.

3. **Evaluate with harness-review --ui-rubric**

   ```
   /harness-review --ui-rubric
   ```

   Before execution, load the screenshot with Read tool and pass to Reviewer agent:

   ```
   Read tool: file_path="screenshot.png"
   ```

4. **4-axis scoring (see ui-rubric.md)**

   | Axis | Evaluation |
   |------|-----------|
   | **Design Quality** | Visual hierarchy / whitespace / color consistency |
   | **Originality** | Distinctiveness / brand expression |
   | **Craft** | Pixel precision / animation / micro-interactions |
   | **Functionality** | User flow completeness / error state consideration |

5. **Multi-resolution comparison (mobile / tablet / desktop)**

   Continuously Read screenshots for each resolution in the same session and have the Reviewer agent evaluate responsive design together.

   ```
   Read tool: file_path="mobile.png"    # ~375×812
   Read tool: file_path="tablet.png"    # ~768×1024
   Read tool: file_path="desktop.png"   # ~1440×900
   ```

---

## Connecting to Reviewer Agent

For any of the above 3 scenarios, after loading images/PDF with Read tool, connect to Reviewer agent with this common pattern.

### Connection in breezing mode

When Lead receives a task with vision input from Worker:

1. Worker returns with image/PDF paths included in `files_changed`
2. Lead loads that path with Read tool and runs the review with vision context attached
3. Reviewer agent returns verdict in `review-result.v1` schema

```json
// Example additional context passed to Reviewer
{
  "vision_inputs": [
    { "type": "image", "path": "diagram.png", "role": "architecture_diagram" },
    { "type": "pdf",  "path": "spec.pdf",    "role": "specification", "pages": "1-10" }
  ],
  "review_context": "Review of changes including images/PDF"
}
```

### Reviewer behavior when receiving image input

- Reviewer treats image input the same as "normal diff text" and returns `review-result.v1`
- In `observations[].location`, write as `"diagram.png: overall"` / `"spec.pdf: p3"` etc.
- When critical/major cannot be determined from image alone, limit to `minor` or `recommendation`
- The verdict criteria (critical / major / minor / recommendation) do not change based on presence/absence of vision input

---

## Batch processing guidelines

When continuously reviewing multiple images/PDF pages:

| Situation | Recommended approach |
|-----------|---------------------|
| PDF 20 pages or fewer | Specify all pages in one Read |
| PDF 21+ pages | Split into 20-page batches → consolidate findings |
| 1-5 images | Continuous Read → review together |
| 6+ images | Batch by 5 → consolidate verdict at end |
| High-resolution images mixed | Process after pre-resize (see usage guide) |

In batch processing, accumulate `observations` from each batch and determine the final verdict based on presence/absence of `critical` / `major` after all batches complete.
