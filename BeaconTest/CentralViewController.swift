//
//  CentralViewController.swift
//  BeaconTest
//
//  Created by Henk van der Spek on 12/04/16.
//  Copyright © 2016 vanmezelf.nl. All rights reserved.
//

import UIKit
import CoreBluetooth
import PubNub

class CentralViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    var central: CBCentralManager?
    var client: PubNub?
    var channel: String?
    var peripherals = [CBPeripheral]()
    let config = PNConfiguration(publishKey: pn_publish_key, subscribeKey: pn_subscribe_key)
    override func viewDidLoad() {
        super.viewDidLoad()
        button.hidden = true
        central = CBCentralManager(delegate: self, queue: nil)
    }
    @IBAction func buttonClicked() {
        if let central = central where !central.isScanning {
            print("Start scanning for peripherals")
            central.scanForPeripheralsWithServices([bt_service_uuid], options: nil)
            button.setTitle("Stop", forState: .Normal)
        } else if let central = central where central.isScanning {
            if let client = client {
                client.unsubscribeFromAll()
            }
            button.setTitle("Start", forState: .Normal)
            print("Stopped")
            central.stopScan()
        }
    }
}

extension CentralViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            button.setTitle("Start", forState: .Normal)
            button.hidden = false
        default:
            print("Peripheral manager did update state(\(central.state.rawValue))")
        }
    }
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Did discover peripheral")
        peripherals.append(peripheral)
        peripheral.delegate = self
        print("Discover services")
        peripheral.discoverServices([bt_service_uuid])
    }
}

extension CentralViewController: CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error == nil, let service = peripheral.services?.first {
            print("Discovered services")
            peripheral.discoverCharacteristics([bt_characteristic_uuid], forService: service)
        } else {
            print("Unable to discover services(\"\(error?.description)\")")
        }
    }
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error == nil, let characteristic = service.characteristics?.first {
            print("Discovered characteristics")
            peripheral.readValueForCharacteristic(characteristic)
        } else {
            print("Unable to discover characteristics(\"\(error?.description)\")")
        }
    }
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error == nil {
            print("Did update value for characteristics")
        } else {
            print("Unable to read updated value for characteristic(\"\(error?.description)\")")
        }
    }
}

//        client = PubNub.clientWithConfiguration(config)
//        client!.addListener(self)
// TODO: Connect channel by UUID
//                    print("Subscribe to PubNub channel with UUID(\(channel))")
//                    client.subscribeToChannels([channel], withPresence: false)

extension CentralViewController: PNObjectEventListener {
    func client(client: PubNub, didReceiveStatus status: PNStatus) {
        switch status.category {
        case .PNConnectedCategory:
            print("connected to channel")
            client.publish("Hello world too!", toChannel: client.channels().last!, withCompletion: { status in
                if !status.error {
                    print("Message published")
                }
            })
        default:
            print("PubNub client received status(\(status.category))")
        }
    }
    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        print("PubNub client received message(\"\(message.data.message!)\")")
    }
}
