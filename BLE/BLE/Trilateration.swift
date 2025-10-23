// Trilateration.swift
import Foundation
import simd

/// Trilateration solver for three 2D points with distances
/// Returns optional (x, y) in same coordinate system (meters)solver for three 2D points with distances.
/// Returns optional (x, y) in same coordinate system (meters)
func trilaterate(p1: SIMD2<Double>, r1: Double,
                 p2: SIMD2<Double>, r2: Double,
                 p3: SIMD2<Double>, r3: Double) -> SIMD2<Double>? {
    let x1 = p1.x, y1 = p1.y
    let x2 = p2.x, y2 = p2.y
    let x3 = p3.x, y3 = p3.y

    let A = 2*(x2 - x1)
    let B = 2*(y2 - y1)
    let C = r1*r1 - r2*r2 - x1*x1 + x2*x2 - y1*y1 + y2*y2
    let D = 2*(x3 - x2)
    let E = 2*(y3 - y2)
    let F = r2*r2 - r3*r3 - x2*x2 + x3*x3 - y2*y2 + y3*y3

    let denom = A*E - B*D
    if abs(denom) < 1e-8 {
        // Degenerate or nearly colinear; can't solve reliably
        return nil
    }

    let x = (C*E - B*F) / denom
    let y = (A*F - C*D) / denom
    return SIMD2<Double>(x, y)
}
