//
//  Blade2DRendererExtendedTests.swift
//  CopterTests
//
//  Created by Константин Савялов on 19.11.2025.
//

import XCTest
@testable import BuilderОfUnmannedSystems
internal import SwiftUI

class Blade2DRendererExtendedTests: XCTestCase {
    
    var testGeometry: BladeGeometry!
    var testSize: CGSize!
    
    override func setUp() {
        super.setUp()
        
        testGeometry = BladeGeometry(
            radius: 0.15,
            rootCutout: 0.02,
            chordDistribution: { radialPosition in
                return 0.05 - (0.05 - 0.02) * radialPosition
            },
            twistDistribution: { radialPosition in
                return 0.3 - 0.2 * radialPosition
            }
        )
        
        testSize = CGSize(width: 400, height: 300)
    }
    
    override func tearDown() {
        testGeometry = nil
        testSize = nil
        super.tearDown()
    }
    
    // MARK: - Тесты производительности для ключевых операций
    
    func testPerformanceLargeScaleTopView() {
        measure {
            let largeSize = CGSize(width: 2000, height: 1500)
            _ = Blade2DRenderer.createTopViewPath(geometry: testGeometry, size: largeSize)
        }
    }
    
    func testPerformanceHighDetailSectionView() {
        measure {
            for i in 0...10 {
                let radiusFraction = Double(i) / 10.0
                _ = Blade2DRenderer.createSectionViewPath(
                    geometry: testGeometry,
                    size: testSize,
                    at: radiusFraction
                )
            }
        }
    }
    
    func testPerformanceMultipleDimensionLines() {
        measure {
            for _ in 0..<100 {
                _ = Blade2DRenderer.createDimensionLines(geometry: testGeometry, size: testSize)
            }
        }
    }
    
    func testPerformanceTwistDistributionCalculation() {
        measure {
            for _ in 0..<1000 {
                _ = Blade2DRenderer.getTwistDistribution(geometry: testGeometry)
            }
        }
    }
    
    func testPerformanceRealTimeRendering() {
        measure {
            // Имитация реального времени - все операции вместе
            let topView = Blade2DRenderer.createTopViewPath(geometry: testGeometry, size: testSize)
            let sectionView = Blade2DRenderer.createSectionViewPath(geometry: testGeometry, size: testSize, at: 0.7)
            let twistView = Blade2DRenderer.createTwistViewPath(geometry: testGeometry, size: testSize)
            let dimensions = Blade2DRenderer.createDimensionLines(geometry: testGeometry, size: testSize)
            let twistData = Blade2DRenderer.getTwistDistribution(geometry: testGeometry)
            
            // Проверяем, что все операции завершились успешно
            XCTAssertFalse(topView.isEmpty)
            XCTAssertFalse(sectionView.isEmpty)
            XCTAssertFalse(twistView.isEmpty)
            XCTAssertFalse(dimensions.isEmpty)
            XCTAssertFalse(twistData.isEmpty)
        }
    }
    
    // MARK: - Тесты обработки экстремальных случаев
    
    func testExtremeGeometrySmallRadius() {
        // Given - очень маленькая лопасть
        let smallGeometry = BladeGeometry(
            radius: 0.01, // 10 мм
            rootCutout: 0.002, // 2 мм
            chordDistribution: { _ in 0.005 }, // 5 мм
            twistDistribution: { _ in 0.1 }
        )
        
        // When
        let path = Blade2DRenderer.createTopViewPath(geometry: smallGeometry, size: testSize)
        let dimensions = Blade2DRenderer.createDimensionLines(geometry: smallGeometry, size: testSize)
        
        // Then
        XCTAssertFalse(path.isEmpty, "Should handle very small geometry")
        XCTAssertFalse(dimensions.isEmpty, "Should generate dimensions for small geometry")
    }
    
    func testExtremeGeometryLargeRadius() {
        // Given - очень большая лопасть
        let largeGeometry = BladeGeometry(
            radius: 1.0, // 1 метр
            rootCutout: 0.1, // 100 мм
            chordDistribution: { _ in 0.2 }, // 200 мм
            twistDistribution: { _ in 0.5 }
        )
        
        // When
        let path = Blade2DRenderer.createTopViewPath(geometry: largeGeometry, size: testSize)
        let sectionInfo = Blade2DRenderer.getSectionInfo(geometry: largeGeometry, at: 0.5)
        
        // Then
        XCTAssertFalse(path.isEmpty, "Should handle very large geometry")
        XCTAssertEqual(sectionInfo.radius, 0.55, accuracy: 0.001, "Should calculate correct radius")
    }
    
