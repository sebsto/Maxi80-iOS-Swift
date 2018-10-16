//
//  UIImageView+AlbumArtDownload.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/31/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit


extension UIImageView {
    func load(url: URL, callback: @escaping ((UIImage) -> Void)) {
        
        // schedule loading of the URL
        DispatchQueue.global().async { [weak self] in
            
            // rely on Data to load the URL
            if let data = try? Data(contentsOf: url) {
                
                // if it returns something
                if let image = UIImage(data: data) {
                    
                    // update the GUI and callback
                    DispatchQueue.main.async {
                        self?.image = image
                        callback(image)
                    }
                }
            }
        }
    }
}



