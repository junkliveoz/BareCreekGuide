//
//  ComplicationController.swift
//  Bare Creek Guide
//
//  Created by Adam on 7/4/2025.
//  Updated on 7/4/2025 to fix text provider issues
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
        
        switch family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BC")
            template.line2TextProvider = CLKSimpleTextProvider(text: wind)
            template.tintColor = color
            return template
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Bare Creek")
            template.body1TextProvider = CLKSimpleTextProvider(text: status)
            template.body2TextProvider = CLKSimpleTextProvider(text: "Wind: \(wind) km/h")
            template.tintColor = color
            return template
            
        case .utilitarianSmall, .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: "BC \(wind)")
            template.tintColor = color
            return template
            
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Bare Creek: \(wind) km/h")
            template.tintColor = color
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BC")
            template.line2TextProvider = CLKSimpleTextProvider(text: wind)
            template.tintColor = color
            return template
            
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BC")
            template.line2TextProvider = CLKSimpleTextProvider(text: wind)
            template.tintColor = color
            return template
            
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerStackText()
            template.innerTextProvider = CLKSimpleTextProvider(text: "BC")
            template.outerTextProvider = CLKSimpleTextProvider(text: "\(wind) km/h")
            return template
            
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "BC")
            template.line2TextProvider = CLKSimpleTextProvider(text: wind)
            return template
            
        case .graphicRectangular:
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Bare Creek")
            template.body1TextProvider = CLKSimpleTextProvider(text: status)
            template.body2TextProvider = CLKSimpleTextProvider(text: "Wind: \(wind) km/h")
            return template
            
        default:
            return nil
        }
    }
    
    // Helper function to convert color string to UIColor
    private func colorFromString(_ colorString: String) -> UIColor {
        switch colorString {
        case "green":
            // Simply use standard colors - watchOS 6.0 is the minimum deployment
            // target for modern Watch apps anyway
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
