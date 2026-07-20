import Flutter
import HealthKit
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()
  private var healthAlertChannel: FlutterMethodChannel?
  private var healthAlertNotificationChannel: FlutterMethodChannel?
  private var healthAlertBridgeRegistrationAttempts = 0
  private var emittedBloodPressureEventKeys = Set<String>()
  private var emittedAggregateEventKeys = Set<String>()
  private let anchorPrefix = "health_alert_anchor_"
  private let healthAlertStandardLookbackSeconds: TimeInterval = 24 * 60 * 60
  private let healthAlertHighFrequencyLookbackSeconds: TimeInterval = 3 * 60 * 60
  private let healthAlertAggregateWindowSeconds: TimeInterval = 15 * 60
  private let healthAlertHighFrequencyQueryLimit = 500
  private let healthAlertStandardQueryLimit = 100
  private let healthAlertMaxAggregateEventsPerType = 12

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    configureHealthAlertBridge()
    configureHealthAlertNotificationBridge()
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    reconcileHealthAlertSamples()
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  private func configureHealthAlertNotificationBridge() {
    if healthAlertNotificationChannel != nil {
      return
    }
    guard let controller = flutterViewController() else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        self?.configureHealthAlertNotificationBridge()
      }
      return
    }
    let channel = FlutterMethodChannel(
      name: "smart_health/health_alert_notifications",
      binaryMessenger: controller.binaryMessenger
    )
    healthAlertNotificationChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "showHealthAlertNotification":
        guard let args = call.arguments as? [String: Any] else {
          result("notification arguments missing")
          return
        }
        let title = args["title"] as? String ?? "Health reminder"
        let body = args["body"] as? String ?? ""
        self.showHealthAlertNotification(title: title, body: body, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func showHealthAlertNotification(
    title: String,
    body: String,
    result: @escaping FlutterResult
  ) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        DispatchQueue.main.async {
          result(error.localizedDescription)
        }
        return
      }
      guard granted else {
        DispatchQueue.main.async {
          result("notification permission denied")
        }
        return
      }
      center.getNotificationSettings { settings in
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
          DispatchQueue.main.async {
            result("notification authorization status: \(settings.authorizationStatus.rawValue)")
          }
          return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
          identifier: "health-alert-\(Int(Date().timeIntervalSince1970 * 1000))",
          content: content,
          trigger: trigger
        )
        center.add(request) { error in
          DispatchQueue.main.async {
            result(error?.localizedDescription)
          }
        }
      }
    }
  }

  private func configureHealthAlertBridge() {
    if healthAlertChannel != nil {
      return
    }
    guard let controller = flutterViewController() else {
      healthAlertBridgeRegistrationAttempts += 1
      guard healthAlertBridgeRegistrationAttempts <= 5 else {
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        self?.configureHealthAlertBridge()
      }
      return
    }
    healthAlertBridgeRegistrationAttempts = 0
    let channel = FlutterMethodChannel(
      name: "smart_health/healthkit_alerts",
      binaryMessenger: controller.binaryMessenger
    )
    healthAlertChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "startHealthAlerts":
        self.requestHealthAlertAuthorization { success, error in
          if success {
            self.registerHealthAlertObservers()
            self.reconcileHealthAlertSamples()
            result(true)
          } else {
            result(FlutterError(code: "healthkit_unavailable", message: error ?? "HealthKit authorization failed.", details: nil))
          }
        }
      case "reconcileHealthAlerts":
        self.reconcileHealthAlertSamples()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func flutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }
    if let controller = findFlutterViewController(in: window?.rootViewController) {
      return controller
    }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else {
        continue
      }
      for sceneWindow in windowScene.windows {
        if let controller = sceneWindow.rootViewController as? FlutterViewController {
          return controller
        }
        if let controller = findFlutterViewController(in: sceneWindow.rootViewController) {
          return controller
        }
      }
    }
    return nil
  }

  private func findFlutterViewController(in controller: UIViewController?) -> FlutterViewController? {
    if let flutterController = controller as? FlutterViewController {
      return flutterController
    }
    if let navigationController = controller as? UINavigationController {
      return findFlutterViewController(in: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
      return findFlutterViewController(in: tabController.selectedViewController)
    }
    if let presented = controller?.presentedViewController {
      return findFlutterViewController(in: presented)
    }
    for child in controller?.children ?? [] {
      if let flutterController = findFlutterViewController(in: child) {
        return flutterController
      }
    }
    return nil
  }

  private func requestHealthAlertAuthorization(completion: @escaping (Bool, String?) -> Void) {
    guard HKHealthStore.isHealthDataAvailable() else {
      completion(false, "HealthKit is not available on this device.")
      return
    }
    healthStore.requestAuthorization(toShare: [], read: healthAlertReadTypes()) { success, error in
      completion(success, error?.localizedDescription)
    }
  }

  private func registerHealthAlertObservers() {
    for sampleType in healthAlertSampleTypes() {
      let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, _ in
        self?.runAnchoredQuery(for: sampleType) {
          completionHandler()
        }
      }
      healthStore.execute(query)
      healthStore.enableBackgroundDelivery(for: sampleType, frequency: deliveryFrequency(for: sampleType)) { _, _ in }
    }
  }

  private func reconcileHealthAlertSamples() {
    for sampleType in healthAlertSampleTypes() {
      runAnchoredQuery(for: sampleType, completion: nil)
    }
  }

  private func runAnchoredQuery(for sampleType: HKSampleType, completion: (() -> Void)?) {
    let start = Date().addingTimeInterval(-lookbackSeconds(for: sampleType))
    let predicate = HKQuery.predicateForSamples(withStart: start, end: nil, options: [])
    let query = HKAnchoredObjectQuery(
      type: sampleType,
      predicate: predicate,
      anchor: loadAnchor(for: sampleType),
      limit: queryLimit(for: sampleType)
    ) { [weak self] _, samples, deletedObjects, newAnchor, error in
      guard let self = self else { completion?(); return }
      defer { completion?() }
      guard error == nil else { return }
      self.emitHealthAlertEvents(samples ?? [], sampleType: sampleType)
      for deleted in deletedObjects ?? [] {
        if self.shouldEmitDeletedEvent(for: sampleType) {
          self.emitDeletedHealthAlertEvent(deleted, sampleType: sampleType)
        }
      }
      if let newAnchor = newAnchor {
        self.saveAnchor(newAnchor, for: sampleType)
      }
    }
    healthStore.execute(query)
  }

  private func emitHealthAlertEvents(_ samples: [HKSample], sampleType: HKSampleType) {
    switch sampleType.identifier {
    case HKQuantityTypeIdentifier.heartRate.rawValue:
      emitQuantityAggregateEvents(
        samples.compactMap { $0 as? HKQuantitySample },
        sampleType: sampleType,
        valueKey: "heart_rate",
        eventType: "heart_rate",
        unit: "count/min",
        sourceIdPrefix: "hk-heart-rate",
        unitConverter: { $0.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) },
        reduce: .average
      )
    case HKQuantityTypeIdentifier.stepCount.rawValue:
      emitQuantityAggregateEvents(
        samples.compactMap { $0 as? HKQuantitySample },
        sampleType: sampleType,
        valueKey: "steps",
        eventType: "activity",
        unit: "count",
        sourceIdPrefix: "hk-step-count",
        unitConverter: { $0.doubleValue(for: HKUnit.count()) },
        reduce: .sum
      )
    case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
      emitSleepAggregateEvents(samples.compactMap { $0 as? HKCategorySample }, sampleType: sampleType)
    default:
      for sample in samples {
        emitHealthAlertEvent(for: sample, sampleType: sampleType, deleted: false)
      }
    }
  }

  private func emitHealthAlertEvent(for sample: HKSample, sampleType: HKSampleType, deleted: Bool) {
    if let quantitySample = sample as? HKQuantitySample {
      emitQuantityHealthAlertEvent(quantitySample, sampleType: sampleType, deleted: deleted)
    } else if let categorySample = sample as? HKCategorySample {
      emitCategoryHealthAlertEvent(categorySample, sampleType: sampleType, deleted: deleted)
    } else if let workout = sample as? HKWorkout {
      emitWorkoutHealthAlertEvent(workout, deleted: deleted)
    }
  }

  private enum AggregateReduce: Equatable {
    case average
    case sum
  }

  private struct QuantityAggregate {
    var total = 0.0
    var count = 0
    var minimum: Double?
    var maximum: Double?
    var sampleIds = [String]()
    var sourceBundleIds = Set<String>()
    var sourceNames = Set<String>()

    mutating func add(value: Double, sample: HKQuantitySample) {
      total += value
      count += 1
      minimum = minimum.map { min($0, value) } ?? value
      maximum = maximum.map { max($0, value) } ?? value
      sampleIds.append(sample.uuid.uuidString)
      sourceBundleIds.insert(sample.sourceRevision.source.bundleIdentifier)
      sourceNames.insert(sample.sourceRevision.source.name)
    }
  }

  private struct SleepAggregate {
    var seconds = 0.0
    var count = 0
    var sampleIds = [String]()
    var sourceBundleIds = Set<String>()
    var sourceNames = Set<String>()

    mutating func add(seconds: Double, sample: HKCategorySample) {
      self.seconds += seconds
      count += 1
      sampleIds.append(sample.uuid.uuidString)
      sourceBundleIds.insert(sample.sourceRevision.source.bundleIdentifier)
      sourceNames.insert(sample.sourceRevision.source.name)
    }
  }

  private func emitQuantityAggregateEvents(
    _ samples: [HKQuantitySample],
    sampleType: HKSampleType,
    valueKey: String,
    eventType: String,
    unit: String,
    sourceIdPrefix: String,
    unitConverter: (HKQuantity) -> Double,
    reduce: AggregateReduce
  ) {
    var aggregates = [TimeInterval: QuantityAggregate]()
    for sample in samples {
      let bucketStart = bucketStartTimestamp(for: sample.endDate)
      var aggregate = aggregates[bucketStart] ?? QuantityAggregate()
      aggregate.add(value: unitConverter(sample.quantity), sample: sample)
      aggregates[bucketStart] = aggregate
    }

    for bucketStart in aggregateBucketStarts(from: aggregates.keys) {
      guard let aggregate = aggregates[bucketStart], aggregate.count > 0 else { continue }
      let eventKey = "\(sourceIdPrefix)-\(Int(bucketStart))"
      guard shouldEmitAggregateEvent(key: eventKey) else { continue }
      let value = reduce == .average ? aggregate.total / Double(aggregate.count) : aggregate.total
      var values: [String: Any] = [
        valueKey: value,
        "window_minutes": Int(healthAlertAggregateWindowSeconds / 60),
        "sample_count": aggregate.count,
      ]
      if let minimum = aggregate.minimum {
        values["\(valueKey)_min"] = minimum
      }
      if let maximum = aggregate.maximum {
        values["\(valueKey)_max"] = maximum
      }
      emitFlutterEvent([
        "event_type": eventType,
        "event_source_id": eventKey,
        "event_time": isoString(Date(timeIntervalSince1970: bucketStart + healthAlertAggregateWindowSeconds)),
        "values": values,
        "unit": unit,
        "source": "apple_health",
        "source_mode": "production",
        "source_metadata": aggregateSourceMetadata(
          sampleType: sampleType,
          bucketStart: bucketStart,
          sampleIds: aggregate.sampleIds,
          sourceBundleIds: aggregate.sourceBundleIds,
          sourceNames: aggregate.sourceNames
        ),
      ])
    }
  }

  private func emitSleepAggregateEvents(_ samples: [HKCategorySample], sampleType: HKSampleType) {
    var aggregates = [TimeInterval: SleepAggregate]()
    for sample in samples where isAsleepSample(sample) {
      var cursor = sample.startDate
      while cursor < sample.endDate {
        let bucketStart = bucketStartTimestamp(for: cursor)
        let bucketEnd = Date(timeIntervalSince1970: bucketStart + healthAlertAggregateWindowSeconds)
        let overlapEnd = min(bucketEnd, sample.endDate)
        let seconds = overlapEnd.timeIntervalSince(cursor)
        if seconds > 0 {
          var aggregate = aggregates[bucketStart] ?? SleepAggregate()
          aggregate.add(seconds: seconds, sample: sample)
          aggregates[bucketStart] = aggregate
        }
        cursor = overlapEnd
      }
    }

    for bucketStart in aggregateBucketStarts(from: aggregates.keys) {
      guard let aggregate = aggregates[bucketStart], aggregate.seconds > 0 else { continue }
      let eventKey = "hk-sleep-\(Int(bucketStart))"
      guard shouldEmitAggregateEvent(key: eventKey) else { continue }
      emitFlutterEvent([
        "event_type": "sleep",
        "event_source_id": eventKey,
        "event_time": isoString(Date(timeIntervalSince1970: bucketStart + healthAlertAggregateWindowSeconds)),
        "values": [
          "sleep_seconds": aggregate.seconds,
          "sleep": aggregate.seconds / 3600,
          "window_minutes": Int(healthAlertAggregateWindowSeconds / 60),
          "sample_count": aggregate.count,
        ],
        "unit": "seconds",
        "source": "apple_health",
        "source_mode": "production",
        "source_metadata": aggregateSourceMetadata(
          sampleType: sampleType,
          bucketStart: bucketStart,
          sampleIds: aggregate.sampleIds,
          sourceBundleIds: aggregate.sourceBundleIds,
          sourceNames: aggregate.sourceNames
        ),
      ])
    }
  }

  private func aggregateBucketStarts<Keys: Collection>(from keys: Keys) -> [TimeInterval]
  where Keys.Element == TimeInterval {
    return Array(Array(keys).sorted().suffix(healthAlertMaxAggregateEventsPerType))
  }

  private func bucketStartTimestamp(for date: Date) -> TimeInterval {
    let timestamp = date.timeIntervalSince1970
    return floor(timestamp / healthAlertAggregateWindowSeconds) * healthAlertAggregateWindowSeconds
  }

  private func shouldEmitAggregateEvent(key: String) -> Bool {
    if emittedAggregateEventKeys.contains(key) {
      return false
    }
    emittedAggregateEventKeys.insert(key)
    if emittedAggregateEventKeys.count > 500 {
      emittedAggregateEventKeys.removeAll(keepingCapacity: true)
    }
    return true
  }

  private func aggregateSourceMetadata(
    sampleType: HKSampleType,
    bucketStart: TimeInterval,
    sampleIds: [String],
    sourceBundleIds: Set<String>,
    sourceNames: Set<String>
  ) -> [String: Any] {
    return [
      "sample_type": sampleType.identifier,
      "aggregate": true,
      "aggregate_window_seconds": Int(healthAlertAggregateWindowSeconds),
      "aggregate_bucket_start": isoString(Date(timeIntervalSince1970: bucketStart)),
      "aggregate_bucket_end": isoString(Date(timeIntervalSince1970: bucketStart + healthAlertAggregateWindowSeconds)),
      "source_sample_ids": sampleIds,
      "source_bundle_ids": Array(sourceBundleIds).sorted(),
      "source_names": Array(sourceNames).sorted(),
      "deleted_at_source": false,
    ]
  }

  private func isAsleepSample(_ sample: HKCategorySample) -> Bool {
    // SleepAnalysis raw values 0 and 2 are in-bed/awake; asleep stages are positive sleep intervals.
    return sample.value != 0 && sample.value != 2
  }

  private func emitQuantityHealthAlertEvent(_ sample: HKQuantitySample, sampleType: HKSampleType, deleted: Bool) {
    let identifier = sampleType.identifier
    if identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue ||
      identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
      emitBloodPressureEvent(around: sample)
      return
    }

    var eventType = "activity"
    var values: [String: Any] = [:]
    var unit = "count"
    if identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
      eventType = "heart_rate"
      unit = "count/min"
      values["heart_rate"] = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
    } else if identifier == HKQuantityTypeIdentifier.stepCount.rawValue {
      eventType = "activity"
      unit = "count"
      values["steps"] = sample.quantity.doubleValue(for: HKUnit.count())
    }

    emitFlutterEvent([
      "event_type": eventType,
      "event_source_id": sample.uuid.uuidString,
      "event_time": isoString(sample.endDate),
      "values": values,
      "unit": unit,
      "source": "apple_health",
      "source_mode": "production",
      "source_metadata": sourceMetadata(for: sample, deleted: deleted),
    ])
  }

  private func emitBloodPressureEvent(around sample: HKQuantitySample) {
    let eventKey = "\(Int(sample.endDate.timeIntervalSince1970 / 300))-\(sample.sourceRevision.source.bundleIdentifier)"
    if emittedBloodPressureEventKeys.contains(eventKey) {
      return
    }
    emittedBloodPressureEventKeys.insert(eventKey)
    if emittedBloodPressureEventKeys.count > 100 {
      emittedBloodPressureEventKeys.removeAll(keepingCapacity: true)
    }

    guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
      let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
      return
    }
    let start = sample.startDate.addingTimeInterval(-300)
    let end = sample.endDate.addingTimeInterval(300)
    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
    let group = DispatchGroup()
    var systolic: Double?
    var diastolic: Double?

    group.enter()
    latestQuantity(for: systolicType, predicate: predicate, unit: HKUnit.millimeterOfMercury()) { value in
      systolic = value
      group.leave()
    }
    group.enter()
    latestQuantity(for: diastolicType, predicate: predicate, unit: HKUnit.millimeterOfMercury()) { value in
      diastolic = value
      group.leave()
    }

    group.notify(queue: .main) { [weak self] in
      guard let self = self, let systolic = systolic, let diastolic = diastolic else { return }
      self.emitFlutterEvent([
        "event_type": "blood_pressure",
        "event_source_id": sample.uuid.uuidString,
        "event_time": self.isoString(sample.endDate),
        "values": ["systolic": systolic, "diastolic": diastolic],
        "unit": "mmHg",
        "source": "apple_health",
        "source_mode": "production",
        "source_metadata": self.sourceMetadata(for: sample, deleted: false),
      ])
    }
  }

  private func latestQuantity(
    for quantityType: HKQuantityType,
    predicate: NSPredicate,
    unit: HKUnit,
    completion: @escaping (Double?) -> Void
  ) {
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
      let sample = samples?.first as? HKQuantitySample
      completion(sample?.quantity.doubleValue(for: unit))
    }
    healthStore.execute(query)
  }

  private func emitCategoryHealthAlertEvent(_ sample: HKCategorySample, sampleType: HKSampleType, deleted: Bool) {
    guard sampleType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return }
    emitFlutterEvent([
      "event_type": "sleep",
      "event_source_id": sample.uuid.uuidString,
      "event_time": isoString(sample.endDate),
      "values": ["sleep_seconds": sample.endDate.timeIntervalSince(sample.startDate), "category_value": sample.value],
      "unit": "seconds",
      "source": "apple_health",
      "source_mode": "production",
      "source_metadata": sourceMetadata(for: sample, deleted: deleted),
    ])
  }

  private func emitWorkoutHealthAlertEvent(_ workout: HKWorkout, deleted: Bool) {
    emitFlutterEvent([
      "event_type": "workout",
      "event_source_id": workout.uuid.uuidString,
      "event_time": isoString(workout.endDate),
      "values": [
        "duration_seconds": workout.duration,
        "workout_activity_type": workout.workoutActivityType.rawValue,
        "total_energy_kcal": workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) as Any,
        "distance_meters": workout.totalDistance?.doubleValue(for: HKUnit.meter()) as Any,
      ],
      "unit": "mixed",
      "source": "apple_health",
      "source_mode": "production",
      "source_metadata": sourceMetadata(for: workout, deleted: deleted),
    ])
  }

  private func emitDeletedHealthAlertEvent(_ deleted: HKDeletedObject, sampleType: HKSampleType) {
    emitFlutterEvent([
      "event_type": eventType(for: sampleType),
      "event_source_id": deleted.uuid.uuidString,
      "event_time": isoString(Date()),
      "values": ["deleted": true],
      "source": "apple_health",
      "source_mode": "production",
      "source_metadata": ["deleted_at_source": true, "sample_type": sampleType.identifier],
    ])
  }

  private func emitFlutterEvent(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.healthAlertChannel?.invokeMethod("healthAlertEvent", arguments: payload)
    }
  }

  private func healthAlertReadTypes() -> Set<HKObjectType> {
    return Set(healthAlertSampleTypes().map { $0 as HKObjectType })
  }

  private func healthAlertSampleTypes() -> [HKSampleType] {
    let quantityTypes = [
      HKQuantityTypeIdentifier.heartRate,
      HKQuantityTypeIdentifier.stepCount,
      HKQuantityTypeIdentifier.bloodPressureSystolic,
      HKQuantityTypeIdentifier.bloodPressureDiastolic,
    ].compactMap { identifier in
      HKObjectType.quantityType(forIdentifier: identifier)
    }
    let categoryTypes = [
      HKCategoryTypeIdentifier.sleepAnalysis,
    ].compactMap { identifier in
      HKObjectType.categoryType(forIdentifier: identifier)
    }
    return quantityTypes + categoryTypes + [HKObjectType.workoutType()]
  }

  private func deliveryFrequency(for sampleType: HKSampleType) -> HKUpdateFrequency {
    if sampleType.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue ||
      sampleType.identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue ||
      sampleType.identifier == HKWorkoutTypeIdentifier {
      return .immediate
    }
    return .hourly
  }

  private func lookbackSeconds(for sampleType: HKSampleType) -> TimeInterval {
    if isHighFrequencyType(sampleType) {
      return healthAlertHighFrequencyLookbackSeconds
    }
    return healthAlertStandardLookbackSeconds
  }

  private func queryLimit(for sampleType: HKSampleType) -> Int {
    return isHighFrequencyType(sampleType) ? healthAlertHighFrequencyQueryLimit : healthAlertStandardQueryLimit
  }

  private func isHighFrequencyType(_ sampleType: HKSampleType) -> Bool {
    return sampleType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue ||
      sampleType.identifier == HKQuantityTypeIdentifier.stepCount.rawValue ||
      sampleType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue
  }

  private func shouldEmitDeletedEvent(for sampleType: HKSampleType) -> Bool {
    return !isHighFrequencyType(sampleType)
  }

  private func sourceMetadata(for sample: HKSample, deleted: Bool) -> [String: Any] {
    return [
      "sample_type": sample.sampleType.identifier,
      "source_bundle_id": sample.sourceRevision.source.bundleIdentifier,
      "source_name": sample.sourceRevision.source.name,
      "deleted_at_source": deleted,
    ]
  }

  private func eventType(for sampleType: HKSampleType) -> String {
    switch sampleType.identifier {
    case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
      HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
      return "blood_pressure"
    case HKQuantityTypeIdentifier.heartRate.rawValue:
      return "heart_rate"
    case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
      return "sleep"
    default:
      return sampleType.identifier == HKWorkoutTypeIdentifier ? "workout" : "activity"
    }
  }

  private func anchorKey(for sampleType: HKSampleType) -> String {
    return "\(anchorPrefix)\(sampleType.identifier)"
  }

  private func loadAnchor(for sampleType: HKSampleType) -> HKQueryAnchor? {
    guard let data = UserDefaults.standard.data(forKey: anchorKey(for: sampleType)) else {
      return nil
    }
    return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
  }

  private func saveAnchor(_ anchor: HKQueryAnchor, for sampleType: HKSampleType) {
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) {
      UserDefaults.standard.set(data, forKey: anchorKey(for: sampleType))
    }
  }

  private func isoString(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}
