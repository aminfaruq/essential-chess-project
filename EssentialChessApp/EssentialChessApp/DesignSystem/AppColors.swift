//
//  AppColors.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//
import SwiftUI

public enum AppColors {
    public static let background  = Color(red: 0.09, green: 0.09, blue: 0.11)
    public static let surface     = Color(red: 0.14, green: 0.14, blue: 0.18)
    public static let surfaceHigh = Color(red: 0.19, green: 0.19, blue: 0.24)
    public static let accent      = Color(red: 0.51, green: 0.72, blue: 0.30)  // lichess green
    public static let gold        = Color(red: 0.95, green: 0.78, blue: 0.25)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let boardLight  = Color(red: 0.94, green: 0.93, blue: 0.82)  // #EEEED2
    public static let boardDark   = Color(red: 0.46, green: 0.59, blue: 0.34)  // #769656
    public static let correct     = Color(red: 0.25, green: 0.78, blue: 0.45)
    public static let incorrect   = Color(red: 0.92, green: 0.27, blue: 0.27)
    public static let hint        = Color(red: 0.95, green: 0.78, blue: 0.25).opacity(0.7)
    public static let locked      = Color(white: 0.4)
    public static let red         = Color(red: 0.92, green: 0.34, blue: 0.34)
}
