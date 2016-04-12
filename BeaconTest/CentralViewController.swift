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
    var central: CBCentralManager?
    var client: PubNub?
    var channel: String?
    var peripheral: CBPeripheral?
    let config = PNConfiguration(publishKey: pn_publish_key, subscribeKey: pn_subscribe_key)
    override func viewDidLoad() {
        super.viewDidLoad()
        central = CBCentralManager(delegate: self, queue: nil)
        client = PubNub.clientWithConfiguration(config)
        client!.addListener(self)
    }
}

extension CentralViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            central.scanForPeripheralsWithServices(nil, options: nil)
        default:
            print("Peripheral manager did update state(\(central.state.rawValue))")
        }
    }
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        peripheral.delegate = self
        self.peripheral = peripheral
        print("Did discover peripheral with data(\(advertisementData))")
    }
}

extension CentralViewController: CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error == nil {
            print("Discovered services")
        } else {
            print("Unable to discover services")
        }
    }
}

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
