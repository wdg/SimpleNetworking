//
//  WebSocket.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

#if canImport(FoundationNetworking)
// Support network calls in Linux.
import FoundationNetworking
#endif

extension SimpleNetworking {
    /// Connect to a websocket
    /// - Parameters:
    ///   - socket: Websocket URL
    ///   - responder: The responder to the messages
    public func connect(to socket: URL, responder: @escaping ((Data) -> Void)) {
        self.WSResponder = responder
        WSSocket = URLSession.shared.webSocketTask(with: socket)
        WSSocket?.resume()
        readMessage()
    }

    /// Read message from websocket
    private func readMessage() {
#if !canImport(FoundationNetworking)
        // It looks like it's not supported on Linux (*yet)
        // error: extra trailing closure passed in call
        //        WSSocket?.receive { result in
        //                          ^~~~~~~~~~~

        WSSocket?.receive { result in
            do {
                let message = try result.get()
                switch message {
                case let .string(string):
                    self.WSConnectionTries = 0
                    if let data = string.data(using: .utf8) {
                        self.WSResponder?(data)
                    }

                case let .data(data):
                    self.WSConnectionTries = 0
                    self.WSResponder?(data)

                @unknown default:
                    self.WSConnectionTries = 0
                }
            } catch {
                print("[SimpleNetworking] WebSocket Error:", error)
            }

            if self.WSConnectionTries < 10 {
                self.readMessage()
            } else {
                self.WSResponder?(Data("FAILED TO CONNECT".utf8))
            }
        }

        WSConnectionTries += 1
#endif
    }
}
