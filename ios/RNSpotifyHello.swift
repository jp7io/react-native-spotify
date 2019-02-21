
//
//  ComponentSwift.swift
//  MixedLanugageExample
//
//  Created by Gergely Orosz on 18/07/2015.
//  Copyright © 2015 GergelyOrosz. All rights reserved.
//
import UIKit

@objc(RNSpotifyHello)
public class RNSpotifyHello: NSObject {
    @objc(sayHello:)
    func sayHello(name: String?) -> String {
        let nameForGreeting = name ?? "World"
        let greeting = "Hello " + nameForGreeting + "!";
        return greeting;
    }
}