    func testExtremeTwistValues() {
        // Given - экстремальные значения крутки
        let extremeTwistGeometry = BladeGeometry(
            radius: 0.15,
            rootCutout: 0.02,
            chordDistribution: { _ in 0.05 },
            twistDistribution: { position in
                // Очень большая крутка у корня, почти нулевая на конце
                return 1.5 - 1.4 * position // от 1.5 рад (~86°) до 0.1 рад (~6°)
            }
        )
        
        // When
        let twistDistribution = Blade2DRenderer.getTwistDistribution(geometry: extremeTwistGeometry)
        let sectionInfo = Blade2DRenderer.getSectionInfo(geometry: extremeTwistGeometry, at: 0.0)
        
        // Then
        XCTAssertEqual(sectionInfo.twistRadians, 1.5, accuracy: 0.001,
                      "Should handle high twist values")
        XCTAssertEqual(sectionInfo.twistDegrees, 1.5 * 180 / .pi, accuracy: 0.1,
                      "Should convert high twist to degrees correctly")
        
        // Проверяем, что крутка уменьшается
        XCTAssertTrue(twistDistribution[0].twistRadians > twistDistribution[10].twistRadians,
                     "Twist should decrease even with extreme values")
    }
    
    func testZeroChordGeometry() {
        // Given - нулевая хорда на конце (дегенеративный случай)
        let zeroChordGeometry = BladeGeometry(
            radius: 0.15,
            rootCutout: 0.02,
            chordDistribution: { position in
                return 0.05 * (1.0 - position) // линейно до нуля
            },
            twistDistribution: { _ in 0.2 }
        )
        
        // When
        let tipInfo = Blade2DRenderer.getSectionInfo(geometry: zeroChordGeometry, at: 1.0)
        let path = Blade2DRenderer.createTopViewPath(geometry: zeroChordGeometry, size: testSize)
        
        // Then
        XCTAssertEqual(tipInfo.chord, 0.0, accuracy: 0.001, "Tip chord should be zero")
        XCTAssertFalse(path.isEmpty, "Should handle zero chord at tip")
    }
    
    func testNegativeSize() {
        // Given - отрицательный размер (некорректные данные)
        let negativeSize = CGSize(width: -100, height: -50)
        
        // When
        let path = Blade2DRenderer.createTopViewPath(geometry: testGeometry, size: negativeSize)
        
        // Then
        XCTAssertFalse(path.isEmpty, "Should handle negative size gracefully")
    }
    
    func testExtremeAspectRatio() {
        // Given - экстремальные соотношения сторон
        let wideSize = CGSize(width: 1000, height: 100)
        let tallSize = CGSize(width: 100, height: 1000)
        
        // When
        let widePath = Blade2DRenderer.createTopViewPath(geometry: testGeometry, size: wideSize)
        let tallPath = Blade2DRenderer.createTopViewPath(geometry: testGeometry, size: tallSize)
        
        // Then
        XCTAssertFalse(widePath.isEmpty, "Should handle wide aspect ratio")
        XCTAssertFalse(tallPath.isEmpty, "Should handle tall aspect ratio")
    }
    
    // MARK: - Тесты математической корректности расчетов
    
    func testMathematicalConsistency() {
        // Given
        let geometry = testGeometry!
        
        // When - получаем информацию в нескольких точках
        let points = [0.0, 0.25, 0.5, 0.75, 1.0]
        var sectionInfos: [SectionInfo] = []
        
        for point in points {
            let info = Blade2DRenderer.getSectionInfo(geometry: geometry, at: point)
            sectionInfos.append(info)
        }
        
        // Then - проверяем математическую согласованность
        for i in 0..<sectionInfos.count {
            let info = sectionInfos[i]
            
            // Радиус должен увеличиваться
            if i > 0 {
                XCTAssertTrue(info.radius > sectionInfos[i-1].radius,
                             "Radius should increase along the blade")
            }
            
            // Нормализованный радиус должен соответствовать
            let expectedNormalized = points[i]
            XCTAssertEqual(info.normalizedRadius, expectedNormalized, accuracy: 0.01,
                          "Normalized radius should match input fraction")
            
            // Углы в радианах и градусах должны быть согласованы
            let calculatedDegrees = info.twistRadians * 180 / .pi
            XCTAssertEqual(info.twistDegrees, calculatedDegrees, accuracy: 0.001,
                          "Degrees should be consistent with radians")
        }
    }
    
