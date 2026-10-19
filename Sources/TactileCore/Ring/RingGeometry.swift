import Foundation

/// Geometria pura do anel radial: 8 posições fixas, cardeais primeiro.
public enum RingGeometry {
    public static let slotCount = 8

    /// Ângulo central de cada posição, indexado pelo rank (0 = mais usado).
    /// Graus em coordenadas de tela (y para baixo): -90 = topo, 0 = direita.
    public static let slotAngles: [Double] = [-90, 0, 90, 180, -45, 45, 135, -135]

    public static let slotSpan: Double = 360.0 / Double(slotCount)

    /// Ranks na ordem visual horária, começando pelo topo.
    public static let clockwiseOrder: [Int] = [0, 4, 1, 5, 2, 6, 3, 7]

    /// Rank da posição apontada pelo vetor (dx, dy) a partir do centro, ou nil dentro da zona morta.
    public static func slot(dx: Double, dy: Double, deadZoneRadius: Double) -> Int? {
        guard (dx * dx + dy * dy).squareRoot() > deadZoneRadius else { return nil }
        let angle = atan2(dy, dx) * 180.0 / Double.pi
        var nearest = 0
        var nearestDistance = Double.greatestFiniteMagnitude
        for (rank, slotAngle) in slotAngles.enumerated() {
            let distance = angularDistance(angle, slotAngle)
            if distance < nearestDistance {
                nearest = rank
                nearestDistance = distance
            }
        }
        return nearest
    }

    public static func angularDistance(_ a: Double, _ b: Double) -> Double {
        var delta = (a - b).truncatingRemainder(dividingBy: 360.0)
        if delta < 0 {
            delta += 360.0
        }
        return min(delta, 360.0 - delta)
    }

    // MARK: - Leque de escolhas

    /// Largura angular de cada escolha no leque que abre por fora da fatia.
    public static let choiceSpan: Double = 21

    /// Teclas 1–8 limitam o leque a oito escolhas.
    public static let maxChoices = 8

    /// Ângulo central de cada escolha, centrado no ângulo da fatia. Índice crescente = sentido horário.
    public static func choiceAngles(count: Int, aroundSlot rank: Int) -> [Double] {
        guard count > 0 else { return [] }
        let center = slotAngles[rank]
        let first = center - Double(count - 1) * choiceSpan / 2
        return (0..<count).map { first + Double($0) * choiceSpan }
    }

    /// Escolha apontada pelo vetor, ou nil fora do leque. Só o ângulo importa; a distância é do chamador.
    public static func choice(dx: Double, dy: Double, count: Int, aroundSlot rank: Int) -> Int? {
        guard count > 0 else { return nil }
        let angle = atan2(dy, dx) * 180.0 / Double.pi
        let angles = choiceAngles(count: count, aroundSlot: rank)
        var nearest: Int?
        var nearestDistance = choiceSpan / 2
        for (index, choiceAngle) in angles.enumerated() {
            let distance = angularDistance(angle, choiceAngle)
            if distance <= nearestDistance {
                nearest = index
                nearestDistance = distance
            }
        }
        return nearest
    }

    /// Deslocamento a partir do centro para o ponto em um ângulo qualquer.
    public static func offset(angle degrees: Double, radius: Double) -> (dx: Double, dy: Double) {
        let radians = degrees * Double.pi / 180.0
        return (cos(radians) * radius, sin(radians) * radius)
    }

    /// Deslocamento a partir do centro para o ponto da posição no raio informado.
    public static func offset(forSlot rank: Int, radius: Double) -> (dx: Double, dy: Double) {
        let radians = slotAngles[rank] * Double.pi / 180.0
        return (cos(radians) * radius, sin(radians) * radius)
    }
}
