//
//  DetailViewController.swift
//  BeaconTest
//
//  Created by Henk van der Spek on 11/04/16.
//  Copyright © 2016 vanmezelf.nl. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class BeaconViewController: UIViewController {
    let major = CLBeaconMajorValue(1)
    let minor = CLBeaconMinorValue(1)
    let uuid = NSUUID()
    var peripheral: CBPeripheralManager?
    var beacon: CLBeaconRegion?
    var data: NSDictionary?
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheral = CBPeripheralManager(delegate: self, queue: nil)
        beacon = CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: "nl.vanmezelf.BeaconTest")
        data = beacon!.peripheralDataWithMeasuredPower(nil) as NSDictionary
    }
}

extension BeaconViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            peripheral.startAdvertising(data as? [String : AnyObject])
        default:
            print("Peripheral manager did update state(\(peripheral.state.rawValue))")
        }
    }
}