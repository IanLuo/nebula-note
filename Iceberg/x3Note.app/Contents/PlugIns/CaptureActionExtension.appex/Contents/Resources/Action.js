//
//  Action.js
//  CaptureActionExtension
//
//  Created by ian luo on 2019/8/18.
//  Copyright © 2019 wod. All rights reserved.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        arguments.completionFunction({ "baseURI": document.baseURI })
    },
    
    finalize: function(arguments) { }
    
};
    
var ExtensionPreprocessingJS = new Action
