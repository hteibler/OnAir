import CoreMediaIO

/// Reports whether any camera is currently in use by some process on the system.
/// Uses the CoreMediaIO `DeviceIsRunningSomewhere` property, which does not
/// require camera (TCC) permission.
enum CameraMonitor {
    static func isInUse() -> Bool {
        let devices = allDevices()
        for device in devices where deviceIsRunning(device) {
            return true
        }
        return false
    }

    private static func allDevices() -> [CMIOObjectID] {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var dataSize: UInt32 = 0
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &dataSize) == kCMIOHardwareNoError,
              dataSize > 0 else {
            return []
        }

        let count = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, dataSize, &dataUsed, &devices) == kCMIOHardwareNoError else {
            return []
        }
        return devices
    }

    private static func deviceIsRunning(_ device: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )

        var isRunning: UInt32 = 0
        var dataUsed: UInt32 = 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        guard CMIOObjectGetPropertyData(device, &address, 0, nil, size, &dataUsed, &isRunning) == kCMIOHardwareNoError else {
            return false
        }
        return isRunning != 0
    }
}
