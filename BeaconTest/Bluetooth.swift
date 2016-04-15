//
//  Bluetooth.swift
//  BeaconTest
//
//  Created by Henk van der Spek on 14/04/16.
//  Copyright © 2016 vanmezelf.nl. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothPeripheralImplementation {
    var d: Bluetooth.Peripheral? { get set }
    func advertise(success: ()->(), failure: (()->())?)
    func isAdvertising() -> Bool
    func stopAdvertising()
}

struct Bluetooth {
    struct Characteristic {
        let uuid: CBUUID
        let value: NSData
        let writable: Bool
        static var defaultUuid = CBUUID()
        static func forString(string: String, uuid: CBUUID) -> Characteristic? {
            if let value = string.dataUsingEncoding(NSASCIIStringEncoding) {
                return Characteristic(uuid: uuid, value: value, writable: false)
            }
            return nil
        }
    }
    struct Service {
        let uuid: CBUUID
        let characteristics: [Characteristic]
        let primary: Bool
        static var defaultUuid = CBUUID()
        static func forCharacteristics(characteristics: [Characteristic], uuid: CBUUID, primary: Bool) -> Service {
            return Service(uuid: uuid, characteristics: characteristics, primary: primary)
        }
    }
    struct Peripheral {
        let services: [Service]
        var implementation: BluetoothPeripheralImplementation
        static var defaultImplementation: BluetoothPeripheralImplementation = CoreBluetoothImplementation()
        init(services: [Service], implementation: BluetoothPeripheralImplementation = defaultImplementation) {
            self.services = services
            self.implementation = implementation
            self.implementation.d = self
        }
        static func forServices(services: [Service]) -> Peripheral {
            return Peripheral(services: services)
        }
        static func forStringCharacteristic(string: String, characteristicUuid: CBUUID = Characteristic.defaultUuid, serviceUuid: CBUUID = Service.defaultUuid) -> Peripheral? {
            if let characteristic = Characteristic.forString(string, uuid: characteristicUuid) {
                return forServices([Service.forCharacteristics([characteristic], uuid: serviceUuid, primary: true)])
            }
            return nil
        }
        static func advertise(string: String, characteristicUuid: CBUUID = Characteristic.defaultUuid, serviceUuid: CBUUID = Service.defaultUuid, success: ()->(), failure: (()->())? = nil) {
            if let peripheral = forStringCharacteristic(string, characteristicUuid: characteristicUuid, serviceUuid: serviceUuid) {
                peripheral.advertise(success, failure: failure)
            } else if let failure = failure {
                failure()
            }
        }
        func advertise(success: ()->(), failure: (()->())? = nil) {
            return implementation.advertise(success, failure: failure)
        }
    }
}

extension Bluetooth.Peripheral {
    class MockedImplementation: BluetoothPeripheralImplementation {
        var d: Bluetooth.Peripheral?
        private var advertising = false
        func advertise(success: ()->(), failure: (()->())? = nil) {
            if let _ = d where advertising == false {
                advertising = true
                success()
            } else if let failure = failure {
                failure()
            }
        }
        func isAdvertising() -> Bool {
            return advertising
        }
        func stopAdvertising() {
            advertising = false
        }
    }
}

extension Bluetooth.Peripheral {
    class CoreBluetoothImplementation: NSObject, BluetoothPeripheralImplementation {
        enum State {
            case Off
            case Unavailable
            case Idle
            case AddingServices
            case Advertising
        }
        typealias SuccessClosure = ()->()
        typealias FailureClosure = ()->()
        var manager: CBPeripheralManager?
        var d: Bluetooth.Peripheral?
        var state: State = .Off
        var advertiseClosures: (SuccessClosure,FailureClosure?)?
        override init() {
            super.init()
            if manager == nil {
                manager = CBPeripheralManager(delegate: self, queue: nil)
            }
        }
        deinit {
            print("Deinit peripheral")
        }
        func advertise(success: SuccessClosure, failure: FailureClosure?) {
            if state == .Idle, let peripheral = d, manager = manager {
                print("Adding services")
                advertiseClosures = (success,failure)
                for s in peripheral.services {
                    var characteristics = [CBMutableCharacteristic]()
                    for c in s.characteristics {
                        let type = c.uuid
                        let properties = c.writable ? CBCharacteristicProperties.Write : CBCharacteristicProperties.Read
                        let value = c.value
                        let permissions = c.writable ? CBAttributePermissions.Writeable : CBAttributePermissions.Readable
                        let characteristic = CBMutableCharacteristic(type: type, properties: properties, value: value, permissions: permissions)
                        characteristics.append(characteristic)
                    }
                    let service = CBMutableService(type: s.uuid, primary: s.primary)
                    service.characteristics = characteristics
                    state = .AddingServices
                    manager.addService(service)
                }
            } else if state == .Off {
                print("Device powering on. Schedule advertise")
                advertiseClosures = (success,failure)
            } else {
                print("Device unavailable for advertisement")
            }
        }
        func isAdvertising() -> Bool {
            return manager != nil && manager!.isAdvertising
        }
        func stopAdvertising() {
            manager?.stopAdvertising()
        }
    }
}

extension Bluetooth.Peripheral.CoreBluetoothImplementation: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            print("Powered on peripheral manager")
            state = .Idle
            if let advertiseClosures = advertiseClosures {
                print("Start scheduled advertise")
                advertise(advertiseClosures.0, failure: advertiseClosures.1)
            }
        default:
            print("Peripheral manager did update state(\(peripheral.state.rawValue))")
            state = .Unavailable
            if let advertiseClosures = advertiseClosures, failure = advertiseClosures.1 {
                failure()
                self.advertiseClosures = nil
            }
        }
    }
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if error == nil {
            print("Did add service")
            if let d = d {
                var uuids = [CBUUID]()
                for s in d.services {
                    uuids.append(s.uuid)
                }
                let data = [CBAdvertisementDataServiceUUIDsKey : uuids]
                peripheral.startAdvertising(data)
            }
        } else {
            print("Failed to add service")
        }
    }
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if error == nil {
            print("Did start advertising peripheral")
            if let advertiseClosures = advertiseClosures {
                advertiseClosures.0()
            }
        } else {
            print("Failed to start advertising")
            if let advertiseClosures = advertiseClosures, failure = advertiseClosures.1 {
                failure()
            }
        }
    }
}