//
// Class:			Alfred
//
// Description:	This class if for helping in creating workflows for Alfred using
//						Apple's Swift language.
//
// Class Variables:
//
// Name			Description
//
// cache			path to the directory that contains the cache for the workflow
// data			path to the directory that contains the data for the workflow
// bundleId		The ID for the bundle that represents the workflow
// path			path to the workflow's directory
// home			path to the user's home directory
// results		the accumulated results. This will be converted to the XML list for
//					feedback into Alfred
//

//
// Import Libraries that are needed.
//
import Foundation


//
// Define structures used.
//

struct AlfredResult {
	var Uid:		String  = ""
	var Arg:		String  = ""
	var Title:	String  = ""
	var Sub:		String  = ""
	var Icon:	String  = ""
	var Valid:	String  = ""
	var Auto:	String  = ""
	var Rtype:	String  = ""
}

//
// Class:			Regex
//
// Description:	This is a helper class for writing tests using regular expressions. Based
//				on article: http://benscheirman.com/2014/06/regex-in-swift/
//
class Regex {
	let internalExpression: NSRegularExpression
	let pattern: String

	init(_ pattern: String) {
		self.pattern = pattern
//		var error: NSError?
//        self.internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)!
        self.internalExpression = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
	}

	func test(input: String) -> Bool {
        let regexOptions: NSRegularExpression.MatchingOptions = .reportProgress
        let matches = self.internalExpression.matches(in: input, options: regexOptions, range: NSMakeRange(0, input.count))
		return matches.count > 0
	}
}

//
// Class: 			Alfred
//
// Description:	This class encloses the functions needed to write workflows for Alfred.
//
public class Alfred {

	var cache:		String = ""
	var data:		String = ""
	var path:		String = ""
	var home:		String = ""
    var fileMGR:   FileManager = FileManager()
	var maxResults:		Int = 10
	var currentResult:	Int = 0
	var results: [AlfredResult] = []

	//
	// Library class Function:
	//
	//	init		This class function is called upon library use to initialize
	//				any variables used for the library before anyone
	//				can make a call to a library class function.
	//
	public init() {
		//
		// Create the result array.
		//
		var resfirst:AlfredResult = AlfredResult()
		resfirst.Title = "No matches found..."
		resfirst.Uid = "default"
		resfirst.Valid = "no"
		resfirst.Arg = ""
		resfirst.Sub = ""
		resfirst.Icon = ""
		resfirst.Auto = ""
		resfirst.Rtype = ""
		results.append(resfirst)
		maxResults = 10
		currentResult = 0

		//
		// Set the path and home variables from the environment.
		// in Objective C: NSString* path = [[[NSProcessInfo processInfo]environment]objectForKey:@"PATH"];
		//
        let process = ProcessInfo.processInfo;
		let edict = NSDictionary(dictionary: process.environment)
		path = fileMGR.currentDirectoryPath
		home = edict["HOME"] as! String

		//
		// Create the directory structure for the cache and data directories.
		//
//        print("打印:\(edict["alfred_workflow_cache"])")
        if edict["alfred_workflow_cache"] != nil {
            cache = edict["alfred_workflow_cache"] as! String
        }
        if edict["alfred_workflow_data"] != nil {
            data = edict["alfred_workflow_data"] as! String
        }
//        cache = (edict["alfred_workflow_cache"] as? String)!
//        data  = (edict["alfred_workflow_data"] as? String)!

		//
		// See if the cache directory exists.
		//
        if(!fileMGR.fileExists(atPath: cache)) {
			//
			// It does not exist. Create it!
			//
			do {
                try fileMGR.createDirectory(atPath: cache, withIntermediateDirectories:true, attributes:nil)
			}
			catch let error as NSError {
			    // Catch a possible error
			    print("Ooops! Can't create directory: \(error)")
			}
		}

		//
		// See if the data directory exists.
		//
        if(!fileMGR.fileExists(atPath: data)) {
			//
			// It does not exist. Create it!
			//
			do {
                try fileMGR.createDirectory(atPath: data, withIntermediateDirectories:true, attributes:nil)
			}
			catch let error as NSError {
			    // Catch a possible error
			    print("Ooops! Can't create directory: \(error)")
			}
		}
	}

