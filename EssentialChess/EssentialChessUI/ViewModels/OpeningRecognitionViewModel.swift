//
//  OpeningRecognitionViewModel.swift
//  EssentialChessUI
//

import Foundation
import Combine
import EssentialChess

public final class OpeningRecognitionViewModel: ObservableObject {
    @Published public private(set) var currentOpeningName: String = "Starting Position"
    @Published public private(set) var currentECO: String = ""
    
    private var detector: ECODetector
    
    public init(detector: ECODetector) {
        self.detector = detector
    }
    
    public func updateDetector(_ detector: ECODetector) {
        self.detector = detector
    }
    
    public func onMove(resultingFen: String) {
        if resultingFen.hasPrefix("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR") {
            self.currentOpeningName = "Starting Position"
            self.currentECO = ""
            return
        }
        
        if let opening = detector.detect(fen: resultingFen) {
            self.currentOpeningName = opening.name
            self.currentECO = opening.eco
        }
    }
}
