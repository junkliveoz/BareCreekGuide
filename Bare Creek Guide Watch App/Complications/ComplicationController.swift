//
//  ComplicationController.swift
//  Bare Creek Guide
//
//  Created by Adam on 7/4/2025.
//  Updated to use modern complication initializers for watchOS 7+
//

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Timeline Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "bareCreekStatus",
                displayName: "Bare Creek Status",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicBezel,
                    .graphicExtraLarge
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Our data refreshes more frequently than the system would refresh complications
        // Return a date 1 hour in the future
        handler(Date().addingTimeInterval(3600))
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // No private data in our complications
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the current weather data from UserDefaults (cached by WatchViewModel)
        let userDefaults = UserDefaults.standard
        let parkStatus = userDefaults.string(forKey: "parkStatus") ?? "Unknown"
        let windSpeed = userDefaults.string(forKey: "windSpeed") ?? "--"
        let colorString = userDefaults.string(forKey: "statusColor") ?? "gray"
        
        // Create a template based on the complication family
        let template = createTemplate(for: complication.family, status: parkStatus, wind: windSpeed, colorString: colorString)
        
        // Create the timeline entry
        if let template = template {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Template Creation
    
    func createTemplate(for family: CLKComplicationFamily, status: String, wind: String, colorString: String) -> CLKComplicationTemplate? {
        let color = self.colorFromString(colorString)
        let bcTextProvider = CLKSimpleTextProvider(text: "BC")
        let windTextProvider = CLKSimpleTextProvider(text: wind)
        let windWithUnitTextProvider = CLKSimpleTextProvider(text: "\(wind) km/h")
        let bareCreekTextProvider = CLKSimpleTextProvider(text: "Bare Creek")
        let statusTextProvider = CLKSimpleTextProvider(text: status)
        let windLabelTextProvider = CLKSimpleTextProvider(text: "Wind: \(wind) km/h")
        
        switch family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText(
                line1TextProvider: bcTextProvider,
                line2TextProvider: windTextProvider
            )
            template.tintColor = color
            return template
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: bareCreekTextProvider,
                body1TextProvider: statusTextProvider,
                body2TextProvider: windLabelTextProvider
            )
            template.tintColor = color
            return template
            
        case .utilitarianSmall, .utilitarianSmallFlat:
            let combinedTextProvider = CLKSimpleTextProvider(text: "BC \(wind)")
            let template = CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: combinedTextProvider
            )
            template.tintColor = color
            return template
            
        case .utilitarianLarge:
            let combinedTextProvider = CLKSimpleTextProvider(text: "Bare Creek: \(wind) km/h")
            let template = CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: combinedTextProvider
            )
            template.tintColor = color
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText(
                line1TextProvider: bcTextProvider,
                line2TextProvider: windTextProvider
            )
            template.tintColor = color
            return template
            
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeStackText(
                line1TextProvider: bcTextProvider,
                line2TextProvider: windTextProvider
            )
            template.tintColor = color
            return template
            
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: bcTextProvider,
                outerTextProvider: windWithUnitTextProvider
            )
            
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: bcTextProvider,
                line2TextProvider: windTextProvider
            )
            
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: bareCreekTextProvider,
                body1TextProvider: statusTextProvider,
                body2TextProvider: windLabelTextProvider
            )
            
        default:
            return nil
        }
    }
    
    // Helper function to convert color string to UIColor
    private func colorFromString(_ colorString: String) -> UIColor {
        switch colorString {
        case "green":
            return UIColor.green
        case "yellow":
            return UIColor.yellow
        case "orange":
            return UIColor.orange
        case "red":
            return UIColor.red
        case "blue":
            return UIColor.blue
        default:
            return UIColor.lightGray
        }
    }
}
