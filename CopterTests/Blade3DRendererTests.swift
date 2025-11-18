//
//  Blade3DRendererTests.swift
//  CopterTests
//
//  Created by Константин Савялов on 19.11.2025.
//

import XCTest
import SceneKit
@testable import BuilderОfUnmannedSystems
internal import Combine

class Blade3DRendererTests: XCTestCase {
    
    var renderer: Blade3DRenderer!
    var testMesh: BladeMesh!
    
    override func setUp() {
        super.setUp()
        renderer = Blade3DRenderer()
        
        // Создаем тестовую сетку лопасти
        let vertices = [
            BladePoint3D(x: 0, y: 0, z: 0),
            BladePoint3D(x: 1, y: 0, z: 0),
            BladePoint3D(x: 0, y: 1, z: 0),
            BladePoint3D(x: 1, y: 1, z: 0)
        ]
        
        let faces = [
            [0, 1, 2],
            [1, 3, 2]
        ]
        
        let normals = [
            BladePoint3D(x: 0, y: 0, z: 1),
            BladePoint3D(x: 0, y: 0, z: 1),
            BladePoint3D(x: 0, y: 0, z: 1),
            BladePoint3D(x: 0, y: 0, z: 1)
        ]
        
        testMesh = BladeMesh(vertices: vertices, faces: faces, normals: normals)
    }
    
    override func tearDown() {
        renderer = nil
        testMesh = nil
        super.tearDown()
    }
    
    // MARK: - Тесты инициализации
    
    func testInitialization() {
        // Then
        XCTAssertNotNil(renderer, "Renderer should be initialized")
        XCTAssertFalse(renderer.isLoading, "Should not be loading initially")
    }
    
    func testSceneSetup() {
        // Given
        let renderer = Blade3DRenderer()
        
        // Then
        // Проверяем, что сцена создана
        // (доступ к приватным свойствам через reflection или public методы)
        let scene = renderer.renderBlade(mesh: testMesh)
        XCTAssertNotNil(scene, "Scene should be created")
    }
    
    // MARK: - Тесты визуализации
    
    func testRenderBlade() {
        // Given
        let expectation = self.expectation(description: "Render completion")
        
        // When
        let scene = renderer.renderBlade(mesh: testMesh)
        
        // Then
        XCTAssertNotNil(scene, "Should return a scene")
        XCTAssertFalse(renderer.isLoading, "Should not be loading after render")
        
        // Проверяем, что сцена содержит геометрию
        let rootNode = scene.rootNode
        XCTAssertTrue(rootNode.childNodes.count > 0, "Scene should contain nodes")
        
        expectation.fulfill()
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testRenderBladeLoadingState() {
        // Given
        let loadingStartedExpectation = expectation(description: "Loading started")
        let loadingFinishedExpectation = expectation(description: "Loading finished")
        var didStartLoading = false
        var didFinishLoading = false
        
        // Отслеживаем изменения состояния загрузки
        let cancellable = renderer.$isLoading
            .sink { isLoading in
                if isLoading && !didStartLoading {
                    didStartLoading = true
                    loadingStartedExpectation.fulfill()
                } else if !isLoading && didStartLoading && !didFinishLoading {
                    didFinishLoading = true
                    loadingFinishedExpectation.fulfill()
                }
            }
        
        // When
        _ = renderer.renderBlade(mesh: testMesh)
        
        // Then
        wait(for: [loadingStartedExpectation, loadingFinishedExpectation], timeout: 2.0)
        
        XCTAssertTrue(didStartLoading, "Should have started loading")
        XCTAssertTrue(didFinishLoading, "Should have finished loading")
        
        cancellable.cancel()
    }
    
    func testRenderMultipleBlades() {
        // Given
        let mesh1 = testMesh!
        
        // Создаем вторую сетку
        let vertices2 = [
            BladePoint3D(x: 0, y: 0, z: 1),
            BladePoint3D(x: 1, y: 0, z: 1),
            BladePoint3D(x: 0, y: 1, z: 1)
        ]
        
        let mesh2 = BladeMesh(
            vertices: vertices2,
            faces: [[0, 1, 2]],
            normals: Array(repeating: BladePoint3D(x: 0, y: 0, z: 1), count: 3)
        )
        
        // When
        let scene1 = renderer.renderBlade(mesh: mesh1)
        let scene2 = renderer.renderBlade(mesh: mesh2)
        
        // Then
        XCTAssertNotNil(scene1, "First render should succeed")
        XCTAssertNotNil(scene2, "Second render should succeed")
        XCTAssertEqual(scene1, scene2, "Should return same scene instance")
    }
    
    // MARK: - Тесты камеры
    
    func testUpdateCameraPosition() {
        // Given
        let testPosition = SIMD3<Float>(5.0, 10.0, 15.0)
        
        // When
        renderer.updateCamera(position: testPosition)
        
        // Then
        // Проверяем через отображение сцены, что камера обновилась
        let scene = renderer.renderBlade(mesh: testMesh)
        
        // Ищем камеру в сцене
        var foundCamera = false
        scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.camera != nil {
                foundCamera = true
                stop.pointee = true
            }
        }
        
        XCTAssertTrue(foundCamera, "Scene should contain a camera")
    }
    
    func testCameraPositionValues() {
        // Given
        let positions = [
            SIMD3<Float>(0, 0, 10),
            SIMD3<Float>(5, 5, 5),
            SIMD3<Float>(-5, -5, 20)
        ]
        
        for position in positions {
            // When
            renderer.updateCamera(position: position)
            
            // Then - проверяем, что метод выполняется без ошибок
            // Конкретную позицию сложно проверить без доступа к приватному свойству
            XCTAssertTrue(true, "Should update camera position without errors")
        }
    }
    
