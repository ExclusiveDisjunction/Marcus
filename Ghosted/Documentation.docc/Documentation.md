# ``Ghosted``

A software solution for job application management. 

## Overview

Often times in the modern world, people are faced with an issue. How to keep track of all of their job applications. To this, we provide a simple solution, Ghosted. Ghosted is a macOS, iPadOS, and iOS app for keeping track of all job applications you submit. As you submit applications, you can record them in Ghosted. Then, over time, it will help you stay on top of these applications. Follow up emails, reminders, goals, and so much more.

## Topics

### Job Applications

- ``JobApplication``
- ``JobKind``
- ``JobApplicationState``
- ``JobLocation``
- ``AllApplications``
- ``JobApplicationInspect``
- ``JobApplicationEdit``
- ``JobStats``
- ``JobStatsViewer``
- ``JobsFilter``
- ``ApplicationsFilterState``
- ``ApplicationsSearchState``

### Core UI 

- ``ContentView``
- ``GeneralCommands``
- ``GhostedApp``

### Element Information

- ``Displayable``
- ``TypeTitleStrings``
- ``TypeTitled``
- ``ElementBase``
- ``NamedElement``
- ``InspectableElement``
- ``EditableElement``
- ``DefaultableElement``
- ``IsolatedDefaultableElement``

### Element Management

- ``DeletingManifest``
- ``ElementDeleteButton``
- ``DeletingActionConfirm``
- ``DeleteConfirmModifier``
- ``SwiftUICore/View/withElementDeleting(manifest:post:)``

- ``InspectionManifest``
- ``InspectionState``
- ``EditableElementManifest``
- ``ElementAddManifest``
- ``ElementAddButton``
- ``ElementEditManifest``
- ``ElementEditButton``
- ``ElementEditor``
- ``WithEditorModifier``
- ``SwiftUICore/View/withElementEditor(manifest:using:filling:post:)``
- ``ElementInspectButton``
- ``ElementInspector``
- ``WithInspectorModifier``
- ``SwiftUICore/View/withElementInspector(manifest:)``
- ``ElementSelectionMode``
- ``ElementIE``
- ``WithInspectorEditorModifier``
- ``SwiftUICore/View/withElementIE(manifest:using:filling:post:)``
- ``ElementPicker``

- ``SelectionContextMenu``
- ``SingularContextMenu``

### Object Selection

- ``SelectionContextProtocol``
- ``QuerySelection``
- ``FilterableQuerySelection``
- ``SourcedSelection``
- ``FrozenSelectionContext``
- ``SelectionContext``

### Warnings

- ``WarningBasis``
- ``WarningManifest``
- ``InternalErrorWarning``
- ``InternalWarningManifest``
- ``SelectionWarningKind``
- ``SelectionWarningManifest``
- ``StringWarning``
- ``StringWarningManifest``
- ``ValidationFailure``
- ``ValidationFailureReason``
- ``ValidationFailureBuilder``
- ``ValidationWarningManifest``
- ``WarningManifestExtension``
- ``SwiftUICore/View/withWarning(_:)``

### Core Data Tools

- ``ContainerDataFiller``
- ``DataStack``
- ``DebugSampleData``
- ``DebugContainerFiller``

### Miscellaneous Tools

- ``NullableValue``
- ``NullableValueBacking``
- ``DatesFilterRange``
- ``EnumPicker``
- ``DisplayableVisualizer``
- ``NamedVisualizer``
- ``FilterSubsection``
- ``TypeTitleVisualizer``