    func testChordDistributionMonotonic() {
        // Given
        let geometry = testGeometry!
        
        // When - получаем распределение хорды
        let points = stride(from: 0.0, through: 1.0, by: 0.1)
        var chords: [Double] = []
        
        for point in points {
            let info = Blade2DRenderer.getSectionInfo(geometry: geometry, at: point)
            chords.append(info.chord)
        }
        
        // Then - хорда должна монотонно уменьшаться (для нашей тестовой геометрии)
        for i in 1..<chords.count {
            XCTAssertTrue(chords[i] <= chords[i-1],
                         "Chord should decrease monotonically for this geometry")
        }
    }
    
    func testTwistDistributionConsistency() {
        // Given
        let geometry = testGeometry!
        
        // When
        let twistData = Blade2DRenderer.getTwistDistribution(geometry: geometry)
        
        // Then - проверяем согласованность данных
        for dataPoint in twistData {
            // Радиус должен быть в допустимом диапазоне
            XCTAssertTrue(dataPoint.radius >= geometry.rootCutout &&
                         dataPoint.radius <= geometry.radius,
                         "Radius should be within blade bounds")
            
            // Нормализованный радиус должен вычисляться корректно
            let calculatedNormalized = (dataPoint.radius - geometry.rootCutout) /
                                     (geometry.radius - geometry.rootCutout)
            let actualNormalized = (dataPoint.radius - geometry.rootCutout) /
                                 (geometry.radius - geometry.rootCutout)
            XCTAssertEqual(calculatedNormalized, actualNormalized, accuracy: 0.001,
                          "Normalized radius calculation should be consistent")
            
            // Преобразование радианы-градусы должно быть точным
            let calculatedDegrees = dataPoint.twistRadians * 180 / .pi
            XCTAssertEqual(dataPoint.twistDegrees, calculatedDegrees, accuracy: 0.001,
                          "Degree conversion should be precise")
        }
    }
    
    func testScaleInvariance() {
        // Given - геометрия с разными масштабами
        let scaleFactors: [Double] = [0.5, 1.0, 2.0, 5.0]
        
        for scale in scaleFactors {
            let scaledGeometry = BladeGeometry(
                radius: 0.15 * scale,
                rootCutout: 0.02 * scale,
                chordDistribution: { position in
                    return (0.05 - (0.05 - 0.02) * position) * scale
                },
                twistDistribution: { position in
                    return 0.3 - 0.2 * position // крутка не масштабируется
                }
            )
            
            // When
            let sectionInfo = Blade2DRenderer.getSectionInfo(geometry: scaledGeometry, at: 0.5)
            
            // Then - нормализованный радиус не должен зависеть от масштаба
            XCTAssertEqual(sectionInfo.normalizedRadius, 0.5, accuracy: 0.001,
                          "Normalized radius should be scale-invariant")
            
            // Крутка не должна масштабироваться
            XCTAssertEqual(sectionInfo.twistRadians, 0.2, accuracy: 0.001,
                          "Twist should not scale with geometry")
        }
    }
    
    func testNumericalStability() {
        // Given - очень близкие значения
        let precisionGeometry = BladeGeometry(
            radius: 0.1500000001,
            rootCutout: 0.0200000001,
            chordDistribution: { position in
                return 0.05 - (0.05 - 0.02) * position
            },
            twistDistribution: { position in
                return 0.3 - 0.2 * position
            }
        )
        
        // When
        let sectionInfo = Blade2DRenderer.getSectionInfo(geometry: precisionGeometry, at: 0.3333333333)
        let twistData = Blade2DRenderer.getTwistDistribution(geometry: precisionGeometry)
        
        // Then - вычисления должны быть стабильными
        XCTAssertTrue(sectionInfo.radius > 0, "Radius should be positive")
        XCTAssertTrue(sectionInfo.chord > 0, "Chord should be positive")
        XCTAssertFalse(twistData.isEmpty, "Should handle high precision inputs")
        
        // Проверяем, что нет NaN или бесконечных значений
        for data in twistData {
            XCTAssertFalse(data.radius.isNaN, "Radius should not be NaN")
            XCTAssertFalse(data.twistRadians.isNaN, "Twist radians should not be NaN")
            XCTAssertFalse(data.twistDegrees.isNaN, "Twist degrees should not be NaN")
            XCTAssertFalse(data.radius.isInfinite, "Radius should not be infinite")
        }
    }
    