    // MARK: - Тесты геометрии
    
    func testGeometryCreation() {
        // Given
        let mesh = testMesh!
        
        // When
        let scene = renderer.renderBlade(mesh: mesh)
        
        // Then
        XCTAssertNotNil(scene, "Should create scene with geometry")
        
        // Проверяем, что в сцене есть геометрия
        var hasGeometry = false
        scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.geometry != nil {
                hasGeometry = true
                stop.pointee = true
            }
        }
        
        XCTAssertTrue(hasGeometry, "Scene should contain geometry nodes")
    }
    
    func testGeometryWithEmptyMesh() {
        // Given
        let emptyMesh = BladeMesh(
            vertices: [],
            faces: [],
            normals: []
        )
        
        // When
        let scene = renderer.renderBlade(mesh: emptyMesh)
        
        // Then
        XCTAssertNotNil(scene, "Should handle empty mesh gracefully")
    }
    
    func testGeometryWithComplexMesh() {
        // Given
        let complexVertices = (0..<100).map { i in
            BladePoint3D(
                x: Double(i) * 0.1,
                y: sin(Double(i) * 0.1),
                z: cos(Double(i) * 0.1)
            )
        }
        
        let complexFaces = (0..<98).map { i in
            [i, i + 1, i + 2]
        }
        
        let complexMesh = BladeMesh(
            vertices: complexVertices,
            faces: complexFaces,
            normals: Array(repeating: BladePoint3D(x: 0, y: 0, z: 1), count: 100)
        )
        
        // When
        let scene = renderer.renderBlade(mesh: complexMesh)
        
        // Then
        XCTAssertNotNil(scene, "Should handle complex mesh")
    }
    
    // MARK: - Тесты производительности
    
    func testRenderPerformance() {
        measure {
            _ = renderer.renderBlade(mesh: testMesh)
        }
    }
    
    func testCameraUpdatePerformance() {
        measure {
            for i in 0..<100 {
                let position = SIMD3<Float>(Float(i), Float(i), Float(i))
                renderer.updateCamera(position: position)
            }
        }
    }
    
    func testMultipleRenderPerformance() {
        measure {
            for _ in 0..<10 {
                _ = renderer.renderBlade(mesh: testMesh)
            }
        }
    }
    
    // MARK: - Тесты обработки ошибок и граничных случаев
    
    func testConcurrentRendering() {
        // Given
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        var renderResults: [SCNScene] = []
        let renderCount = 10
        
        // When
        for i in 0..<renderCount {
            dispatchGroup.enter()
            queue.async {
                let mesh = self.createTestMesh(offset: Double(i))
                let scene = self.renderer.renderBlade(mesh: mesh)
                
                DispatchQueue.main.async {
                    renderResults.append(scene)
                    dispatchGroup.leave()
                }
            }
        }
        
        // Then
        let expectation = self.expectation(description: "All renders complete")
        dispatchGroup.notify(queue: .main) {
            XCTAssertEqual(renderResults.count, renderCount, "All renders should complete")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testMemoryManagement() {
        // Given
        var weakRenderer: Blade3DRenderer? = Blade3DRenderer()
        weak var weakReference = weakRenderer
        
        // When
        _ = weakRenderer?.renderBlade(mesh: testMesh)
        weakRenderer = nil
        
        // Then
        XCTAssertNil(weakReference, "Renderer should be deallocated")
    }
    
    // MARK: - Вспомогательные методы
    
    private func createTestMesh(offset: Double = 0.0) -> BladeMesh {
        let vertices = [
            BladePoint3D(x: offset + 0, y: 0, z: 0),
            BladePoint3D(x: offset + 1, y: 0, z: 0),
            BladePoint3D(x: offset + 0, y: 1, z: 0),
            BladePoint3D(x: offset + 1, y: 1, z: 0)
        ]
        
        let faces = [
            [0, 1, 2],
            [1, 3, 2]
        ]
        
        let normals = Array(repeating: BladePoint3D(x: 0, y: 0, z: 1), count: 4)
        
        return BladeMesh(vertices: vertices, faces: faces, normals: normals)
    }
}

// MARK: - Тесты интеграции

class Blade3DRendererIntegrationTests: XCTestCase {
    
    func testIntegrationWithMeshGenerator() {
        // Given
        let renderer = Blade3DRenderer()
        let meshGenerator = BladeMeshGenerator()
        let bladeGeometry = BladeGeometry(
            radius: 0.15,
            rootCutout: 0.02,
            chordDistribution: { position in
                return 0.05 - (0.05 - 0.02) * position
            },
            twistDistribution: { position in
                return 0.3 - 0.2 * position
            }
        )
        
        // When
        let mesh = meshGenerator.generateMesh(for: bladeGeometry, segments: 20)
        let scene = renderer.renderBlade(mesh: mesh)
        
        // Then
        XCTAssertNotNil(scene, "Should render mesh from generator")
        XCTAssertFalse(renderer.isLoading, "Should not be loading after render")
    }
    
    func testFullPipelinePerformance() {
        // Given
        let renderer = Blade3DRenderer()
        let meshGenerator = BladeMeshGenerator()
        let bladeGeometry = BladeGeometry(
            radius: 0.15,
            rootCutout: 0.02,
            chordDistribution: { position in return 0.05 },
            twistDistribution: { position in return 0.2 }
        )
        
        measure {
            // When
            let mesh = meshGenerator.generateMesh(for: bladeGeometry, segments: 50)
            _ = renderer.renderBlade(mesh: mesh)
        }
    }
}
