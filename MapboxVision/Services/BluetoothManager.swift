import CoreBluetooth

/// Class that contains logic to dispatch and manage the bluetooth module.
final class BluetoothManager: NSObject {
    // MARK: Public properties

    /// Indicates whether the bluetooth module is powered on.
    var isBluetoothPoweredOn: Bool {
        return coreBluetoothManager.state == .poweredOn
    }

    // MARK: Private properties

    /// Underlying `CBCentralManager` object that manages state of bluetooth module.
    private var coreBluetoothManager: CBCentralManager!

    // MARK: Lifecycle

    /**
     Base initializer to create an instance of `BluetoothManager`.
     */
    override init() {
        super.init()
        coreBluetoothManager = CBCentralManager(delegate: nil, queue: nil)
    }
}
