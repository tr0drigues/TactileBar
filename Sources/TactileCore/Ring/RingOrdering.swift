import Foundation

/// Decide qual switch fixado ocupa cada posição do anel.
/// Regra: mais usado nas melhores posições, mas sem embaralhar durante o uso.
public enum RingOrdering {
    /// Pins do mais usado para o menos usado; empate pela ordem em que foram fixados.
    public static func rankedByUsage(pinnedOrder: [String], usageCounts: [String: Int]) -> [String] {
        pinnedOrder.enumerated()
            .sorted { lhs, rhs in
                let lhsCount = usageCounts[lhs.element, default: 0]
                let rhsCount = usageCounts[rhs.element, default: 0]
                if lhsCount != rhsCount {
                    return lhsCount > rhsCount
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Distribui uma lista já ordenada pelas posições, por rank.
    public static func layout(ranked: [String], slotCount: Int = RingGeometry.slotCount) -> [String?] {
        var slots = [String?](repeating: nil, count: slotCount)
        for (rank, id) in ranked.prefix(slotCount).enumerated() {
            slots[rank] = id
        }
        return slots
    }

    /// Ajuste mínimo após mudança nos pins: quem saiu libera a posição,
    /// quem entrou ocupa as primeiras posições livres. Os demais não se movem.
    public static func reconcile(
        slots: [String?],
        pinnedOrder: [String],
        usageCounts: [String: Int],
        slotCount: Int = RingGeometry.slotCount
    ) -> [String?] {
        let pinned = Set(pinnedOrder)
        var result = [String?](repeating: nil, count: slotCount)
        var placed = Set<String>()

        for (rank, id) in slots.prefix(slotCount).enumerated() {
            if let id, pinned.contains(id), !placed.contains(id) {
                result[rank] = id
                placed.insert(id)
            }
        }

        var newcomers = rankedByUsage(
            pinnedOrder: pinnedOrder.filter { !placed.contains($0) },
            usageCounts: usageCounts
        )[...]
        for rank in result.indices where result[rank] == nil {
            guard let next = newcomers.popFirst() else { break }
            result[rank] = next
        }
        return result
    }

    /// Quantos pins ficaram fora do anel por falta de posição.
    public static func overflowCount(slots: [String?], pinnedOrder: [String]) -> Int {
        let placed = Set(slots.compactMap { $0 })
        return Set(pinnedOrder).subtracting(placed).count
    }
}
