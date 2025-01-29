//
//  Home.swift
//  PushNotifications
//
//  Created by Kester Atakere on 31/01/2025.
//

import AVKit
import CoreLocation
import SwiftUI
import UserNotifications

class HapticManager {
  static let instance = HapticManager()  // Singleton

  func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(type)
  }

  func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
  }
}

class SoundManager {
  static let instance = SoundManager()  // Singleton

  var player: AVAudioPlayer?

  enum SoundOption: String {
    case pop = "Pop"
  }

  func playSound(_ option: SoundOption) {
    guard let url = Bundle.main.url(forResource: option.rawValue, withExtension: "mp3") else {
      return
    }
    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.play()
    } catch let error {
      print("Error playing sound: \(error.localizedDescription)")
    }
  }

}

class NotificationManager: NSObject {

  static let instance = NotificationManager()  // Singleton
  private var locationManager: CLLocationManager?

  func requestPermission(completion: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    center.requestAuthorization(options: options) { (granted, error) in
      if granted {
        print("Notification permission granted")
      } else {
        print("Notification permission denied")
      }

      // Request location permission
      self.requestLocationPermission { granted in
        completion(granted)
      }
    }
  }

  func requestLocationPermission(completion: @escaping (Bool) -> Void) {
    locationManager = CLLocationManager()
    locationManager?.delegate = self  // Ensure CLLocationManagerDelegate is set
    locationManager?.requestAlwaysAuthorization()
    completion(true)  // We can assume permission granted for now, for demo purposes.
  }

  func scheduleNotification(title: String, body: String) {
    requestPermission { [weak self] granted in
      guard granted else { return }

      // Fetch current location before scheduling notification
      self?.fetchCurrentLocation { location in
        if let location = location {
          print("User's current location: \(location.latitude), \(location.longitude)")

          let content = UNMutableNotificationContent()
          content.title = title
          content.body = body
          content.sound = UNNotificationSound.default
          content.badge = 1

          // Add image attachment
          if let attachment = self?.createImageAttachment(imageName: "1") {
            content.attachments = [attachment]
          }

          // Time notification trigger
          // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

          // Calendar notification trigger
          //   var dateComponents = DateComponents()
          //   dateComponents.hour = 20
          //   dateComponents.minute = 20
          //   dateComponents.second = 45
          //   let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

          // Region notification trigger

          let region = CLCircularRegion(
            center: location,
            radius: 100,
            identifier: UUID().uuidString)
          region.notifyOnEntry = true
          region.notifyOnExit = true
          let trigger = UNLocationNotificationTrigger(region: region, repeats: true)

          let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
          )

          UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
              print("Error scheduling notification: \(error)")
            }
          }

          let coordinates = CLLocationCoordinate2D(  // CHANGE TO YOUR COORDINATES
            latitude: 76,
            longitude: 87)

          // check if user is in the region already & send notification
          if region.contains(coordinates) {
            print("User is in the region")

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
              identifier: UUID().uuidString,
              content: content,
              trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
              if let error = error {
                print("Error scheduling notification: \(error)")
              }
            }
          }

        } else {
          print("Failed to get current location")
        }
      }
    }
  }

  private func fetchCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
    // Start updating location to get the current coordinates
    if let locationManager = locationManager {
      locationManager.startUpdatingLocation()
    }
    // Use a completion block when location is fetched (this will depend on the delegate method)
    completion(locationManager?.location?.coordinate)
  }

  private func createImageAttachment(imageName: String) -> UNNotificationAttachment? {
    guard let image = UIImage(named: imageName) else {
      print("Image not found in Assets catalog")
      return nil
    }

    let temporaryDirectory = NSTemporaryDirectory()
    let fileName = "\(UUID().uuidString).jpg"
    let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)

    do {
      if let imageData = image.jpegData(compressionQuality: 1.0) {
        try imageData.write(to: fileURL)
        let attachment = try UNNotificationAttachment(
          identifier: UUID().uuidString, url: fileURL, options: nil)

        return attachment
      } else {
        print("Failed to convert UIImage to JPEG data")
        return nil
      }
    } catch {
      print("Error creating image attachment: \(error)")
      return nil
    }
  }

  func cancelNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  }

}

extension NotificationManager: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    switch status {
    case .authorizedAlways:
      print("Location permission granted for background location updates.")
    case .denied, .restricted:
      print("Location permission denied.")
    default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Stop updating location after getting the current location
    if let currentLocation = locations.first {
      print(
        "Current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)"
      )
      manager.stopUpdatingLocation()  // Stop updating location once it's fetched
    }
  }
}

struct Home: View {
  var body: some View {
    VStack(spacing: 20) {
      Button("Schedule Notification") {
        NotificationManager.instance.scheduleNotification(
          title: "Sync",
          body: "Account has been synced"
        )
      }
      Button("Cancel Notifications") {
        NotificationManager.instance.cancelNotifications()
      }

      Divider()
      Divider()
      Button("pop") { SoundManager.instance.playSound(.pop) }
      Divider()
      Button("success") { HapticManager.instance.notification(.success) }
      Button("warning") { HapticManager.instance.notification(.warning) }
      Button("error") { HapticManager.instance.notification(.error) }
      Divider()
      Button("soft") { HapticManager.instance.impact(.soft) }
      Button("light") { HapticManager.instance.impact(.light) }
      Button("medium") { HapticManager.instance.impact(.medium) }
      Button("rigid") { HapticManager.instance.impact(.rigid) }
      Button("heavy") { HapticManager.instance.impact(.heavy) }
    }
    .onAppear {
      UNUserNotificationCenter.current().setBadgeCount(0)
    }

  }

}

#Preview {
  Home()
}
