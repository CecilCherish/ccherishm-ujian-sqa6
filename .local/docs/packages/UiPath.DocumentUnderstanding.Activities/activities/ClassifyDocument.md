# Classify Document

`UiPath.IntelligentOCR.StudioWeb.Activities.ClassifyDocument`

**XAML element:** `<du:ClassifyDocument …>` *(not generic — no `x:TypeArguments`)*
**xmlns prefix:** `du` → `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`
**Pairs with:** Usually the first DU activity. Output `ClassificationResults` (`DocumentData`) feeds `ExtractDocumentDataWithDocumentData.FileInput` directly (`DocumentData` implements `IResource`). To validate the classification first, route it through `CreateClassificationValidationActionAndWait` (single step) or `CreateClassificationValidationAction` + `WaitForClassificationValidationAction` (split).

Classifies a document according to the configured classifier in the Document Understanding framework. Supports pretrained classifiers for standard document types (invoices, receipts, id_cards, passports, purchase_orders, utility_bills, remittance_advices, bills_of_lading, checks).

**Package:** `UiPath.DocumentUnderstanding.Activities`
**Category:** Document Understanding

## Properties

### Input

| Name | Display Name | Kind | Type | Required | Default | Description |
|------|-------------|------|------|----------|---------|-------------|
| `ProjectId` | Project | InArgument | `string` | Yes | | The Document Understanding project ID. A GUID (e.g., `"00000000-0000-0000-0000-000000000000"` for the Predefined project), or a non-GUID placeholder when `ProjectName` is set (the runtime then resolves the project by name). For custom projects, if the GUID is unknown, set `ProjectName` to the project's display name and use a non-GUID placeholder string for ProjectId (e.g., ProjectId="placeholder"). Do not use "00000000-0000-0000-0000-000000000000" — that is the Predefined project's real GUID and will be accepted as-is without triggering name-based resolution — **Studio resolves `ProjectId` from `ProjectName` at design time**. Set as a **literal attribute value** (not a VB expression). |
| `ProjectVersionNumber` | Version | InArgument | `int` | No | | The version number referencing a snapshot of the Document Understanding project. Studio fills it also when a tag is picked. If `ProjectTag` is set and points to a different version, the tag wins. For the Predefined project, use `0`. |
| `ProjectTag` | Tag | InArgument | `string` | No | | A tag referencing a snapshot of the Document Understanding project (e.g., `"Production"`). Studio sets it only when a tag is picked. If set, the runtime uses the version that carries the tag, even if `ProjectVersionNumber` points elsewhere. For the Predefined project, use `"Production"`. |
| `ClassifierId` | Classifier | InArgument | `string` | Yes | | The classifier to use. For the Predefined project, use `ml-classification` (recommended) or a document-type-specific identifier (see Enum Reference). For custom DU projects, use the **classifier name** from the project. Ask the user for this name. Studio resolves names to internal GUIDs at design time. Set `ClassifierName` to the same value. |
| `FileInput` | Input | InArgument | `IResource` | Yes | | Document Data referencing the digitized input file, or the input file itself if Document Data has not been created yet. |
| `TimeoutInSeconds` | Timeout (seconds) | InArgument | `int` | Yes | `3600` | Maximum execution time in seconds. If exceeded, the operation is terminated. |
| `GptPromptWithVariables` | Prompt | Property | `Dictionary<string, InArgument<string>>` | Only for the generative classifier | empty | The document types the generative classifier can choose from: key = document type name, value = a description that helps identify it. Ignored by other classifiers; write an empty dictionary for them (see XAML Example). |

### Configuration

| Name | Display Name | Type | Default | Description |
|------|-------------|------|---------|-------------|
| `MinimumConfidence` | Minimum confidence | `float` | `0` | Minimum confidence threshold for classification. If the classification confidence is below this value, the document type is set to Unknown. **Scale is 0 to 100** (a percentage), while `DocumentType.Confidence` in the results is 0.0 to 1.0: `MinimumConfidence="80"` means 0.8. When the attribute is omitted the runtime uses `0` (every result accepted); Studio's designer fills in `50` for a new activity, so set it explicitly to match a Studio-built workflow. |
| `RuntimeAssetPath` | Credentials Asset | `string` | | Orchestrator credentials asset path used to authenticate against the Document Understanding tenant. Should have the form `<orchestratorFolder>/<assetName>`. |
| `RuntimeTenantUrl` | Tenant URL | `string` | | URL of the tenant used to authenticate against the Document Understanding service. Should have the form `https://<base_url>/<organization>/<tenant>`. |

