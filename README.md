# Virtual Tourist

An iPhone app that lets you tour the world from the comfort of your couch. User will be able to drop pins on a map, download images for the location and save the favorites to the device.

## Requirements

 * Device running macOS(MacBook or iMac) 
 * [Xcode](https://developer.apple.com/xcode/)

## How to Run
* [Clone](https://github.com/sagarchoudhary96/Virtual-Tourist.git) or [Download](https://github.com/sagarchoudhary96/Virtual-Tourist/archive/master.zip) this repository.
* Open the project folder in xcode.
* Register on [Flickr](https://www.flickr.com) and get your Flickr [API key](https://www.flickr.com/services/apps/create/).
* Replace `FLICKR_API_KEY_HERE` text in `FlickrParameterValues` in `Utils/Constants.swift` file by your **api** key.
* Run the project using the `play` button on top left corner of xcode as you can see below in the screenshot.
![uploadImage](https://user-images.githubusercontent.com/16102594/49672781-42f01680-fa92-11e8-9c14-d37cf02b3c21.png)

## Things Learnt

* Using NSURLSessions to interact with a public restful API
* Create a user interface that intuitively communicates network activity and download progress
* Store media on the device file system Use Core Data for local persistence of an object structure

## ScreenShots
<img src="https://user-images.githubusercontent.com/16102594/49672764-3075dd00-fa92-11e8-992c-d35420bec380.png" width="45%" height="700" align="left"/>
<img src="https://user-images.githubusercontent.com/16102594/49672758-2bb12900-fa92-11e8-9f25-78e6f0fb89c9.png" width="45%" height="700" align="right"/>
