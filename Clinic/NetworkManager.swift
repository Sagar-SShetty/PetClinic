//
//  NetworkManager.swift
//  Clinic
//
//  Created by Admin on 29/01/23.
//

import Foundation

class NetworkManager {
    
    func fetchValues(urlString: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        let baseURL = "https://5948dd47-0e25-40ad-8a82-1284bc1ec201.mock.pstmn.io/v1/"
        let validUrl = URL(string: baseURL + urlString)!
        let task = URLSession.shared.dataTask(with: validUrl,
                                              completionHandler: { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            switch httpResponse.statusCode {
            case 200..<300:
                completionHandler(data, response, nil)
            case 300..<400:
                completionHandler(nil, response, error)
            case 400..<500:
                completionHandler(nil, response, error)
            case 500..<600:
                completionHandler(nil, response, error)
            default: break
            }
        })
        task.resume()
    }
}
