import CoreBluetooth

/// Class that contains logic to dispatch and manage the bluetooth module.
final class BluetoothManager: NSObject {
    // MARK: Public properties

    /// Indicates whether the bluetooth module is powered on.
    private(set) var isBluetoothPoweredOn = false

    // MARK: Private properties

    /// Underlying `CBCentralManager` object that manages state of bluetooth module.
    private var coreBluetoothManager: CBCentralManager?
    /// The dispatch queue to dispatch the CBCentralManager's events.
    private let bluetoothManagerQueue = DispatchQueue(label: "com.mapbox.BluetoothManager")

    // MARK: Lifecycle

    /**
     Base initializer to create an instance of `BluetoothManager`.
     */
    override init() {
        super.init()
        coreBluetoothManager = CBCentralManager(delegate: self, queue: bluetoothManagerQueue)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothPoweredOn = true
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            isBluetoothPoweredOn = false
        }
    }
}
