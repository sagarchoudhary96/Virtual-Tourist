//
//  APIClient.swift
//  Virtual Tourist
//
//  Created by Sagar Choudhary on 05/12/18.
//  Copyright © 2018 Sagar Choudhary. All rights reserved.
//

import Foundation
class APIClient {
    
    let session = URLSession.shared
    
    // shared singleton api instance
    static let shared = APIClient()
    
    // MARK: Build Url from params
    private func buildUrlWithParam(parameters: [String: AnyObject]) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.Flickr.APIScheme
        urlComponents.host = Constants.Flickr.APIHost
        urlComponents.path = Constants.Flickr.APIBaseURL
        urlComponents.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            urlComponents.queryItems!.append(queryItem)
        }
        return urlComponents.url!
    }
    
    private func getParamPair(pin: Pin) -> Dictionary<String, Any> {
        return [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.PhotosSearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.SafeSearch,
            Constants.FlickrParameterKeys.BoundingBox: getbbox(pin: pin)
        ]
    }
    
    // MARK: get bboxString
    private func getbbox(pin: Pin) -> String {
        // ensure bbox is bounded
        let minLong = max(pin.longitude - Constants.Flickr.SearchBoxWidth, Constants.Flickr.SearchLongRange.0)
        let minLat =  max(pin.latitude - Constants.Flickr.SearchBoxHeight, Constants.Flickr.SearchLatRange.0)
        let maxLong = min(pin.longitude + Constants.Flickr.SearchBoxWidth, Constants.Flickr.SearchLongRange.1)
        let maxLat = min(pin.latitude + Constants.Flickr.SearchBoxHeight, Constants.Flickr.SearchLatRange.1)
        
        return "\(minLong),\(minLat),\(maxLong),\(maxLat)"
    }
    
    // MARK: Create Request
    func createRequest(pin: Pin) -> URLRequest {
         return URLRequest(url: buildUrlWithParam(parameters: getParamPair(pin: pin) as [String : AnyObject]))
    }
    
    // MARK: Make Request
    func makeRequest(request: URLRequest, completionHandler: @escaping (_ result: NSArray?, _ error: String?) -> Void) {
        let task = session.dataTask(with: request) {
            (data, response, error) in
            // guard for error
            guard(error == nil) else {
                completionHandler(nil, "Connection Error")
                return
            }
            
            // guard for successful http response
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            // guard if any data is returned or not
            guard let data = data else {
                completionHandler(nil, "No data was returned by the API")
                return
            }
            
            // parse the result
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                completionHandler(nil, "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // guard if photos and photo key is present in the response or not
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                completionHandler(nil, "Cannot find Keys : \(Constants.FlickrResponseKeys.Photos) in \(parsedResult!)")
                return
            }
            
            // guard if photos are present
            guard(photoArray.count > 0) else {
                completionHandler(nil, "No photos Found!.Search again")
                return
            }
            
            // yay!! we got the data from request
            completionHandler(photoArray as NSArray, nil)
        }
        
        // resume the task
        task.resume()
    }
    
    //MARK: Download Image
    func downloadImage(imageUrl: String, completionHandler: @escaping (_ image: Data?,_ error: String?) -> Void ) {
        let task = session.dataTask(with: URL(string: imageUrl)!) {
            (data, response, error) in
            
            // guard for error
            guard(error == nil) else {
                completionHandler(nil, "Connection Error")
                return
            }
            
            // guard for successful http response
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            // yay! we got the image
            completionHandler(data, nil)
            
        }
        task.resume()
    }
}