	//
	// class Function:	Cache
	//
	// Description:		This class function returns the cache directory for the workflow.
	//
	public func Cache() -> String {
		return(  cache )
	}

	//
	// class Function:	Data
	//
	// Description:		This class function returns the data directory for the workflow.
	//
	public func Data() -> String {
		return( data )
	}

	//
	// class Function:	Path
	//
	// Description:		This class function returns the path to the workflow.
	//
	public func Path() -> String {
		return( path )
	}

	//
	// class Function:	Home
	//
	// Description:		This class function returns the Home directory for the user.
	//
	public func Home() -> String {
		return( home )
	}

	//
	// class Function:	ToXML
	//
	// Description:	This class function takes the result array and makes it into an
	//						XML String for passing back to Alfred.
	//
	public func ToXML() -> String {
		var newxml: String = "<items>"

		for result in results {
			newxml += "<item uidid='\(result.Uid)' valid='\(result.Valid)' autocomplete='\(result.Auto)' type='\(result.Rtype)'><arg>\(result.Arg)</arg><title>\(result.Title)</title><sub>\(result.Sub)</sub><icon>\(result.Icon)</icon></item>"
		}

		//
		// Close the xml and return the XML String.
		//
		newxml += "</items>"
		return(newxml)
	}

	//
	// class Function:	AddResult
	//
	// Description:		Helper class function that just makes it easier to pass values
	//							into a class function
	//							and create an array result to be passed back to Alfred.
	//
	// Inputs:
	// 		uid 		the uid of the result, should be unique
	// 		arg 		the argument that will be passed on
	// 		title		The title of the result item
	// 		sub 		The subtitle text for the result item
	// 		icon 		the icon to use for the result item
	// 		valid		sets whether the result item can be actioned
	// 		auto 		the autocomplete value for the result item
	//			rtype		I have no idea what this one is used for. HELP!
	//
	public func AddResult(_ uid: String, arg: String, title: String, sub: String, icon: String, valid: String, auto: String, rtype: String) {
		//
		// Add in the new result array if not full.
		//
		if (currentResult < maxResults) {
			if(currentResult != 0) {
				var resfirst:AlfredResult = AlfredResult()
				resfirst.Title = title
				resfirst.Uid = uid
				resfirst.Valid = valid
				resfirst.Arg = arg
				resfirst.Sub = sub
				resfirst.Icon = icon
				resfirst.Auto = auto
				resfirst.Rtype = rtype
				results.append(resfirst)
			} else {
				results[0].Title = title
				results[0].Uid = uid
				results[0].Valid = valid
				results[0].Arg = arg
				results[0].Sub = sub
				results[0].Icon = icon
				results[0].Auto = auto
				results[0].Rtype = rtype
			}
			currentResult = currentResult + 1;
		}
	}

	//
	// class Function:	AddResultsSimilar
	//
	// Description:		This class function will only add the results that are similar to the
	//							input given. This is used to select input selectively from what the
	//							user types in.
	//
	// Inputs:
	//			inString	the String to test against the titles to allow that record or not
	// 		uid		the uid of the result, should be unique
	// 		arg 		the argument that will be passed on
	// 		title		The title of the result item
	// 		sub 		The subtitle text for the result item
	// 		icon 		the icon to use for the result item
	// 		valid		sets whether the result item can be actioned
	// 		auto 		the autocomplete value for the result item
	//			rtype		I have no idea what this one is used for. HELP!
	//
	public func AddResultsSimilar(_ uid: String, inString: String, arg: String, title: String, sub: String, icon: String, valid: String, auto: String, rtype: String) {
		//
		// Compare the match String to the title for the Alfred output.
		//
        if(Regex(inString + ".*").test(input: title)) {
			//
			// A match, add it to the results.
			//
			AddResult( uid, arg: arg, title: title, sub: sub, icon: icon, valid: valid, auto: auto, rtype: rtype)
		}
	}

	//
	// class Function:	SetDefaultString
	//
	// Description:		This class function sets a different default title
	//
	// Inputs:
	// 		title 	the title to use
	//
	public func SetDefaultString(_ title: String) {
		if(currentResult == 0) {
			//
			// Add only if no results have been added.
			//
			results[0].Title = title
		}
	}
}
