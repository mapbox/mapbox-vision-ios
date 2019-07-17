import CoreBluetooth

final class BluetoothManager: NSObject {
    private(set) var isBluetoothPoweredOn = false

    private var coreBluetoothManager: CBCentralManager?
    private let bluetoothManagerQueue = DispatchQueue(label: "com.mapbox.BluetoothManager")

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
        default:
            isBluetoothPoweredOn = false
        }
    }
}
