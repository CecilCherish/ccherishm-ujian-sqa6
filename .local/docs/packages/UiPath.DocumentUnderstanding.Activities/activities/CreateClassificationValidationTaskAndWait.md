# Create Classification Validation Task and Wait

`UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation.CreateClassificationValidationActionAndWait`

**XAML element:** `<duVal:CreateClassificationValidationActionAndWait …>` *(not generic — no `x:TypeArguments`)*
**xmlns prefix:** `duVal` → `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`
**Pairs with:** Single-step replacement for `CreateClassificationValidationAction` + `WaitForClassificationValidationAction`. Input from `ClassifyDocument.ClassificationResults`. Output `ValidatedClassificationResults` (validated `DocumentData`) feeds `ExtractDocumentDataWithDocumentData.FileInput`.

Creates a Classification Validation Task in Action Center to verify the classification results and suspends the workflow until the task is completed. After a human reviewer submits the validated classification, the workflow resumes with the corrected results.

**Package:** `UiPath.DocumentUnderstanding.Activities`
**Category:** Document Understanding

## Properties

### Input

| Name | Display Name | Kind | Type | Required | Default | Description |
|------|-------------|------|------|----------|---------|-------------|
| `AutomaticClassificationResults` | Document Data | InArgument | `DocumentData` | Yes | | The classification result, output of the Classify Document activity. |
| `ActionTitle` | Action title | InArgument | `string` | Yes | | Title of the action as it appears in Action Center. |
| `ActionPriority` | Action priority | InArgument | `string` | | | Priority of the action. |
| `ActionCatalogue` | Action catalog | InArgument | `string` | | | Catalog where the action will be available in Action Center. The task is created in `OrchestratorFolderName`, so the catalog must exist in that folder. In a Solution, use the name of a task catalog resource of the solution, deployed in the same folder as the storage bucket resource. |
| `OrchestratorFolderName` | Orchestrator folder | InArgument | `string` | | | Orchestrator folder where the action will be available. |
| `OrchestratorBucketName` | Orchestrator bucket | InArgument | `string` | | `"du_storage_bucket"` | Orchestrator storage bucket for documents and data required for validation. The bucket must exist in the target tenant. Do not set this property unless the user specifies a bucket name — omitting it uses the default (`SWConstants.DefaultBucketName`). |

### Configuration

| Name | Display Name | Type | Default | Description |
|------|-------------|------|---------|-------------|
| `EnablePageReordering` | Enable Page Reordering | `bool` | `false` | Whether page reordering should be enabled in Classification Station. |
| `RemoveDataFromStorage` | Remove Data From Storage | `bool` | `false` | If checked, deletes the files staged for the classification validation task once that task reaches a terminal state. |

### Output

| Name | Display Name | Kind | Type | Description |
|------|-------------|------|------|-------------|
| `ValidatedClassificationResults` | Document data | OutArgument | `DocumentData` | Validated classification data containing changes made by the reviewer in Classification Station. |

**JSON serialization.** This output serializes as a plain JSON object, so it can be bound to a **job out-argument** (e.g. returned from an RPA workflow element to a Maestro process variable) and read back into a `DocumentData` / `IDocumentData<DictionaryData>` in-argument in another workflow. See [JSON serialization](../overview.md#documentdata-classification) in the overview for the details and limits.

## XAML Example

```xml
<duVal:CreateClassificationValidationActionAndWait
    DisplayName="Create Classification Validation Task and Wait"
    AutomaticClassificationResults="[classificationResults]"
    ActionTitle="[&quot;Validate classification&quot;]"

    ValidatedClassificationResults="[validatedClassification]" />
```

> Namespace prefix `duVal` maps to `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`.

## Notes

- This is a **persistent activity**. The workflow suspends after creating the validation task and resumes only when the task is completed in Action Center. The project must have `"supportsPersistence": true` in `project.json` (under `"runtimeOptions"`). Without this, the workflow will fail at runtime.
- Cannot be placed inside a No Persist Scope.
- For a non-blocking alternative, use **Create Classification Validation Task** followed by **Wait for Classification Validation Task & Resume**.
- In a typical pipeline, this activity follows **Classify Document**. The `ValidatedClassificationResults` output (`DocumentData`) is passed as `FileInput` to **Extract Document Data**.

### Remove Data From Storage

Deletes every file the classification validation task staged in the storage bucket, including the original document. Files are removed from the bucket the task was created against, in the folder that hosts it.

The robot's Orchestrator role needs these folder permissions:

| Permission | Required |
|---|---|
| Storage Files | View, Delete |
| Storage Buckets | View |
| Actions | View |

Without **Delete** on Storage Files, no file is removed. Individual delete failures are logged and skipped rather than failing the workflow, so a completed workflow does not on its own mean the bucket is empty.

The `AreFilesRemoved` telemetry field reflects whether at least one staged file was actually deleted, on both the same-organization and the cross-organization path. Individual per-file failures are logged; read the robot logs to see which file failed.

Because this activity creates and waits in one step, removal runs after the reviewer completes the task and the document has been rehydrated.

Every terminal task state removes, not just the successful one: a task deleted in Orchestrator and a document the reviewer rejects both have their files removed before the activity reports the error, on the same-organization and the cross-organization path alike. After the throw there is no further chance to clean up.

A cancelled job is different, and so is a fault raised before the removal step. Both leave the files where they are, which is what you want when you have to debug the failure that caused them.

Once the data is removed, the completed action is no longer available in Action Center.

## Supporting References

Both `AutomaticClassificationResults` and `ValidatedClassificationResults` are `DocumentData` wrapping the contracts classification model:

- [`ClassificationResult`](../../UiPath.DocumentProcessing.Contracts/classes/ClassificationResult.md) — the underlying classification contract. The reviewer's correction surfaces here as a different `DocumentTypeId` / `DocumentTypeName`. Use `AsExtractionResult(taxonomy)` if you need to seed an extraction result programmatically.
