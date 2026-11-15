# Wait for Classification Validation Task & Resume

`UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation.WaitForClassificationValidationAction`

**XAML element:** `<duVal:WaitForClassificationValidationAction …>` *(not generic — no `x:TypeArguments`; note the class has **no** `AndResume` suffix even though the friendly title does)*
**xmlns prefix:** `duVal` → `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`
**Pairs with:** Required completion of a `CreateClassificationValidationAction` upstream — `CreatedClassificationValidationAction` input comes from that activity's output. Output `ValidatedClassificationResults` (validated `DocumentData`) feeds `ExtractDocumentDataWithDocumentData.FileInput`.

Waits for the completion of a Classification Validation Task (created by the **Create Classification Validation Task** activity) and resumes the workflow with the validated classification results.

**Package:** `UiPath.DocumentUnderstanding.Activities`
**Category:** Document Understanding

## Properties

### Input

| Name | Display Name | Kind | Type | Required | Default | Description |
|------|-------------|------|------|----------|---------|-------------|
| `CreatedClassificationValidationAction` | Created Classification Validation Task | InArgument | `CreatedClassificationValidationAction` | Yes | | The output of the **Create Classification Validation Task** activity. |
| `RemoveDataFromStorage` | Remove Data From Storage | InArgument | `bool` | No | `false` | If checked, deletes the files staged for the classification validation task after it reaches a terminal state. |

### Output

| Name | Display Name | Kind | Type | Description |
|------|-------------|------|------|-------------|
| `ValidatedClassificationResults` | Document data | OutArgument | `DocumentData` | Validated classification data containing changes made by the reviewer in Classification Station. |

**JSON serialization.** This output serializes as a plain JSON object, so it can be bound to a **job out-argument** (e.g. returned from an RPA workflow element to a Maestro process variable) and read back into a `DocumentData` / `IDocumentData<DictionaryData>` in-argument in another workflow. See [JSON serialization](../overview.md#documentdata-classification) in the overview for the details and limits.

## XAML Example

```xml
<duVal:WaitForClassificationValidationAction
    DisplayName="Wait for Classification Validation Task"
    CreatedClassificationValidationAction="[createdClassificationAction]"
    RemoveDataFromStorage="True"
    ValidatedClassificationResults="[validatedClassification]" />
```

> Namespace prefix `duVal` maps to `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DataValidation;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`.

## Notes

- This is a **persistent activity**. The workflow suspends while waiting for the validation task to be completed in Action Center. The project must have `"supportsPersistence": true` in `project.json` (under `"runtimeOptions"`). Without this, the workflow will fail at runtime.
- Cannot be placed inside a No Persist Scope.
- Must be used after a **Create Classification Validation Task** activity. The `CreatedClassificationValidationAction` input must come from that activity's output.
- In a typical pipeline, the `ValidatedClassificationResults` output (`DocumentData`) is passed as `FileInput` to **Extract Document Data**. `DocumentData` implements `IResource`, so it can be used directly.

### Remove Data From Storage

For a successful same-organization task, files are deleted only after the validated result and document have been downloaded. Rejected and deleted tasks attempt cleanup before returning their terminal error. Cross-organization tasks delegate cleanup to the Action Center service. A task that is already completed or deleted when the activity starts never suspends, so cleanup runs inline instead — on both the same-organization and the cross-organization path.

The robot's Orchestrator role needs these folder permissions:

| Permission | Required |
|---|---|
| Storage Files | View, Delete |
| Storage Buckets | View |
| Actions | View |

Individual delete failures are logged and skipped rather than failing the workflow. Therefore, workflow completion alone does not prove that the task's storage directory is empty; verify the bucket contents when cleanup is an acceptance criterion.

The `AreFilesRemoved` telemetry field reflects whether at least one staged file was actually deleted, on both the same-organization and the cross-organization path. Individual per-file failures are logged; read the robot logs to see which file failed.

## Supporting References

The `ValidatedClassificationResults` output is a `DocumentData` wrapping the contracts classification model:

- [`ClassificationResult`](../../UiPath.DocumentProcessing.Contracts/classes/ClassificationResult.md) — the underlying classification contract. The reviewer's correction surfaces here as a different `DocumentTypeId` / `DocumentTypeName`.
