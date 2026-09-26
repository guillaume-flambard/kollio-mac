import SwiftUI
import KollioCore

/// A comparison of several directions, criterion by criterion.
///
/// The card is shaped by what AI-05 forbids. There is **no score column by
/// default**: a total appears only when every criterion has a measure *and* a
/// weight the person typed, and until then the card says so rather than showing a
/// zero. A cell nobody filled in reads "Not recorded", which is an answer, where a
/// blank would read as an oversight and a zero would read as a bad result.
///
/// Two lists, because a comparison that shows only its cells is a spreadsheet. The
/// criteria are questions, the cells are what was observed, and the references are
/// what each answer rests on, so nothing here can be read without also being
/// checkable.
struct ComparisonView: View {
    let model: KollioModel
    let id: ComparisonID

    @Environment(\.kollioTheme) private var theme
    @FocusState private var focused: Bool

    private var comparison: Comparison? { model.comparison(id) }

    var body: some View {
        if let comparison {
            VStack(alignment: .leading, spacing: Space.s) {
                header(comparison)
                if let reason = model.comparisonNeedsReview(id) {
                    reviewBanner(reason)
                }
                if comparison.isDraft {
                    draftBlock(comparison)
                }
                criteriaBlock(comparison)
                directionsBlock(comparison)
                HStack {
                    Spacer(minLength: 0)
                    ActionButton(title: L10n.comparisonClose, isDefault: false) {
                        model.openComparison = nil
                    }
                }
            }
            .padding(Space.l)
            .frame(width: 460, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .fill(theme.surfacePrimary)
                    .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.14), radius: 18, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.richBlock, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
        }
    }

    // MARK: Blocks

