import WidgetKit
import SwiftUI
import AppIntents

/// A Control Center and Lock Screen button: one tap opens Sova ready to
/// type a new task.
struct NewTaskControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "app.sova.Sova.NewTask") {
            ControlWidgetButton(action: OpenQuickCaptureIntent()) {
                Label("New Task", systemImage: "plus.circle.fill")
            }
        }
        .displayName("New Task")
        .description("Open Sova ready to type a task.")
    }
}