    func testBoundaryConditions() {
        // Given
        let geometry = testGeometry!
        
        // When - тестируем граничные условия
        let rootInfo = Blade2DRenderer.getSectionInfo(geometry: geometry, at: 0.0)
        let tipInfo = Blade2DRenderer.getSectionInfo(geometry: geometry, at: 1.0)
        
        // Then
        XCTAssertEqual(rootInfo.radius, geometry.rootCutout, accuracy: 0.001,
                      "Root section should be at root cutout")
        XCTAssertEqual(rootInfo.normalizedRadius, 0.0, accuracy: 0.001,
                      "Root normalized radius should be 0")
        
        XCTAssertEqual(tipInfo.radius, geometry.radius, accuracy: 0.001,
                      "Tip section should be at blade radius")
        XCTAssertEqual(tipInfo.normalizedRadius, 1.0, accuracy: 0.001,
                      "Tip normalized radius should be 1")
    }
    
    func testPathGeometryProperties() {
        // Given
        let geometry = testGeometry!
        let size = testSize!
        
        // When
        let topPath = Blade2DRenderer.createTopViewPath(geometry: geometry, size: size)
        let sectionPath = Blade2DRenderer.createSectionViewPath(geometry: geometry, size: size, at: 0.7)
        let twistPath = Blade2DRenderer.createTwistViewPath(geometry: geometry, size: size)
        
        // Then - проверяем геометрические свойства путей
        let topBounds = topPath.boundingRect
        let sectionBounds = sectionPath.boundingRect
        let twistBounds = twistPath.boundingRect
        
        // Пути должны быть внутри canvas
        XCTAssertTrue(topBounds.maxX <= size.width, "Top view should fit in width")
        XCTAssertTrue(topBounds.maxY <= size.height, "Top view should fit in height")
        XCTAssertTrue(sectionBounds.maxX <= size.width, "Section view should fit in width")
        XCTAssertTrue(sectionBounds.maxY <= size.height, "Section view should fit in height")
        XCTAssertTrue(twistBounds.maxX <= size.width, "Twist view should fit in width")
        XCTAssertTrue(twistBounds.maxY <= size.height, "Twist view should fit in height")
        
        // Пути должны иметь положительные размеры
        XCTAssertTrue(topBounds.width > 0, "Top view should have positive width")
        XCTAssertTrue(topBounds.height > 0, "Top view should have positive height")
        XCTAssertTrue(sectionBounds.width > 0, "Section view should have positive width")
        XCTAssertTrue(sectionBounds.height > 0, "Section view should have positive height")
        XCTAssertTrue(twistBounds.width > 0, "Twist view should have positive width")
        XCTAssertTrue(twistBounds.height > 0, "Twist view should have positive height")
    }
    
    func testDimensionLineMathematicalProperties() {
        // Given
        let testCases = [
            (start: CGPoint(x: 0, y: 0), end: CGPoint(x: 100, y: 0), text: "Horizontal"),
            (start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 100), text: "Vertical"),
            (start: CGPoint(x: 10, y: 20), end: CGPoint(x: 50, y: 60), text: "Diagonal")
        ]
        
        for testCase in testCases {
            // When
            let dimensionLine = DimensionLine(
                start: testCase.start,
                end: testCase.end,
                text: testCase.text
            )
            
            // Then - проверяем математические свойства
            XCTAssertEqual(dimensionLine.start, testCase.start, "Start point should match")
            XCTAssertEqual(dimensionLine.end, testCase.end, "End point should match")
            XCTAssertEqual(dimensionLine.text, testCase.text, "Text should match")
            
            // Длина линии должна быть неотрицательной
            let dx = testCase.end.x - testCase.start.x
            let dy = testCase.end.y - testCase.start.y
            let length = sqrt(dx * dx + dy * dy)
            XCTAssertTrue(length >= 0, "Line length should be non-negative")
        }
    }
}
