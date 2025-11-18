//
//  BladeMeshGenerator.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation

/// # Генератор сетки лопасти
/// Создает 3D представления сеток из определений геометрии лопасти
/// Генерирует вершины, грани и нормали для визуализации и экспорта
public class BladeMeshGenerator {
    
    /// ## Сгенерировать сетку лопасти
    /// Создает полную 3D сетку из геометрии лопасти
    /// - Parameters:
    ///   - geometry: Определение геометрии лопасти
    ///   - segments: Количество радиальных сегментов (больше = больше деталей)
    /// - Returns: Полная сетка лопасти с вершинами и гранями
    public func generateMesh(for geometry: BladeGeometry, segments: Int) -> BladeMesh {
        var vertices: [BladePoint3D] = []
        var faces: [[Int]] = []
        var normals: [BladePoint3D] = []
        
        let radialSegments = segments
        let chordSegments = 20
        
        // Генерируем вершины
        for i in 0...radialSegments {
            let r = geometry.rootCutout + (geometry.radius - geometry.rootCutout) * Double(i) / Double(radialSegments)
            let chord = geometry.getChord(at: r / geometry.radius)
            let twist = geometry.getTwist(at: r / geometry.radius)
            
            for j in 0...chordSegments {
                let chordPos = Double(j) / Double(chordSegments) - 0.5 // от -0.5 до 0.5
                let x = r
                let y = chordPos * chord * cos(twist)
                let z = chordPos * chord * sin(twist)
                
                vertices.append(BladePoint3D(x: x, y: y, z: z))
            }
        }
        
        // Генерируем грани
        for i in 0..<radialSegments {
            for j in 0..<chordSegments {
                let v0 = i * (chordSegments + 1) + j
                let v1 = v0 + 1
                let v2 = v0 + (chordSegments + 1)
                let v3 = v2 + 1
                
                // Два треугольника на четырехугольник
                faces.append([v0, v1, v2])
                faces.append([v1, v3, v2])
            }
        }
        
        // Вычисляем нормали (упрощенно - все направлены вверх)
        for _ in vertices {
            normals.append(BladePoint3D(x: 0, y: 0, z: 1))
        }
        
        return BladeMesh(vertices: vertices, faces: faces, normals: normals)
    }
}