### Output

| Name | Display Name | Kind | Type | Description |
|------|-------------|------|------|-------------|
| `ClassificationResults` | Document data | OutArgument | `DocumentData` | Classification results. The `DocumentType` property contains the classified type, confidence, and identifiers. May contain multiple subdocuments if document splitting is enabled. See Type Reference below. |

### Studio UI Display Properties

These properties control how Studio's designer renders dropdown selections and drive name-based resolution. When generating XAML programmatically, always set them alongside their corresponding functional properties. They are marked `Browsable(false)` in the source code but are serialized in XAML by Studio.

| Property | Type | Role | Example Value |
|----------|------|------|---------------|
| `ProjectName` | `string` | **Drives resolution of `ProjectId`** — Studio looks up the project by this name and populates `ProjectId` with the GUID at design time. | `"Predefined"` |
| `ProjectVersionName` | `string` | The tag name when a tag is picked, otherwise the picked version's name | `"Production"` |
| `ClassifierName` | `string` | Mirrors `ClassifierId` | `"ML Classification"` |
| `Endpoint` | `string` | **Required at runtime** — the activity fails with `Endpoint not specified` when it is missing. Studio fills it from the selected classifier. When writing XAML without Studio, set any non-empty value: the classification calls do not use it, it is only copied into `DocumentType.Url`. | `"placeholder"` |

## Type Reference

### DocumentData

**CLR type:** `UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification.DocumentData`
**Assembly:** `UiPath.IntelligentOCR.StudioWeb.Activities`
**XAML xmlns:** `clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification;assembly=UiPath.IntelligentOCR.StudioWeb.Activities`

| Property | Type | Description |
|----------|------|-------------|
| `DocumentType` | `DocumentType` | The classified document type (see below). |
| `SubDocuments` | `IDocumentData[]` | Array of subdocuments when splitting is enabled. When the file was split, the parent's own `DocumentType` is `null`; read the type of each entry instead. |
| `FileDetails` | `FileDetails` | File path, name, extension, and page range of the source document. For a sub-document, read the pages from `FileDetails.PageRange.PageRange` (a 1-based string such as `"3-4"`). `PageRange.StartPage`, `TextStartIndex` and `TextLength` are obsolete and not reliably populated (often `0`); do not read them. |
| `DocumentMetadata` | `DocumentMetadata` | OCR text (`Text`), document object model (`DocumentObjectModel`), language, and extraction results as DataTables (`ResultsAsDataTables`). `SplitConfidence` is `-1` after Classify Document (the service returns no split confidence). Classification validation sets it to `1` on the sub-documents it creates; other activities pass the value through. Do not build a threshold on it. |

**JSON serialization.** `DocumentData` serializes as a plain JSON object, so `ClassificationResults` (or its `SubDocuments`) can be bound to a **job out-argument** — e.g. returned from an RPA workflow element to a Maestro process variable — and read back into a `DocumentData` / `IDocumentData` in-argument in another workflow. A deserialized document keeps the classification results but its `FileDetails.LocalPath` refers to the producing robot's file system. See [JSON serialization](../overview.md#documentdata-classification) in the overview for the details and limits.

### DocumentType

**CLR type:** `UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification.DocumentType`

| Property | Type | Description |
|----------|------|-------------|
| `DisplayName` | `string` | Human-readable label (e.g., `"Invoices"`). |
| `Id` | `string` | Machine identifier (e.g., `"invoices"`). Use this for programmatic comparisons and for passing to ExtractDocumentData's `DocType`. |
| `Confidence` | `float` | Classification confidence score (0.0 to 1.0). |
| `Name` | `string` | **Obsolete.** Use `Id` instead. |
| `Url` | `string` | Reference URL for the document type definition. |

**VB expression examples:**
- `classificationResults.DocumentType.Id` — returns `"invoices"`
- `classificationResults.DocumentType.DisplayName` — returns `"Invoices"`
- `classificationResults.DocumentType.Confidence` — returns confidence score

## Enum Reference

### Classifier Identifiers

| Identifier | Display Name | Description |
|------------|-------------|-------------|
| `ml-classification` | ML Classification | General-purpose multi-class classifier that distinguishes between all supported pretrained document types. **Recommended for most use cases.** |

### Pretrained Document Type Identifiers

These lowercase identifiers can be used as `ClassifierId` for single-type classification:

