//
//  Blade3DRenderer.swift
//  Calculator
//
//  Created by Константин Савялов on 18.11.2025.
//

import Foundation
import SceneKit
import SwiftUI
import Combine

/// # 3D Визуализатор лопасти
/// Управляет 3D визуализацией лопастей пропеллера с использованием SceneKit
/// Обеспечивает высококачественную визуализацию с реалистичными материалами и освещением
public class Blade3DRenderer: NSObject, ObservableObject {
    
    // MARK: - Публичные свойства
    
    /// ## Статус загрузки
    /// Указывает, обрабатывает ли в данный момент визуализатор геометрию
    /// Используется для отображения индикаторов загрузки в пользовательском интерфейсе
    @Published public var isLoading = false
    
    // MARK: - Приватные свойства
    
    /// ## Сцена SceneKit
    /// Корневая сцена, содержащая все 3D объекты и освещение
    /// Управляет 3D окружением и конвейером визуализации
    private var scene: SCNScene
    
    /// ## Узел камеры
    /// Камера SceneKit для просмотра 3D сцены
    /// Управляет точкой обзора и параметрами проекции
    private var cameraNode: SCNNode
    
    /// ## Узел лопасти
    /// Узел SceneKit, содержащий геометрию лопасти
    /// Родительский узел для всех визуальных компонентов лопасти
    private var bladeNode: SCNNode?
    
    // MARK: - Инициализация
    
    /// ## Инициализатор 3D визуализатора
    /// Настраивает сцену SceneKit с освещением и камерой по умолчанию
    public override init() {
        self.scene = SCNScene()
        self.cameraNode = SCNNode()
        super.init()
        setupScene()
    }
    
    // MARK: - Публичные методы
    
    /// ## Визуализировать сетку лопасти
    /// Преобразует сетку лопасти в геометрию SceneKit и добавляет в сцену
    /// Применяет материалы и настраивает для высококачественной визуализации
    /// - Parameter mesh: Сетка лопасти для визуализации
    /// - Returns: Настроенная сцена SceneKit, готовая к отображению
    public func renderBlade(mesh: BladeMesh) -> SCNScene {
        isLoading = true
        
        // Удаляем предыдущую геометрию лопасти
        bladeNode?.removeFromParentNode()
        
        // Создаем новую геометрию лопасти из сетки
        let bladeGeometry = createGeometry(from: mesh)
        bladeNode = SCNNode(geometry: bladeGeometry)
        
        // Применяем реалистичные свойства материала
        let material = SCNMaterial()
        material.diffuse.contents = NSColor.systemBlue
        material.specular.contents = NSColor.white
        material.shininess = 0.8
        material.transparency = 0.9
        bladeGeometry.materials = [material]
        
        // Добавляем лопасть в сцену
        scene.rootNode.addChildNode(bladeNode!)
        
        isLoading = false
        return scene
    }
    
    /// ## Обновить позицию камеры
    /// Перемещает камеру в новую позицию в 3D пространстве
    /// - Parameter position: Новая позиция камеры как SIMD3<Float>
    public func updateCamera(position: SIMD3<Float>) {
        cameraNode.position = SCNVector3(position.x, position.y, position.z)
    }
    
    // MARK: - Приватные методы
    
    /// ## Настроить окружение сцены
    /// Настраивает освещение по умолчанию, камеру и свойства сцены
    /// Создает профессиональную среду визуализации
    private func setupScene() {
        // Настраиваем камеру с позицией по умолчанию
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Добавляем окружающий свет для базового освещения
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = NSColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Добавляем направленный свет для бликов и теней
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .directional
        directionalLight.light!.color = NSColor(white: 0.8, alpha: 1.0)
        directionalLight.position = SCNVector3(10, 10, 10)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)
    }
    
    /// ## Создать геометрию SceneKit
    /// Преобразует пользовательскую сетку лопасти в формат геометрии SceneKit
    /// - Parameter mesh: Исходные данные сетки лопасти
    /// - Returns: Геометрия SceneKit, готовая к визуализации
    private func createGeometry(from mesh: BladeMesh) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        // Преобразуем пользовательские вершины в формат SceneKit
        for vertex in mesh.vertices {
            vertices.append(SCNVector3(vertex.x, vertex.y, vertex.z))
        }
        
        // Преобразуем грани в индексы треугольников
        for face in mesh.faces {
            for vertexIndex in face {
                indices.append(Int32(vertexIndex))
            }
        }
        
        // Создаем источники геометрии SceneKit
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
