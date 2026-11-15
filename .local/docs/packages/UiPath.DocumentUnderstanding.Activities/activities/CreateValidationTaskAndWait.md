# Create Validation Task and Wait

`UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation.ValidateDocumentDataWithDocumentData`

**XAML element:** `<duVal:ValidateDocumentDataWithDocumentData x:TypeArguments="dux:DictionaryData" …>` *(generic — `x:TypeArguments` is required and must match `ExtractDocumentDataWithDocumentData<T>`. **Note: the friendly title "Create Validation Task and Wait" does not map to a `CreateValidationActionAndWait` class — the class is `ValidateDocumentDataWithDocumentData`.**)*
**xmlns prefixes:** `duVal` → `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities` (the activity), `dux` → `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataExtraction;assembly=UiPath.IntelligentOCR.StudioWeb.Activities` (the type argument)
**Pairs with:** Single-step replacement for `CreateValidationAction<T>` + `WaitForValidationAction<T>`. Input `AutomaticExtractionResults` from `ExtractDocumentDataWithDocumentData.ExtractionResults`. Output `ValidatedExtractionResults` is the final reviewed `IDocumentData<T>` for downstream reads.

Creates a Document Validation Task in Action Center to verify extracted document data and suspends the workflow until the task is completed. After a human reviewer submits the validated data, the workflow resumes with the corrected extraction results.

**Package:** `UiPath.DocumentUnderstanding.Activities`
**Category:** Document Understanding

## Properties

### Input

| Name | Display Name | Kind | Type | Required | Default | Description |
|------|-------------|------|------|----------|---------|-------------|
| `AutomaticExtractionResults` | Document Data | InArgument | `IDocumentData<ExtendedExtractionResultsForDocumentData>` | Yes | | The extraction result, output of the Extract Document Data activity. |
| `ActionTitle` | Action title | InArgument | `string` | Yes | | Title of the action as it appears in Action Center. |
| `ActionPriority` | Action priority | InArgument | `string` | | | Priority of the action. |
| `ActionCatalogue` | Action catalog | InArgument | `string` | | | Catalog where the action will be available in Action Center. The task is created in `OrchestratorFolderName`, so the catalog must exist in that folder. In a Solution, use the name of a task catalog resource of the solution, deployed in the same folder as the storage bucket resource. |
| `OrchestratorFolderName` | Orchestrator folder | InArgument | `string` | | | Orchestrator folder where the action will be available. |
| `OrchestratorBucketName` | Orchestrator bucket | InArgument | `string` | | `"du_storage_bucket"` | Orchestrator storage bucket for documents and data required for validation. The bucket must exist in the target tenant. Do not set this property unless the user specifies a bucket name — omitting it uses the default (`SWConstants.DefaultBucketName`). |

### Configuration

| Name | Display Name | Type | Default | Description |
|------|-------------|------|---------|-------------|
| `FieldsValidationConfidence` | Extracted fields validation confidence % | `int?` | | Upper-limit confidence score for filtering extracted fields that need human review. |
| `EnableRTLControls` | Enable RTL controls | `bool` | `false` | Enable right-to-left controls in Validation Station. |
| `DisplayMode` | Display mode | `DisplayModeArgument` | `Classic` | Display mode for Validation Station. |
| `RemoveDataFromStorage` | Remove Data From Storage | `bool` | `false` | If checked, the document's data is deleted from the storage bucket once the validation task completes. |

### Output

| Name | Display Name | Kind | Type | Description |
|------|-------------|------|------|-------------|
| `ValidatedExtractionResults` | Document data | OutArgument | `IDocumentData<ExtendedExtractionResultsForDocumentData>` | Validated extracted data containing changes made by the reviewer in Validation Station. |