    private func header(_ comparison: Comparison) -> some View {
        HStack(spacing: Space.xs) {
            Text(L10n.comparisonTitle)
                .font(TypeScale.metadata.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
            Spacer(minLength: 0)
            // A total is a claim about the whole comparison, so it is stated once,
            // for every direction, or not at all.
            if comparison.hasDefinedTotals {
                Image(systemName: "sum")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .help(L10n.comparisonWeight)
            } else {
                Text(L10n.comparisonNoTotal)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private func reviewBanner(_ reason: ComparisonReviewReason) -> some View {
        HStack(alignment: .top, spacing: Space.xs) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.attention)
            Text(label(for: reason))
                .font(TypeScale.metadata)
                .foregroundStyle(theme.attention)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.attention.opacity(0.10))
        )
    }

    private func label(for reason: ComparisonReviewReason) -> String {
        switch reason {
        case .referenceGone: return L10n.comparisonReviewGone
        case .referencedObjectChanged: return L10n.comparisonReviewObjectChanged
        case .evidenceMoved: return L10n.comparisonReviewEvidenceMoved
        }
    }

    /// The draft: the criteria are a question, and nothing is recorded until the
    /// person agrees to them.
    private func draftBlock(_ comparison: Comparison) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(L10n.comparisonDraftHint)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ActionButton(title: L10n.comparisonConfirm, isDefault: true) {
                _ = model.confirmComparisonCriteria(id)
            }
        }
    }

    private func criteriaBlock(_ comparison: Comparison) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(L10n.comparisonCriteria)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
            if comparison.criteria.isEmpty {
                Text(L10n.comparisonNoCriterion)
                    .font(TypeScale.body)
                    .foregroundStyle(theme.textSecondary)
            }
            ForEach(comparison.criteria) { criterion in
                criterionRow(criterion, comparison: comparison)
            }
            HStack(spacing: Space.xs) {
                TextField(
                    L10n.comparisonCriterionPlaceholder,
                    text: Binding(
                        get: { criterionDraft },
                        set: { criterionDraft = $0 }
                    )
                )
                .textFieldStyle(.plain)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textPrimary)
                .focused($focused)
                .onSubmit { submitCriterion() }
                ActionButton(title: L10n.comparisonAddCriterion, isDefault: false) {
                    submitCriterion()
                }
            }
        }
    }

    @ViewBuilder
    private func criterionRow(_ criterion: Criterion, comparison: Comparison) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            criterionHeadline(criterion)
            if editingCriterion == criterion.id {
                criterionEditor(criterion)
            }
        }
    }

    private func criterionHeadline(_ criterion: Criterion) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
            Text(criterion.title)
                .font(TypeScale.body.weight(.medium))
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let measure = criterion.measure {
                // The unit and the direction of "better", stated. A criterion
                // without one cannot hold a number and says so instead of offering
                // a field that would be refused.
                Text("\(L10n.comparisonMeasure) \(measure.unit) · \(measure.higherIsBetter ? "+" : "−")")
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text(L10n.comparisonNoMeasure)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
            }
            if let weight = criterion.weight {
                Text("\(L10n.comparisonWeight) \(format(weight))")
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
            }
            // The two things that decide whether a total exists at all, and they are
            // reachable here rather than only from a test: a criterion whose measure
            // and weight nobody can set is a criterion that can never be summed.
            FrameIconButton(systemImage: "ruler", label: L10n.comparisonMeasure) {
                editingCriterion = criterion.id
                measureDraft = criterion.measure?.unit ?? ""
                higherIsBetterDraft = criterion.measure?.higherIsBetter ?? true
                focused = true
            }
            FrameIconButton(systemImage: "scalemass", label: L10n.comparisonWeight) {
                editingCriterion = criterion.id
                measureDraft = criterion.measure?.unit ?? ""
                higherIsBetterDraft = criterion.measure?.higherIsBetter ?? true
                weightDraft = criterion.weight.map { format($0) } ?? ""
                focused = true
            }
            Button {
                _ = model.removeCriterion(criterion.id, from: id)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help(L10n.comparisonCriteria)
            .accessibilityLabel(L10n.comparisonCriteria)
        }
    }

    /// The measure and the weight, in one place, because they are one decision:
    /// whether this criterion is counted, and how much it counts.
    private func criterionEditor(_ criterion: Criterion) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.xs) {
                Text(L10n.comparisonMeasure)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
                TextField(
                    L10n.comparisonUnitPlaceholder,
                    text: Binding(get: { measureDraft }, set: { measureDraft = $0 })
                )
                .textFieldStyle(.plain)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textPrimary)
                Button {
                    higherIsBetterDraft.toggle()
                } label: {
                    Text(higherIsBetterDraft ? "+" : "−")
                        .font(TypeScale.body.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 22, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                                .fill(theme.accentSurface)
                        )
                }
                .buttonStyle(.plain)
                .help(L10n.comparisonDirectionHint)
                .accessibilityLabel(L10n.comparisonDirectionHint)
            }
            HStack(spacing: Space.xs) {
                Text(L10n.comparisonWeight)
                    .font(TypeScale.metadata)
                    .foregroundStyle(theme.textSecondary)
                TextField(
                    L10n.comparisonWeightPlaceholder,
                    text: Binding(get: { weightDraft }, set: { weightDraft = $0 })
                )
                .textFieldStyle(.plain)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textPrimary)
                Spacer(minLength: 0)
                ActionButton(title: L10n.cancel, isDefault: false) {
                    editingCriterion = nil
                }
                ActionButton(title: L10n.comparisonSave, isDefault: true) {
                    saveCriterion(criterion)
                }
            }
        }
        .padding(Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.surfaceSubtle)
        )
    }

    /// Saves both facts, and only what the person actually gave: a blank unit means
    /// "judged in words", and a blank weight means unweighted. Neither is guessed.
    private func saveCriterion(_ criterion: Criterion) {
        let unit = measureDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = model.setMeasure(
            unit.isEmpty ? nil : unit, higherIsBetter: higherIsBetterDraft,
            criterion: criterion.id, in: id
        )
        let typed = weightDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            _ = model.setWeight(nil, criterion: criterion.id, in: id)
        } else if let weight = Double(typed.replacingOccurrences(of: ",", with: ".")), weight >= 0 {
            _ = model.setWeight(weight, criterion: criterion.id, in: id)
        } else {
            // A weight that is not a number is not rounded into one.
            model.status = L10n.comparisonWeightInvalid
        }
        editingCriterion = nil
        weightDraft = ""
    }

    private func directionsBlock(_ comparison: Comparison) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            ForEach(model.comparisonRows(id)) { row in
                directionRow(row, comparison: comparison)
            }
        }
    }

    private func directionRow(_ row: ComparisonDirectionRow, comparison: Comparison) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.xs) {
                Text(row.title)
                    .font(TypeScale.body.weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let total = row.total {
                    Text(format(total))
                        .font(TypeScale.body.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .accessibilityLabel("\(L10n.comparisonWeight) \(format(total))")
                }
                ActionButton(
                    title: row.isKept ? L10n.comparisonKept : L10n.comparisonKeep,
                    isDefault: false
                ) {
                    _ = model.keepDirection(row.id, in: id)
                }
                .disabled(row.isKept)
                .help(L10n.comparisonKeepHint)
            }
            Text(L10n.comparisonCellCount(row.cellCount))
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
            // One cell per criterion, in the order the criteria were written. The
            // grid is the comparison: a direction read without it is a claim.
            ForEach(comparison.criteria) { criterion in
                cellRow(criterion, direction: row.id, comparison: comparison)
            }
        }
        .padding(Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                .fill(theme.surfaceSubtle.opacity(row.isKept ? 1 : 0.55))
        )
    }

    private func cellRow(_ criterion: Criterion, direction: ObjectID, comparison: Comparison) -> some View {
        let cell = comparison.cell(criterion: criterion.id, direction: direction)
        let isEditing = editing == Editing(criterion: criterion.id, direction: direction)
        return HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
            Text(criterion.title)
                .font(TypeScale.metadata)
                .foregroundStyle(theme.textSecondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
            if isEditing {
                TextField(
                    L10n.comparisonValuePlaceholder,
                    text: Binding(get: { cellDraft }, set: { cellDraft = $0 })
                )
                .textFieldStyle(.plain)
                .font(TypeScale.body)
                .foregroundStyle(theme.textPrimary)
                .focused($focused)
                .onSubmit { submitCell(criterion, direction: direction) }
                ActionButton(title: L10n.comparisonRecord, isDefault: true) {
                    submitCell(criterion, direction: direction)
                }
            } else {
                Text(valueLabel(cell))
                    .font(TypeScale.body)
                    .foregroundStyle(cell?.value.isRecorded == true ? theme.textPrimary : theme.attention)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let cell, cell.references.isEmpty == false {
                    Text(L10n.comparisonReferences(cell.references.count))
                        .font(TypeScale.metadata)
                        .foregroundStyle(theme.textSecondary)
                }
                if cell?.value.isRecorded == true {
                    ActionButton(title: L10n.comparisonRecordValue, isDefault: false) {
                        editing = Editing(criterion: criterion.id, direction: direction)
                        cellDraft = ""
                        focused = true
                    }
                    .font(TypeScale.metadata)
                }
            }
        }
    }

    private func valueLabel(_ cell: Cell?) -> String {
        guard let cell else { return L10n.comparisonNotRecorded }
        switch cell.value {
        case .notRecorded: return L10n.comparisonNotRecorded
        case .number(let value): return format(value)
        case .text(let value): return value
        }
    }

    // MARK: Input

    private struct Editing: Equatable {
        var criterion: CriterionID
        var direction: ObjectID
    }

    @State private var editing: Editing?
    @State private var cellDraft: String = ""
    @State private var criterionDraft: String = ""
    @State private var editingCriterion: CriterionID?
    @State private var measureDraft: String = ""
    @State private var higherIsBetterDraft = true
    @State private var weightDraft: String = ""

    /// A cell is a word or a number, and which one is decided by the criterion: a
    /// criterion with a measure takes the number if the field holds one, and a
    /// criterion without one always takes the words. A field is never asked to
    /// decide what kind of truth it is being given.
    private func submitCell(_ criterion: Criterion, direction directionID: ObjectID) {
        let typed = cellDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let value: Cell.Value
        if criterion.measure != nil, let number = Double(typed.replacingOccurrences(of: ",", with: ".")) {
            value = .number(number)
        } else if typed.isEmpty {
            value = .notRecorded
        } else {
            value = .text(typed)
        }
        _ = model.recordCell(value, criterion: criterion.id, direction: directionID, in: id)
        editing = nil
        cellDraft = ""
    }

    /// Typing a criterion adds it. It does not confirm the comparison: confirming is
    /// the button above, and a comparison that confirmed itself as soon as a word was
    /// typed would make the draft state a thing nobody ever sees.
    private func submitCriterion() {
        let typed = criterionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard typed.isEmpty == false else { return }
        if model.addCriterion(typed, to: id) {
            criterionDraft = ""
        }
    }

    /// One decimal place, and no thousands separator: a total is read at a glance,
    /// and a figure with three decimals suggests a precision nobody defined.
    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
