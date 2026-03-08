.pragma library

function getPriorityColor(priority, Color) {
    if (priority === "H")
        return Color.mError;
    if (priority === "M")
        return Color.mPrimary;
    return Color.mOnSurfaceVariant;
}

function formatDueDate(dueStr, pluginApi) {
    if (!dueStr || dueStr === "")
        return "";
    try {
        var d = new Date(dueStr);
        var now = new Date();
        var diffMs = d.getTime() - now.getTime();
        var diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
        if (diffDays < 0)
            return pluginApi?.tr("panel.due-overdue") || "Overdue";
        if (diffDays === 0)
            return pluginApi?.tr("panel.due-today") || "Today";
        if (diffDays === 1)
            return pluginApi?.tr("panel.due-tomorrow") || "Tomorrow";
        return d.toLocaleDateString();
    } catch (e) {
        return dueStr;
    }
}

function isDueOverdue(dueStr) {
    if (!dueStr || dueStr === "")
        return false;
    try {
        return new Date(dueStr) < new Date();
    } catch (e) {
        return false;
    }
}

function formatDateForInput(dateStr) {
    if (!dateStr || dateStr === "")
        return "";
    try {
        var d = new Date(dateStr);
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    } catch (e) {
        return dateStr;
    }
}