| Identifier | Display Name |
|------------|-------------|
| `invoices` | Invoices |
| `receipts` | Receipts |
| `id_cards` | ID Cards |
| `passports` | Passports |
| `purchase_orders` | Purchase Orders |
| `utility_bills` | Utility Bills |
| `remittance_advices` | Remittance Advices |
| `bills_of_lading` | Bills of Lading |
| `checks` | Checks |

## XAML Example

Classifies a document using the Predefined project with the ML Classification classifier. Replace `[inputFile]` with an `IResource` variable pointing to the document.

```xml
<du:ClassifyDocument
    DisplayName="Classify Document"
    ProjectId="00000000-0000-0000-0000-000000000000"
    ProjectName="Predefined"
    ProjectTag="Production"
    ProjectVersionName="Production"
    ProjectVersionNumber="0"
    ClassifierId="ml-classification"
    ClassifierName="ML Classification"
    Endpoint="placeholder"
    FileInput="[inputFile]"
    TimeoutInSeconds="[3600]"
    ClassificationResults="[classificationResults]">
  <du:ClassifyDocument.GptPromptWithVariables>
    <scg:Dictionary x:TypeArguments="x:String, InArgument(x:String)" />
  </du:ClassifyDocument.GptPromptWithVariables>
</du:ClassifyDocument>
```

**Generative classifier.** Uses the Generative Predefined project (no tag or version) and lists the candidate document types in `GptPromptWithVariables`. It returns one result and never splits.

```xml
<du:ClassifyDocument
    DisplayName="Classify Document"
    ProjectId="00000000-0000-0000-0000-000000000001"
    ProjectName="Generative Predefined"
    ClassifierId="generative_classifier"
    ClassifierName="Generative Classifier"
    Endpoint="placeholder"
    FileInput="[inputFile]"
    TimeoutInSeconds="[3600]"
    ClassificationResults="[classificationResults]">
  <du:ClassifyDocument.GptPromptWithVariables>
    <InArgument x:TypeArguments="x:String" x:Key="invoice">A bill requesting payment for goods or services</InArgument>
    <InArgument x:TypeArguments="x:String" x:Key="receipt">Proof that a payment was made</InArgument>
  </du:ClassifyDocument.GptPromptWithVariables>
</du:ClassifyDocument>
```

**Required variable declaration:**

```xml
<Variable x:TypeArguments="duc:DocumentData" Name="classificationResults" />
```

**Required XAML namespace prefixes:**

```xml
xmlns:du="clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities;assembly=UiPath.IntelligentOCR.StudioWeb.Activities"
xmlns:duc="clr-namespace:UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification;assembly=UiPath.IntelligentOCR.StudioWeb.Activities"
xmlns:scg="clr-namespace:System.Collections.Generic;assembly=mscorlib"
```

**Required expression namespace imports:**

```xml
<TextExpression.NamespacesForImplementation>
  <scg:List x:TypeArguments="x:String">
    <x:String>UiPath.IntelligentOCR.StudioWeb.Activities</x:String>
    <x:String>UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification</x:String>
  </scg:List>
</TextExpression.NamespacesForImplementation>
<TextExpression.ReferencesForImplementation>
  <scg:List x:TypeArguments="AssemblyReference">
    <AssemblyReference>UiPath.IntelligentOCR.StudioWeb.Activities</AssemblyReference>
  </scg:List>
</TextExpression.ReferencesForImplementation>
```

## Cross-org authentication

This activity can authenticate against an external Document Understanding tenant via an Orchestrator credential asset. The same `Credentials Asset` value is used at both design time (to populate the Project / Version / Classifier dropdowns from the external tenant) and runtime (to acquire the access token when the activity executes).

### Design-time UX

To author a `ClassifyDocument` activity that authenticates against an external Document Understanding tenant:

1. Set **Credentials Asset** (`RuntimeAssetPath`) to the Orchestrator credential asset path. Format: `<orchestratorFolder>/<assetName>`.
2. Set **Tenant URL** (`RuntimeTenantUrl`) to the external tenant URL. Format: `https://<base_url>/<organization>/<tenant>`.
3. Click **Connect**. StudioWeb resolves the asset's username/password via Orchestrator and authenticates against the external tenant. The Project / Version / Classifier dropdowns then populate from the external tenant.

### Variable expressions block Connect

If **Credentials Asset** or **Tenant URL** contains a variable expression (for example `In_AssetPath`), clicking **Connect** surfaces this error and the connection is not attempted:

```text
The Connect button needs the actual asset path and tenant URL — variable expressions only resolve when running the workflow.
```