**JSON serialization.** This output serializes as a plain JSON object, so it can be bound to a **job out-argument** (e.g. returned from an RPA workflow element to a Maestro process variable) and read back into a `DocumentData` / `IDocumentData<DictionaryData>` in-argument in another workflow. See [JSON serialization](../overview.md#documentdata-classification) in the overview for the details and limits.

## Enum Reference

**`DisplayModeArgument`**: `Classic`, `Compact`

## XAML Example

```xml
<duVal:ValidateDocumentDataWithDocumentData
    x:TypeArguments="dux:ExtendedExtractionResultsForDocumentData"
    DisplayName="Create Validation Task and Wait"
    AutomaticExtractionResults="[extractionResults]"
    ActionTitle="[&quot;Validate extraction&quot;]"

    ValidatedExtractionResults="[validatedResults]" />
```

> Namespace prefix `duVal` maps to `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`.
> Namespace prefix `dux` maps to `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataExtraction;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`.

### DictionaryData Variant

When using `DictionaryData` for the extraction pipeline (recommended for agent-generated workflows):

```xml
<duVal:ValidateDocumentDataWithDocumentData
    x:TypeArguments="dux:DictionaryData"
    DisplayName="Create Validation Task and Wait"
    AutomaticExtractionResults="[extractionResults]"
    ActionTitle="[&quot;Validate extraction&quot;]"

    ValidatedExtractionResults="[validatedResults]" />
```

**Required variable declarations:**

```xml
<Variable x:TypeArguments="dux:IDocumentData(dux:DictionaryData)" Name="extractionResults" />
<Variable x:TypeArguments="dux:IDocumentData(dux:DictionaryData)" Name="validatedResults" />
```

### Remove Data From Storage

Deletes every file the validation task staged in the storage bucket, including the original document. Files are removed from the bucket the task was created against, in the folder that hosts it.

The robot's Orchestrator role needs these folder permissions:

| Permission | Required |
|---|---|
| Storage Files | View, Delete |
| Storage Buckets | View |
| Actions | View |

Without **Delete** on Storage Files, no file is removed. Individual delete failures are logged and skipped rather than failing the workflow, so a completed workflow does not on its own mean the bucket is empty.

The `RemoveDataFromStorageOutcome` telemetry field says what the cleanup did, on both the same-org and the cross-org path:

| Value | In telemetry | Meaning |
| --- | --- | --- |
| `NotRequested` | `0` | The option was off. |
| `Removed` | `1` | At least one staged file was deleted. |
| `NothingToRemove` | `2` | Nothing was staged under the task's directory. |
| `BucketNotResolved` | `3` | The bucket name matched no single bucket, so nothing was touched. |
| `FolderNotResolved` | `4` | No Orchestrator folder could be resolved for the bucket, so nothing was touched. |
| `RemovalFailed` | `5` | Files were there and every delete failed. |
| `ContentsNotResolved` | `6` | The task's directory could not be listed, so nothing was touched and it is not known whether anything was staged. |

Telemetry carries the number, not the name. Query for `1`, not for `Removed`.

An empty field means the activity reached no cleanup verdict, which is not the same as `NotRequested`.

`AreFilesRemoved` is kept for compatibility and is `true` only when the outcome is `Removed`. Individual per-file failures are logged; read the robot logs to see which file failed.

A solution resource is the exception: its artifacts are kept for the rehydration that follows the resume. A rejected one is not exempt. There is no rehydration left to protect, so its files are removed like any other document's.

Because this activity creates and waits in one step, removal runs after the reviewer completes the task and the document has been rehydrated.

Rejection behaves differently on the two paths. A cross-org task removes the files and then reports the rejection, so the bucket is emptied. A same-org task reports the rejection first, so the staged files stay in the bucket.

Once the data is removed, the completed action is no longer available in Action Center.

## Notes

- This is a **persistent activity**. The workflow suspends after creating the validation task and resumes only when the task is completed in Action Center. The project must have `"supportsPersistence": true` in `project.json` (under `"runtimeOptions"`). Without this, the workflow will fail at runtime.
- This is a generic activity. In XAML, use `x:TypeArguments="dux:ExtendedExtractionResultsForDocumentData"` or `x:TypeArguments="dux:DictionaryData"`.
- The type argument **must match** the type argument used in `ExtractDocumentDataWithDocumentData`. If extraction used `DictionaryData`, this activity must also use `DictionaryData`.
- For a non-blocking alternative, use **Create Validation Task** followed by **Wait for Validation Task and Resume** to separate task creation from waiting.
- Cannot be placed inside a No Persist Scope.
- In a typical pipeline, this activity follows Extract Document Data. It combines the functionality of Create Validation Task + Wait for Validation Task and Resume into a single step.

## Supporting References

The `AutomaticExtractionResults` input and `ValidatedExtractionResults` output are `IDocumentData<T>` over the contracts `ExtractionResult`. To inspect or post-process the validated result in code:

- [`ExtractionResultHandler`](../../UiPath.DocumentProcessing.Contracts/classes/ExtractionResultHandler.md) — fluent navigator. Reach it via `validatedResults.Data.Handler`.
- [`ExtractionResult`](../../UiPath.DocumentProcessing.Contracts/classes/ExtractionResult.md) — the underlying data contract; covers per-field validator notes (`GetFieldValidatorNotes` / `SetFieldValidatorNotes`), business-rule exceptions (`HasExceptions*`), and the five supported field shapes.
