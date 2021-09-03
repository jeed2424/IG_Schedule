//
//  NotificaionManager.swift
//  LazyPublish
//
//  Created by KSun on 2021/7/16.
//  Copyright © 2021 SeanGuang. All rights reserved.
//
// MARK: - Notes
/*
1. Remove "repeats"
 */

import Foundation
import UserNotifications

enum NotificationManagerConstants {
  static let calendarBasedNotificationThreadId =
    "CalendarBasedNotificationThreadId"
}
// Only iOS 13, app should be 13+ anyway...
@available(iOS 13.0, *)
class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  @Published var settings: UNNotificationSettings?

  func requestAuthorization(completion: @escaping  (Bool) -> Void) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _  in
        self.fetchNotificationSettings()
        completion(granted)
      }
  }

  func fetchNotificationSettings() {
    // 1
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      // 2
      DispatchQueue.main.async {
        self.settings = settings
      }
    }
  }

  func removeScheduledNotification(task: Post) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [task.id])
  }

  // 1
  func scheduleNotification(task: Post) {
    // 2
    let content = UNMutableNotificationContent()
    //Title and body can be changed based on the post type, etc.
    content.title = "Time to post your story"
    content.body = "Gentle reminder for your task!"
    content.categoryIdentifier = "LazyPublishCategory"
    let taskData = try? JSONEncoder().encode(task)
    if let taskData = taskData {
      content.userInfo = ["Task": taskData]
    }

    // 3
    var trigger: UNNotificationTrigger?
   

      if let date = task.time {
        trigger = UNCalendarNotificationTrigger(
          dateMatching: Calendar.current.dateComponents(
            [.day, .month, .year, .hour, .minute],
            from: date),
            repeats: (task.time != nil))
      }
      content.threadIdentifier =
        NotificationManagerConstants.calendarBasedNotificationThreadId

    // 4
    if let trigger = trigger {
      let request = UNNotificationRequest(
        identifier: task.id,
        content: content,
        trigger: trigger)
      // 5
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          print(error)
        }
      }
    }
  }
}

// MARK: Notificaiton Name extension

extension Notification.Name {
    static let PostWasSuccessfullyScheduled = Notification.Name("PostWasSuccessfullyScheduled")
}