This design-time check is intentional: variables are only resolved at runtime, so the editor cannot use them to authenticate. To work with cross-org authentication where the asset path or tenant URL is dynamic, set literal values during authoring and rely on the runtime path to honor the variable substitution at execution time.

### Disconnect

Clicking **Connect** a second time disconnects from the external tenant. The Project dropdown stays visible but is cleared; clicking **Connect** again with valid literals reconnects.

### Note on previous versions

Earlier StudioWeb releases required separate `DesigntimeAppId`, `DesigntimeAppSecret`, and `DesigntimeTenantUrl` fields at design time. Those fields have been removed; the same **Credentials Asset** now feeds both design time and runtime. Existing customer workflows (`.xaml`) continue to load unchanged because the underlying property names (`RuntimeAssetPath`, `RuntimeTenantUrl`) are preserved.

## Notes

- `ProjectId` is either the project GUID or, when `ProjectName` is set, any non-GUID placeholder — the runtime then resolves the project by name. The Predefined project GUID is `00000000-0000-0000-0000-000000000000`. Studio also resolves `ProjectId` from `ProjectName` at design time, so the GUID does not need to be known at authoring time.
- Properties backed by Studio dropdown widgets (`ProjectId`, `ProjectTag`, `ProjectVersionNumber`, `ClassifierId`) should be set as **literal attribute values** rather than VB/C# expressions (e.g., `ProjectId="00000000-..."` not `ProjectId="[&quot;00000000-...&quot;]"`) to ensure the dropdown displays correctly in the designer.
- For the Predefined project, the standard version configuration is: `ProjectTag="Production"`, `ProjectVersionNumber="0"`, `ProjectVersionName="Production"`.
- `ProjectVersionNumber` and `ProjectTag` are two ways to reference a project snapshot. Use one or the other. If neither is specified, the Staging version is used by default; if not available, the latest version is used.
- For custom DU projects, set `ClassifierId` to the **classifier name** from the project. Studio resolves the name to the internal GUID at design time. Set `ClassifierName` to the same value. Ask the user for the classifier name if not provided.
- The `ClassificationResults` output is of type `DocumentData` (namespace `UiPath.IntelligentOCR.StudioWeb.Activities.DocumentClassification`). Access the classified type via `classificationResults.DocumentType.Id` (lowercase identifier like `"invoices"`) or `classificationResults.DocumentType.DisplayName` (human-readable like `"Invoices"`). Do **not** use `.ToString()` on `DocumentType` — it returns the CLR type name, not the classification label.
- `DocumentType.Name` is obsolete — use `DocumentType.Id` instead.
- When splitting is enabled, each entry in `SubDocuments` is a `DocumentData` with its own `DocumentType` and `FileDetails`. Read a sub-document's pages from `FileDetails.PageRange.PageRange` (1-based string, e.g. `"3-4"`), never from `PageRange.StartPage`, which is obsolete and not reliably populated. Splitting is a setting of Helix and MLS classifiers in the project version; a generative classifier always returns a single result and never splits.
- `DocumentMetadata.SplitConfidence` is `-1` after Classify Document and `1` on sub-documents created by classification validation; do not build a threshold on it. `MinimumConfidence` (0–100) is the only supported gate, and it compares against `DocumentType.Confidence` (0–1) scaled by 100.
- `RuntimeAssetPath` and `RuntimeTenantUrl` enable cross-organization access. Both must be set together. See [Cross-org authentication](#cross-org-authentication) for the design-time flow and the variable-expression hard-error.
- In a typical pipeline, this is the first activity. Its `ClassificationResults` output (`DocumentData`) feeds into classification validation activities and/or directly into `ExtractDocumentDataWithDocumentData` as `FileInput` (`DocumentData` implements `IResource`).

## Supporting References

When you need to drop down to the contracts data model behind `DocumentData`:

- [`ClassificationResult`](../../UiPath.DocumentProcessing.Contracts/classes/ClassificationResult.md) — the underlying classification contract. `ClassificationResult.AsExtractionResult(taxonomy)` is the bridge that seeds an `ExtractionResult` for downstream extraction.
- [`Document`](../../UiPath.DocumentProcessing.Contracts/classes/Document.md) — the DOM exposed via `DocumentData.DocumentMetadata.DocumentObjectModel`. Use it to walk pages / sections / words / boxes referenced by the classification.

Both links resolve at agent runtime once `PackageDocsSync` extracts the contracts package alongside this one under `.local/docs/packages/`.
